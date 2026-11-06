
export CIVITAI_API="aec13e057a0838aeb7564ce721b5160f"

BASE="/workspace/ComfyUI/models"
LOG="/workspace/download_logs"
MANIFEST="$LOG/civitai_paths_v2.tsv"

mkdir -p "$LOG"
mkdir -p "$BASE"/{diffusion_models,text_encoders,vae,loras}
touch "$MANIFEST"

# ------------------------------------------
# Hugging Face downloader
# ------------------------------------------

download_hf() {
    local URL="$1"
    local DEST="$2"
    local NAME="$3"

    echo
    echo "===== HUGGING FACE: $NAME ====="

    if curl -fL --retry 5 --retry-delay 3 \
        --progress-bar -C - \
        -o "$DEST/$NAME" "$URL"; then
        echo "SUCCESS: $NAME"
    else
        local RC=$?
        if [ "$RC" -eq 33 ]; then
            echo "Already complete or range unavailable: $NAME"
        else
            echo "FAILED: $NAME (curl $RC)"
        fi
    fi
}

# ------------------------------------------
# Civitai downloader
# Detects actual model type and destination.
# Uses version ID + file ID in manifest.
# Replaces opaque filenames with descriptive names.
# Verifies final file size.
# ------------------------------------------

download_civitai() {
    local VERSION="$1"
    local FILE_ID="$2"
    local META="/tmp/civitai_${VERSION}_${FILE_ID}.json"

    echo
    echo "===== CIVITAI VERSION $VERSION / FILE $FILE_ID ====="

    if ! curl -fsSL --retry 5 --retry-delay 3 \
        "https://civitai.com/api/v1/model-versions/$VERSION" \
        -o "$META"; then
        echo "FAILED: Could not retrieve Civitai metadata for $VERSION"
        return 1
    fi

    local INFO
    INFO=$(python - "$META" "$VERSION" "$FILE_ID" <<'PY'
import json, sys, os, re

with open(sys.argv[1]) as f:
    d = json.load(f)

version = sys.argv[2]
fid = str(sys.argv[3])

file_info = next(
    (x for x in d.get("files", []) if str(x.get("id")) == fid),
    None
)

if not file_info:
    raise SystemExit("File ID not found in Civitai metadata")

model = d.get("model", {})
model_name = model.get("name") or "Civitai_Model"
file_name = os.path.basename(file_info.get("name") or "")

stem, ext = os.path.splitext(file_name)

# Replace opaque generated filenames with descriptive names.
if not stem or re.fullmatch(r"[A-Za-z0-9]{20,}", stem):
    slug = re.sub(r"[^A-Za-z0-9]+", "_", model_name).strip("_")
    ext = ext or ".safetensors"
    file_name = f"{slug}_v{version}{ext}"

if not file_name:
    raise SystemExit("Could not determine filename")

if not os.path.splitext(file_name)[1]:
    file_name += ".safetensors"

print(model.get("type", ""))
print(file_name)
print(round(float(file_info.get("sizeKB", 0)) * 1024))
PY
    ) || {
        echo "FAILED: Could not identify file $FILE_ID"
        return 1
    }

    local TYPE NAME EXPECTED DEST TARGET
    TYPE=$(echo "$INFO" | sed -n '1p')
    NAME=$(echo "$INFO" | sed -n '2p')
    EXPECTED=$(echo "$INFO" | sed -n '3p')

    case "${TYPE,,}" in
        checkpoint) DEST="$BASE/diffusion_models" ;;
        lora|locon|dora) DEST="$BASE/loras" ;;
        vae) DEST="$BASE/vae" ;;
        *)
            echo "FAILED: Unknown Civitai type: $TYPE"
            return 1
            ;;
    esac

    mkdir -p "$DEST"
    touch "$MANIFEST"

    # Lock manifest during parallel downloads.
    exec 9>"${MANIFEST}.lock"
    flock 9

    # Identify downloads by BOTH version ID and file ID.
    TARGET=$(awk -F '\t' \
        -v v="$VERSION" -v f="$FILE_ID" \
        '$1 == v && $2 == f {print $3; exit}' "$MANIFEST")

    if [ -z "$TARGET" ]; then
        TARGET="$DEST/$NAME"

        # Avoid overwriting another download.
        if awk -F '\t' -v p="$TARGET" \
            '$3 == p {found=1} END {exit !found}' "$MANIFEST" \
            || [ -e "$TARGET" ]; then

            TARGET="$DEST/${NAME%.*}_civitai_${VERSION}_${FILE_ID}.${NAME##*.}"
        fi

        printf '%s\t%s\t%s\n' \
            "$VERSION" "$FILE_ID" "$TARGET" >> "$MANIFEST"
    fi

    flock -u 9
    exec 9>&-

    echo "Name: $NAME"
    echo "Type: $TYPE"
    echo "Destination: $TARGET"
    echo "Expected bytes: $EXPECTED"

    # Skip only if exact expected size matches.
    if [ -f "$TARGET" ] && [ "$EXPECTED" -gt 0 ]; then
        local LOCAL_SIZE
        LOCAL_SIZE=$(stat -c %s "$TARGET")

        if [ "$LOCAL_SIZE" -eq "$EXPECTED" ]; then
            echo "Already downloaded and verified. Skipping."
            return 0
        fi
    fi

    # Download and resume partial files.
    if curl -fL --retry 5 --retry-delay 3 \
        --progress-bar -C - \
        -H "Authorization: Bearer $CIVITAI_API" \
        -o "$TARGET" \
        "https://civitai.red/api/download/models/$VERSION?fileId=$FILE_ID"; then
        echo "Download completed."
    else
        local RC=$?

        if [ "$RC" -eq 33 ]; then
            echo "Resume unavailable. Retrying from the beginning."

            curl -fL --retry 5 --retry-delay 3 \
                --progress-bar \
                -H "Authorization: Bearer $CIVITAI_API" \
                -o "$TARGET" \
                "https://civitai.red/api/download/models/$VERSION?fileId=$FILE_ID"

            RC=$?
            if [ "$RC" -ne 0 ]; then
                echo "FAILED: Civitai $VERSION / $FILE_ID (curl $RC)"
                return 1
            fi
        else
            echo "FAILED: Civitai $VERSION / $FILE_ID (curl $RC)"
            return 1
        fi
    fi

    # Verify final downloaded size.
    if [ "$EXPECTED" -gt 0 ]; then
        local ACTUAL_SIZE
        ACTUAL_SIZE=$(stat -c %s "$TARGET")

        if [ "$ACTUAL_SIZE" -ne "$EXPECTED" ]; then
            echo "FAILED: Size mismatch for $TARGET"
            echo "Expected: $EXPECTED bytes; got: $ACTUAL_SIZE bytes"
            return 1
        fi
    fi

    echo "SUCCESS: $TARGET"
}

# ------------------------------------------
# GROUP 1: DIFFUSION MODELS
# ------------------------------------------

group_diffusion() {
    

    # H3 Eros Max — confirmed Checkpoint, not LoRA.
    # File 3330999 = h3ErosMax_beta7_3330999.safetensors

    download_civitai 3429412 3346133 || true // H3 Eros Max int8 
    

   # download_civitai 3429412 3330999 || true // H3 Eros Max bf16
}

# ------------------------------------------
# GROUP 2: TEXT ENCODER + VAEs
# ------------------------------------------

group_encoders_vae() {
    
    download_hf \
    "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors" \
    "$BASE/text_encoders" \
    "qwen3vl_32b_minimax_h3_int8_convrot.safetensors" || true

    # download_hf \
    # "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_bf16.safetensors?download=true" \
    # "$BASE/text_encoders" \
    # "qwen3vl_32b_minimax_h3_bf16.safetensors" || true

   
    # VAE from Civitai
    download_civitai 3068442 2947164 || true

    # download_hf \
    # "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_int8_convrot.safetensors" \
    # "$BASE/vae" \
    # "minimax_h3_video_vae_int8_convrot.safetensors" || true

    download_hf \
    "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors" \
    "$BASE/vae" \
    "minimax_h3_video_vae_fp16.safetensors" || true
   

    download_hf \
    "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors" \
    "$BASE/vae" \
    "minimax_h3_audio_vae_fp32.safetensors" || true
}

# ------------------------------------------
# GROUP 3: LORAs
# ------------------------------------------

group_loras() {
    download_hf \
    "https://huggingface.co/larryvrh/MiniMax-H3-Turbo-Lora/resolve/main/minimax_h3_turbo_v4_step600_ema.safetensors" \
    "$BASE/loras" \
    "minimax_h3_turbo_v4_step600_ema.safetensors" || true

    download_civitai 3219337 3101211 || true // Turbo Light x2v

    
    download_civitai 3374369 3262606 || true
    download_civitai 3306139 3191174 || true
    download_civitai 3257589 3140780 || true
    download_civitai 3399886 3290337 || true
    download_civitai 3413468 3305979 || true
    download_civitai 3405038 3296311 || true
    download_civitai 3201619 3082893 || true
    download_civitai 3247473 3130327 || true
    download_civitai 3416478 3311427 || true
    download_civitai 3228867 3111185 || true
    download_civitai 3258590 3141848 || true
    download_civitai 3250381 3137071 || true
    download_civitai 3391862 3281578 || true

    download_civitai 3275319 3159342 || true
    download_civitai 3223411 3105419 || true 
    download_civitai 3215304 3097094 || true
    download_civitai 3226989 3109184 || true
    download_civitai 3441237 3339252 || true
    download_civitai 3405852 3297235 || true
    download_civitai 3202064 3083352 || true

    download_civitai 3446189 3345197 || true
}

# ------------------------------------------
# RUN ALL THREE GROUPS IN PARALLEL
# ------------------------------------------

export CIVITAI_API BASE LOG MANIFEST
export -f download_hf download_civitai
export -f group_diffusion group_encoders_vae group_loras

: > "$LOG/diffusion.log"
: > "$LOG/encoders_vae.log"
: > "$LOG/loras.log"

echo "Launching all three download groups..."

bash -c 'group_diffusion' > "$LOG/diffusion.log" 2>&1 &
PID1=$!

bash -c 'group_encoders_vae' > "$LOG/encoders_vae.log" 2>&1 &
PID2=$!

bash -c 'group_loras' > "$LOG/loras.log" 2>&1 &
PID3=$!

echo "Diffusion PID: $PID1"
echo "Encoder/VAE PID: $PID2"
echo "LoRA PID: $PID3"
echo
echo "LIVE DOWNLOAD OUTPUT:"
echo "=========================================="

tail -n 20 -f \
    "$LOG/diffusion.log" \
    "$LOG/encoders_vae.log" \
    "$LOG/loras.log" &
TAIL_PID=$!

wait "$PID1"
STATUS1=$?

wait "$PID2"
STATUS2=$?

wait "$PID3"
STATUS3=$?

kill "$TAIL_PID" 2>/dev/null || true
wait "$TAIL_PID" 2>/dev/null || true

echo
echo "=========================================="
echo "DOWNLOAD GROUP RESULTS"
echo "=========================================="

echo "Diffusion: $STATUS1"
echo "Encoders/VAEs: $STATUS2"
echo "LoRAs: $STATUS3"

echo
echo "Failures, if any:"
grep -H "FAILED:" "$LOG"/*.log || echo "No reported failures."

echo
echo "Final model folder sizes:"
du -sh "$BASE"/* 2>/dev/null

echo
echo "Finished. Logs are in $LOG"

echo
echo "=========================================="
echo "SYSTEM / COMFYUI DIAGNOSTICS"
echo "=========================================="

echo
echo "=== COMFYUI STARTUP ARGUMENTS ==="
grep -n COMFYUI_ARGS /opt/supervisor-scripts/comfyui.sh

echo
echo "=== CONTAINER MEMORY LIMIT ==="
cat /sys/fs/cgroup/memory.max

echo
echo "=== DOWNLOAD FAILURES ==="
grep -H "FAILED:" "$LOG"/*.log || echo "No reported failures."

echo
echo "=== FINAL MODEL FOLDER SIZES ==="
du -sh "$BASE"/* 2>/dev/null

# ------------------------------------------
# RESTART COMFYUI AFTER ALL DOWNLOADS
# ------------------------------------------

echo
echo "=========================================="
echo "RESTARTING COMFYUI"
echo "=========================================="

supervisorctl restart comfyui
supervisorctl status
