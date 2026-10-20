#!/bin/bash
set -e

CIVITAI_API="0e05d424e9c41efbd9d06a43f1ea0dac"
DIFFUSION="/workspace/ComfyUI/models/diffusion_models"
TEXT_ENCODER="/workspace/ComfyUI/models/text_encoders"
VAE="/workspace/ComfyUI/models/vae"
LORAS="/workspace/ComfyUI/models/loras"

mkdir -p "$DIFFUSION" "$TEXT_ENCODER" "$VAE" "$LORAS"

# Diffusion models

# FL2VA
wget -c -P "$DIFFUSION" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_int8_convrot.safetensors"

# 10Eros Max Turbo
wget -c -P "$DIFFUSION" "https://huggingface.co/TenStrip/10Eros-Max/resolve/main/10Eros_Max_h3_8stepTURBO_beta6_int8.safetensors"

# Text encoder
wget -c -P "$TEXT_ENCODER" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors"

# VAEs

# Video VAE
wget -c -P "$VAE" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors"

# Audio VAE
wget -c -P "$VAE" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors"

# LoRAs

# Hugging Face Turbo LoRA

# Civitai LoRA
cd "$LORAS" && 

curl -fL --retry 3 -o "minimax_h3_turbo_v4_step600_ema.safetensors" "https://huggingface.co/larryvrh/MiniMax-H3-Turbo-Lora/resolve/main/minimax_h3_turbo_v4_step600_ema.safetensors"
curl -fL --retry 3 -H "Authorization: Bearer ${CIVITAI_API}" -OJ "https://civitai.red/api/download/models/3374369?fileId=3262606"
curl -fL --retry 3 -H "Authorization: Bearer ${CIVITAI_API}" -OJ "https://civitai.red/api/download/models/3306139?fileId=3191174"
curl -fL --retry 3 -H "Authorization: Bearer ${CIVITAI_API}"  -OJ "https://civitai.red/api/download/models/3257589?fileId=3140780"
curl -fL --retry 3 -H "Authorization: Bearer ${CIVITAI_API}" -OJ "https://civitai.red/api/download/models/3399886?fileId=3290337"
