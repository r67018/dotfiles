{ pkgs, ... }:

let
  nodejsLatestLts = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "nodejs";
    version = "24.18.0";

    src = pkgs.fetchurl {
      url = "https://nodejs.org/dist/v${version}/node-v${version}-darwin-arm64.tar.xz";
      hash = "sha256-RHe59477d3RM9etXoOlZTbpmRms4tOk/qfNcuQeglaY=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R ./* "$out"/

      runHook postInstall
    '';

    meta = pkgs.nodejs_24.meta // {
      platforms = [ "aarch64-darwin" ];
    };
  };
in

{
  imports = [
    ../../modules/thunderbird-cli.nix
  ];

  home.packages = [
    nodejsLatestLts
  ];
}
