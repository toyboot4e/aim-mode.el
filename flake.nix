{
  description = "aim-mode.el — yet another Vim mode for Emacs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: f nixpkgs.legacyPackages.${system});

      treefmtEval = forAllSystems (
        pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }
      );

      emacsWithLint = forAllSystems (pkgs: pkgs.emacs.pkgs.withPackages (epkgs: [ epkgs.package-lint ]));
    in
    {
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

      checks = forAllSystems (pkgs: {
        # `nix flake check` enforces tree formatting (nixfmt via treefmt).
        format = treefmtEval.${pkgs.system}.config.build.check self;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            emacsWithLint.${pkgs.system}
            pkgs.just
            treefmtEval.${pkgs.system}.config.build.wrapper
            pkgs.pinact
            pkgs.zizmor
          ];
        };
      });

      formatter = forAllSystems (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      packages = forAllSystems (pkgs: {
        tests =
          pkgs.runCommand "aim-tests"
            {
              nativeBuildInputs = [
                emacsWithLint.${pkgs.system}
                pkgs.just
              ];
            }
            ''
              export HOME="$TMPDIR"
              cp -R ${self} src && chmod -R u+w src && cd src
              just ci
              touch "$out"
            '';
      });
    };
}
