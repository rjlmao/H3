
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

    # Get the real model type, a safe descriptive filename,
    # and the expected file size.
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
    raise SystemExit("Could not determine a filename")

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

    # Ensure the manifest exists before accessing it.
    touch "$MANIFEST"

    # Lock the manifest so parallel download groups cannot
    # interfere with one another.
    exec 9>"${MANIFEST}.lock"
    flock 9

    # Identify downloads by BOTH version ID and file ID.
    TARGET=$(awk -F '\t' \
        -v v="$VERSION" -v f="$FILE_ID" \
        '$1 == v && $2 == f {print $3; exit}' "$MANIFEST")

    if [ -z "$TARGET" ]; then
        TARGET="$DEST/$NAME"

        # Avoid collisions with another Civitai download.
        if awk -F '\t' -v p="$TARGET" \
            '$3 == p {found=1} END {exit !found}' "$MANIFEST"; then

            local STEM="${NAME%.*}"
            local EXT="${NAME##*.}"
            TARGET="$DEST/${STEM}_civitai_${VERSION}_${FILE_ID}.${EXT}"
        fi

        printf '%s\t%s\t%s\n' \
            "$VERSION" "$FILE_ID" "$TARGET" >> "$MANIFEST"
    fi

    flock -u 9
    exec 9>&-

    echo "Model: $NAME"
    echo "Type: $TYPE"
    echo "Destination: $TARGET"
    echo "Expected bytes: $EXPECTED"

    # Skip only if the existing file has the exact expected size.
    if [ -f "$TARGET" ] && [ "$EXPECTED" -gt 0 ]; then
        local LOCAL_SIZE
        LOCAL_SIZE=$(stat -c %s "$TARGET")

        if [ "$LOCAL_SIZE" -eq "$EXPECTED" ]; then
            echo "Already downloaded and verified by size. Skipping."
            return 0
        fi
    fi

    # Resume partial downloads without changing the destination name.
    if curl -fL --retry 5 --retry-delay 3 \
        --progress-bar -C - \
        -H "Authorization: Bearer $CIVITAI_API" \
        -o "$TARGET" \
        "https://civitai.red/api/download/models/$VERSION?fileId=$FILE_ID"; then

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
    else
        local RC=$?
        echo "FAILED: Civitai $VERSION / $FILE_ID (curl $RC)"
        return 1
    fi
}
echo
echo "===== RESTARTING COMFYUI ====="
supervisorctl restart comfyui
supervisorctl status
