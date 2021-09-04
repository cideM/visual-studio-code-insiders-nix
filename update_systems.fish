# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=visual-studio-code-insiders-bin
# For some valid arch and OS combos

function _validate_build -d "Only allow certain architecture and OS combinations"
  switch $_flag_value
    case "darwin-arm64"
      return 0
    case "darwin"
      return 0
    case "linux-x64"
      return 0
    case "linux-arm64"
      return 0
    case "linux-armhf"
      return 0
    # case "linux-ia32"
    #   return 0
    case '*'
      echo "invalid value $_flag_value, supported values are:"
      echo -e "\tdarwin-arm64"
      echo -e "\tdarwin"
      echo -e "\tlinux-x64"
      echo -e "\tlinux-arm64"
      echo -e "\tlinux-armhf"
      # echo -e "\tlinux-ia32"
      return 1
  end
end

argparse --name="update_vscode_archive_sha256" 'b/build=!_validate_build' -- $argv

if not set -q _flag_build
  echo "required option -b/--build not given or invalid"
  exit 1
end

if not test -d systems
  mkdir systems
end

set -l generated_url https://update.code.visualstudio.com/latest/$_flag_build/insider

echo "Get real URL by following redirects for generated URL: $generated_url"
set -l real_url (curl -IL -o /dev/null -w %{url_effective} $generated_url)

echo "Download archive and generate hash from real URL: $real_url"
# https://fishshell.com/docs/current/cmds/psub.html
set -l hash (nix-hash --type sha256 --base32 --flat (curl -o - $real_url | psub))

echo "Update output file with real URL and hash"
if not test -d systems/$_flag_build
  mkdir systems/$_flag_build
end

echo "\"$real_url\"" > systems/$_flag_build/url.nix
echo "\"$hash\"" > systems/$_flag_build/hash.nix
