{ pkgs, ... }:

{
  packages = with pkgs; [
    _1password
    azure-cli
    entr
    git
    opentofu
    terragrunt
  ];

  enterShell = ''
    git --version
  '';

  pre-commit.hooks.shellcheck.enable = true;
}
