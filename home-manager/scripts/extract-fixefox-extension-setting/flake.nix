{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs }: 
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    unzip = "${pkgs.unzip}/bin/unzip";
    jq = "${pkgs.jq}/bin/jq";
  in
  {
    packages.x86_64-linux.default = pkgs.writeShellScriptBin "extract-firefox-extension-setting" ''
      if [ -z "$1" ]; then
        echo "Usage: nix run <flake_path> -- <extension_url>"
        exit 1
      fi

      TMPDIR=$(mktemp -d)      
      EXTENSION_NAME=$(echo "$1" \
        | sed -E 's|https://addons.mozilla.org/firefox/downloads/file/[0-9]+/([^/]+)-[^/]+\.xpi|\1|' \
        | tr '_' '-')
      echo $EXTENSION_NAME \
        | awk '{print "https://addons.mozilla.org/firefox/downloads/latest/" $1 "/latest.xpi"}' \
        | xargs wget --directory-prefix="$TMPDIR" -O "$TMPDIR/latest.xpi"
      ${unzip} "$TMPDIR/latest.xpi" -d "$TMPDIR/my-extension" > /dev/null

      echo $EXTENSION_NAME
      cat "$TMPDIR/my-extension/manifest.json" | ${jq} -r '.browser_specific_settings.gecko.id'
    '';
  };
}
