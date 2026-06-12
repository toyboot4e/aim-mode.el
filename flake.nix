{
  description = "aim-mode.el — yet another Vim mode for Emacs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            (pkgs.emacs.pkgs.withPackages (epkgs: [ epkgs.package-lint ]))
            pkgs.just
          ];
        };
      });

      # `nix run` launches a reproducible Emacs with aim-mode loaded.
      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${pkgs.writeShellScript "aim-playground" ''
            exec ${pkgs.emacs}/bin/emacs -Q -L ${self}/lisp -l aim-mode --eval '(aim-playground)'
          ''}";
          meta.description = "Emacs with aim-mode loaded in a playground buffer";
        };
      });
    };
}
