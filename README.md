# Use the Latest Visual Studio Code Insiders Build

**This is no longer needed**

Please use https://nixos.wiki/wiki/Visual_Studio_Code under the "Insiders Build" heading.

## Instructions

Add this flake to your inputs, create an overlay that provides the latest
Visual Studio Code (VSC) to Nixpkgs, and then use that new package in your Home
Manager (HM) configuration for VSC. The result is that HM still takes care of
extensions, keybindings, and so on, but the VSC package will always come from
the flake.

Here's an example flake:

```nix
{
  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "unstable";
    };
    vscodeInsiders.url = "github:cideM/visual-studio-code-insiders-nix";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, home-manager, vscodeInsiders, unstable }:
    let
      homeConfigurations = {
        m1-darwin = home-manager.lib.homeManagerConfiguration rec {
          system = "aarch64-darwin";
          pkgs = import unstable {
            inherit system;
          };
          homeDirectory = "/Users/someone";
          username = "someone";
          configuration = { pkgs, config, ... }:
            {
              imports = [
                {
                  nixpkgs.overlays = overlays ++ [
                    (self: super: {
                      vscodeInsiders = vscodeInsiders.packages.${super.system}.vscodeInsiders;
                    })
                  ];

                  nixpkgs.config = {
                    allowUnfree = true;
                  };
                }
                ({ pkgs, config, ... }:
                  {
                    programs.vscode = {
                      enable = true;
                      # The important part!
                      package = pkgs.vscodeInsiders;
                    };
                  })
                ./path/to/home.nix
              ];
            };
        };
      };
    in
    {
      inherit homeConfigurations;
    };
}
```

## How It Works

This repository takes care of two things for you:

- Make sure the correct executable and folder names are used. This should be
  upstreamed to Nixpkgs at some point, but right now, it's easy to break your
  VSC installation by using the wrong combination of attributes. In those cases
  the symlink to the VSC executable might point at a file that doesn't exist,
  or it might look for extensions in the wrong folder, since it's not acutally
  an insiders build, and so on.
- Fetch the actual URL to the archive and update the hash for the archive, so
  you don't have to.

The Nix code is very straight forward since the heavy lifting is already done
by Nixkpgs and Home Manager, respectively.
