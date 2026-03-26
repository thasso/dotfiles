{ lib, stdenvNoCC, fetchurl }:

let
  version = "0.12.0";
  platform = stdenvNoCC.hostPlatform.system;
  srcInfo = {
    aarch64-darwin = {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_darwin_arm64.tar.gz";
      hash = "sha256-03FmSb9taj8F6UvocEmRxp3Ghqz8hNNfHyiBL9JPEVE=";
    };
    aarch64-linux = {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_linux_arm64.tar.gz";
      hash = "sha256-1/IElNfrDocWYxhT0FXMuzaMe4HLgWX1W0WIS8y2e0s=";
    };
    x86_64-linux = {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_linux_amd64.tar.gz";
      hash = "sha256-oD/MvWfqLlmialbpLeiRhXf0vr5LL5RoI0GXd4J82rI=";
    };
  }.${platform} or (throw "gogcli: unsupported platform ${platform}");

  src = fetchurl {
    inherit (srcInfo) url hash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "gogcli";
  inherit version src;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 gog $out/bin/gog
    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI tool for interacting with Google APIs (Gmail, Calendar, Drive, and more)";
    homepage = "https://github.com/steipete/gogcli";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
    mainProgram = "gog";
  };
}
