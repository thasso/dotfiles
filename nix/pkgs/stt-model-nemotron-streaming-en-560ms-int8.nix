# Streaming speech-to-text weights for the personal assistant's hands-free
# voice conversation (`speech.streamingModelDir` →
# ASSISTANT_STT_STREAMING_MODEL_DIR). The offline Parakeet model keeps serving
# composer dictation; this one is served by a separate warm
# sherpa-onnx-online-websocket-server.
#
# Same rules as stt-model-parakeet-tdt-600m-v2-int8.nix: a host package, and a
# `fetchzip` so its store path is fixed-output and cannot move on
# `make update`. The stripped root holds encoder/decoder/joiner .onnx plus
# tokens.txt, the file set the app's config/stt-models.json names for this id.
#
# NAR hash of the UNPACKED tree, not the catalog's tarball `sha256`:
#   nix store prefetch-file --unpack --name stt-model-nemotron-streaming-en-560ms-int8 <url>
{ fetchzip }:

fetchzip {
  name = "stt-model-nemotron-streaming-en-560ms-int8";
  url =
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemotron-speech-streaming-en-0.6b-560ms-int8-2026-04-25.tar.bz2";
  hash = "sha256-hSDGxoMMzKswt8+mXeCIA/7UoUJHDM+ymi7ysNOGX9c=";
}
