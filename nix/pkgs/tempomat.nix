{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage {
  pname = "tempomat";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "szymonkozak";
    repo = "tempomat";
    rev = "v2.0.1";
    hash = "sha256-eC7Hwm9dbyzmKK1kg/ymrvd6wPkvyJLU6PZma3G5UtQ=";
  };

  npmDepsHash = "sha256-gDT7mAhdGMYJBsntAvWYX5MDLL/yqrBcBwCzATyW6AE=";

  meta = with lib; {
    description = "Tempo.io cloud CLI";
    homepage = "https://github.com/szymonkozak/tempomat";
    license = licenses.mit;
    mainProgram = "tempo";
  };
}
