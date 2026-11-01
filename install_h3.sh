#!/bin/bash
set -e

CIVITAI_API="6c5170f5756b2c90ea9b689707db7dff"

DIFFUSION="/workspace/ComfyUI/models/diffusion_models"
TEXT_ENCODER="/workspace/ComfyUI/models/text_encoders"
VAE="/workspace/ComfyUI/models/vae"
LORAS="/workspace/ComfyUI/models/loras"

mkdir -p "$DIFFUSION" "$TEXT_ENCODER" "$VAE" "$LORAS"

download() {
    curl -fL --retry 5 --retry-delay 3 -C - "$@"
}

echo "=== DIFFUSION MODELS ==="

# FL2VA
download -o "$DIFFUSION/minimax_h3_fl2va_int8_convrot.safetensors" \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_int8_convrot.safetensors"

# 10Eros Max (NOT Turbo)
download -H "Authorization: Bearer ${CIVITAI_API}" \
-o "$DIFFUSION/10eros_max.safetensors" \
"https://civitai.red/api/download/models/3429412?fileId=3330999"


echo "=== TEXT ENCODER ==="

download -o "$TEXT_ENCODER/qwen3vl_32b_minimax_h3_int8_convrot.safetensors" \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors"


echo "=== VAEs ==="

# Video VAE
download -o "$VAE/minimax_h3_video_vae_fp16.safetensors" \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors"

# Audio VAE
download -o "$VAE/minimax_h3_audio_vae_fp32.safetensors" \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors"


echo "=== LoRAs ==="

# Hugging Face Turbo LoRA
download -o "$LORAS/minimax_h3_turbo_v4_step600_ema.safetensors" \
"https://huggingface.co/larryvrh/MiniMax-H3-Turbo-Lora/resolve/main/minimax_h3_turbo_v4_step600_ema.safetensors"

# Civitai LoRAs
download -H "Authorization: Bearer ${CIVITAI_API}" \
-o "$LORAS/civitai_3374369.safetensors" \
"https://civitai.red/api/download/models/3374369?fileId=3262606"

download -H "Authorization: Bearer ${CIVITAI_API}" \
-o "$LORAS/civitai_3306139.safetensors" \
"https://civitai.red/api/download/models/3306139?fileId=3191174"

download -H "Authorization: Bearer ${CIVITAI_API}" \
-o "$LORAS/civitai_3257589.safetensors" \
"https://civitai.red/api/download/models/3257589?fileId=3140780"

download -H "Authorization: Bearer ${CIVITAI_API}" \
-o "$LORAS/civitai_3399886.safetensors" \
"https://civitai.red/api/download/models/3399886?fileId=3290337"

echo "=== ALL DOWNLOADS COMPLETE ==="
