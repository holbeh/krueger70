{
  description = "krueger70 website";

  outputs = { self, nixpkgs }: let

    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
  in {
    overlay = final: prev: {
      hugo-fresh = final.stdenv.mkDerivation {
        name = "hugo-fresh";
        src = final.fetchFromGitHub {
          owner = "StefMa";
          repo = "hugo-fresh";
          rev = "6b7327731336dd250a5deb54f56b0a364ae68ced";
          sha256 = "1srynd324aqnxd54r4szmnbym8g7yd986ra6blg8zw6qkbzgabzx";
        };
        patches = [ ./own-js.diff ./font.diff ];

        installPhase = ''
          mkdir -p $out
          cp -r * "$out"
          chmod -R u+w $out
        '';
      };

      krueger70 = let
        themes = [ final.hugo-fresh ];
      in final.stdenv.mkDerivation {
        name = "krueger70-hugo";
        src = self;
        configurePhase = ''
          mkdir -p themes
          ${final.lib.concatStringsSep "\n" (map (theme: ''
            echo "installing theme ${theme.name}"
            ln -s ${theme} themes/${theme.name}
          '') themes)}

          cp ${final.google-fonts}/share/fonts/truetype/TitilliumWeb-Regular.ttf static/
        '';
        buildPhase = "${final.hugo}/bin/hugo";
        installPhase = ''
          cp -r public/ "$out"
        '';
      };
    };

    devShell = forAllSystems (system: let pkgs = nixpkgsFor.${system}; in pkgs.mkShell {
      nativeBuildInputs = [ pkgs.hugo ];

      shellHook = ''
        echo installing theme dir
        mkdir themes
        ln -s ${pkgs.hugo-fresh} themes/hugo-fresh
      '';
    });

    legacyPackages = forAllSystems (system: nixpkgsFor.${system});

    packages = forAllSystems (system: { inherit (nixpkgsFor.${system}) hugo-fresh krueger70; }  );

    #packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    #defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    defaultPackage = forAllSystems (system: self.packages.${system}.krueger70);

  };
}
