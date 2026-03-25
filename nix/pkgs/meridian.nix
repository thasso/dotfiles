{ lib, stdenv, fetchFromGitHub, bun, nodejs_22, cacert, makeBinaryWrapper, typescript }:

let
  version = "1.17.0";
  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "opencode-claude-max-proxy";
    rev = "4d792c0aa5ab160919b3c4b7cb9d5dc6ee4c34a9";
    hash = "sha256-EScd+aslfPp8p6uz+NqkKDFvT1MyRZvrdIRlVq/cDpo=";
  };

  # Fixed-output derivation: allowed network access to fetch bun deps
  node_modules = stdenv.mkDerivation {
    pname = "meridian-deps";
    inherit version src;
    nativeBuildInputs = [ bun cacert ];
    dontFixup = true;
    buildPhase = ''
      export HOME=$TMPDIR
      bun install --frozen-lockfile
    '';
    installPhase = ''
      cp -r node_modules $out
    '';
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-sp5M6S70wVWX3jgIFUmFnoe3eRiAYFeZ7y+jmKdr60Y=";
  };
in
stdenv.mkDerivation {
  pname = "meridian";
  inherit version src;

  nativeBuildInputs = [ bun nodejs_22 makeBinaryWrapper typescript ];

  buildPhase = ''
    export HOME=$TMPDIR
    cp -r ${node_modules} node_modules
    chmod -R u+w node_modules

    bun build bin/cli.ts src/proxy/server.ts \
      --outdir dist \
      --target node \
      --splitting \
      --external @anthropic-ai/claude-agent-sdk \
      --entry-naming '[name].js'

    tsc -p tsconfig.build.json
  '';

  installPhase = ''
    mkdir -p $out/lib/meridian $out/bin

    cp -r dist/* $out/lib/meridian/

    # Runtime dependency: @anthropic-ai/claude-agent-sdk (marked external in build)
    mkdir -p $out/lib/meridian/node_modules/@anthropic-ai
    cp -r ${node_modules}/@anthropic-ai/claude-agent-sdk \
      $out/lib/meridian/node_modules/@anthropic-ai/

    makeBinaryWrapper ${nodejs_22}/bin/node $out/bin/meridian \
      --add-flags "$out/lib/meridian/cli.js" \
      --set NODE_PATH "$out/lib/meridian/node_modules"
  '';

  meta = with lib; {
    description = "Local Anthropic API powered by your Claude Max subscription";
    homepage = "https://github.com/rynfar/opencode-claude-max-proxy";
    license = licenses.mit;
    mainProgram = "meridian";
  };
}
