    rjlmao
    H3

Repository navigation

    Code
    Issues
    Pull requests
    Actions
    Projects
    Wiki
    Security and quality
    Insights
    Settings

Files
tT

    Easy Workflow.json
    README.md
    install_h3.sh

    H3

/
in
main

    Edit
    Preview

Indent mode
Indent size
Line wrap mode
Editing install_h3.sh file contents
nextpreviousallmatch caseregexpby word
replacereplace all
×
 
185
186
187
188
189
190
191
192
193
194
195
196
197
198
199
200
201
202
203
204
205
206
207
208
209
210
211
212
213
214
215
216
217
218
219
220
221
222
223
224
225
226
227
228
229
230
231
232
233
234
235
236
237
238
239
240
241
242
243
244
245
246
247
248
249
250
251
252
253
254
255
256
257
258
259
260

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
    

    download_civitai 3429412 3330999 || true // H3 Eros Max bf16
}

# ------------------------------------------
# GROUP 2: TEXT ENCODER + VAEs
# ------------------------------------------

group_encoders_vae() {
    # Keep ONLY the 32B text encoder.
    # download_hf \
    # "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors" \
    # "$BASE/text_encoders" \
    # "qwen3vl_32b_minimax_h3_int8_convrot.safetensors" || true

    download_hf \
    "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_bf16.safetensors?download=true" \
    "$BASE/text_encoders" \
    "qwen3vl_32b_minimax_h3_bf16.safetensors" || true

   
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
Use Control + Shift + m to toggle the tab key moving focus. Alternatively, use esc then tab to move to the next interactive element on the page.
