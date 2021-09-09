{
  description = "A daily updated build of Visual Studio Code Insiders";

  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , unstable
    , flake-utils
    }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "aarch64-linux"
      "armv7l-linux"
    ]
      (system:
      let
        mappedSystem = {
          x86_64-linux = "linux-x64";
          x86_64-darwin = "darwin";
          aarch64-linux = "linux-arm64";
          aarch64-darwin = "darwin-arm64";
          armv7l-linux = "linux-armhf";
        }.${system};

        archive_fmt = if (system == "x86_64-darwin" || system == "aarch64-darwin") then "zip" else "tar.gz";

        pkgs = import unstable {
          inherit system;

          config = {
            allowUnfree = true;
          };

          overlays = [
            (self: super: {
              vscode = super.vscode.overrideAttrs (old: {
                preInstall =
                  # This is a workaround until I've made it so that
                  # sourceExecutableName is forwarded to vscode/generic.nix. I
                  # think there's currently no way of reaching it through just
                  # vscode.
                  if (super.pkgs.stdenv.hostPlatform.system == "x86_64-darwin" || super.pkgs.stdenv.hostPlatform.system == "aarch64-darwin") then ''
                    cp ./Contents/Resources/app/bin/code ./Contents/Resources/app/bin/code-insiders
                  '' else "";

                pname = "vscode-insiders";

                src = builtins.fetchurl {
                  name = "VSCode_${mappedSystem}.${archive_fmt}";
                  url = import (./systems + "/${mappedSystem}/url.nix");
                  sha256 = import (./systems + "/${mappedSystem}/hash.nix");
                };
              });
            })
          ];
        };
      in
      {
        packages = flake-utils.lib.flattenTree ({
          vscodeInsiders = pkgs.vscode.override { isInsiders = true; };
        });
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.fish
          ];
        };
      });
}
