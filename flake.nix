{
  description = "A very basic flake";

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
    ]
      (system:
      let
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
          buildInputs = [ ];
        };
      });
}
