

CIVITAI_API="6c5170f5756b2c90ea9b689707db7dff"

mkdir -p /workspace/download_logs
mkdir -p /workspace/ComfyUI/models/{diffusion_models,text_encoders,vae,loras}

# Diffusion models
(
set -e
cd /workspace/ComfyUI/models/diffusion_models

curl -fL --retry 5 -C - -O "https://huggingface.co/AlperKTS/Krea2_FP8/resolve/main/krea2_turbo_fp8.safetensors"

curl -fL --retry 5 -C - -O "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_int8_convrot.safetensors"

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3429412?fileId=3330999"

) > /workspace/download_logs/diffusion.log 2>&1 &

# Text encoders and VAEs
(
set -e
cd /workspace/ComfyUI/models/text_encoders

curl -fL --retry 5 -C - -O "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors"

curl -fL --retry 5 -C - -O "https://huggingface.co/Comfy-Org/Qwen3-VL/resolve/main/text_encoders/qwen3vl_4b_bf16.safetensors?download=true"

cd /workspace/ComfyUI/models/vae

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3068442?fileId=2947164"

curl -fL --retry 5 -C - -O "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors"

curl -fL --retry 5 -C - -O "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors"

) > /workspace/download_logs/encoders_vae.log 2>&1 &

# LoRAs
(
set -e
cd /workspace/ComfyUI/models/loras

curl -fL --retry 5 -C - -O "https://huggingface.co/AlperKTS/Krea2_FP8/resolve/main/krea2_turbo_fp8.safetensors"

curl -fL --retry 5 -C - -O "https://huggingface.co/larryvrh/MiniMax-H3-Turbo-Lora/resolve/main/minimax_h3_turbo_v4_step600_ema.safetensors" &

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3374369?fileId=3262606" &

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3306139?fileId=3191174" &

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3257589?fileId=3140780" &

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3399886?fileId=3290337" &

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3413468?fileId=3305979" &

curl -fLJ --retry 5 -OJ -H "Authorization: Bearer $CIVITAI_API" "https://civitai.red/api/download/models/3405038?fileId=3296311" &

wait
) > /workspace/download_logs/loras.log 2>&1 &


#  cat /sys/fs/cgroup/memory.max
# grep -n COMFYUI_ARGS /opt/supervisor-scripts/comfyui.sh

# sed -i '31s|.*|COMFYUI_ARGS="${COMFYUI_ARGS} --disable-pinned-memory --cache-none"|' /opt/supervisor-scripts/comfyui.sh
# supervisorctl restart comfyui

# echo "All download groups launched in parallel."
