# Speech-to-text model weights for the personal assistant's composer dictation.
#
# THIS HOST owns the model, not the app. The assistant treats dictation as an
# optional host capability: it ships no recognizer and no weights, and only
# discovers a directory it is pointed at (`speech.modelDir` →
# ASSISTANT_STT_MODEL_DIR). So the URL and hash live here, next to the other
# host packages, and updating the model is an ordinary host change.
#
# `fetchzip`, deliberately, and not a mkDerivation that installs selected files:
# a fixed-output derivation's store path is a function of its NAME and OUTPUT
# HASH alone, never of stdenv, so this path does NOT move when nixpkgs is
# updated. An input-addressed derivation here would put the assistant's unit back
# in the churn we removed — it would change on every `make update` and, with it,
# the service definition.
#
# The archive's single top-level directory is stripped (stripRoot default), so
# the output is the model directory itself: encoder/decoder/joiner .onnx plus
# tokens.txt, which is exactly the file set the app's config/stt-models.json
# entry for this id names. A partial or wrong directory is reported by the
# server as "not configured" rather than handed to the recognizer.
#
# NOTE: this hash is the NAR hash of the UNPACKED tree, so it is deliberately a
# different value from the tarball `sha256` in the app's catalog. Get it with:
#   nix store prefetch-file --unpack --name stt-model-parakeet-tdt-600m-v2-int8 <url>
{ fetchzip }:

fetchzip {
  name = "stt-model-parakeet-tdt-600m-v2-int8";
  url =
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8.tar.bz2";
  hash = "sha256-U43bN8LfUGsLe8zrSKMzcwRV7GKKPNe8qIEScvGQvIs=";
}
