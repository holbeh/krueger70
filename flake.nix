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
      hugo-fresh = final.runCommand "hugo-fresh" {
        src = final.fetchFromGitHub {
          owner = "StefMa";
          repo = "hugo-fresh";
          rev = "6b7327731336dd250a5deb54f56b0a364ae68ced";
          sha256 = "1srynd324aqnxd54r4szmnbym8g7yd986ra6blg8zw6qkbzgabzx";
        };
      } ''
          cp -r "$src" "$out"
          chmod -R u+w $out
        '';

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
        '';
        buildPhase = "${final.hugo}/bin/hugo";
        installPhase = ''
          cp -r public/ "$out"
        '';
      };
      /*krueger70 = final.runCommand "krueger70" {
        src = self;
        themes = [ final.hugo-fresh ];

      } ''
          ${final.lib.concatStringsSep "\n" (final.lib.mapAttrsToList (name: theme: ''
            echo "installing theme ${name}"
            ln -s ${theme} themes/${name}
          '') themes)}
          ${final.lib.concatStringsSep "\n" (final.lib.mapAttrsToList (name: theme: ''
            echo "installing theme ${name}"
            ln -s ${theme} themes/${name}
          '') themes)}


          for "$theme" in "$themes"; do
            echo "installing theme $theme.name"
          done
        '';*/
    };

    legacyPackages = forAllSystems (system: nixpkgsFor.${system});

    packages = forAllSystems (system: { inherit (nixpkgsFor.${system}) hugo-fresh krueger70; }  );

    #packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    #defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    defaultPackage = forAllSystems (system: self.packages.${system}.krueger70);

  };
}
