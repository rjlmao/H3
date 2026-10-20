```bash

# COMFY ARGS "--disable-auto-launch --disable-xformers --port 18188 --cache-none --enable-cors-header"
#!/bin/bash
set -e

DIFFUSION="/workspace/ComfyUI/models/diffusion_models"
TEXT_ENCODER="/workspace/ComfyUI/models/text_encoders"
VAE="/workspace/ComfyUI/models/vae"
LORAS="/workspace/ComfyUI/models/loras"



# Diffusion 
  # FL2VA
  wget -c -P "$DIFFUSION" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_int8_convrot.safetensors"
  wget -c -P "$DIFFUSION" "https://huggingface.co/TenStrip/10Eros-Max/resolve/main/10Eros_Max_h3_8stepTURBO_beta6_int8.safetensors"

# Text encoder
wget -c -P "$DIFFUSION" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors"

# VAE  
  # Video VAE
  wget -c -P "$VAE" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors"
  
  # Audio VAE
  wget -c -P "$VAE" "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors"

```
