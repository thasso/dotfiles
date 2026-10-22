# Kokoro 82M v1.0 (fp32) text-to-speech weights for the personal assistant's
# voice replies (`speech.ttsModelDir` → ASSISTANT_TTS_MODEL_DIR).
#
# Same rules as stt-model-parakeet-tdt-600m-v2-int8.nix: a host package, and a
# `fetchzip` so its store path is fixed-output and cannot move on
# `make update`. The app's own flake builds this with fetchurl + mkDerivation,
# which is input-addressed; we deliberately do not reuse it.
#
# The whole archive is kept: the app needs model.onnx, voices.bin, tokens.txt,
# the English lexicons, espeak-ng-data/ and dict/ side by side, and fp32 rather
# than model.int8.onnx (slower on this CPU).
#
# NAR hash of the UNPACKED tree, not the catalog's tarball `sha256`:
#   nix store prefetch-file --unpack --name tts-model-kokoro-v1-fp32 <url>
{ fetchzip }:

fetchzip {
  name = "tts-model-kokoro-v1-fp32";
  url =
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-multi-lang-v1_0.tar.bz2";
  hash = "sha256-HKrjB25Dqlu7p000Js6S6+y32h/dDEjn7vQqWnCU74E=";
}
