{
  description = "slock - simple screen locker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        version = "1.5";
        
      in {
        packages = {
          slock = pkgs.stdenv.mkDerivation rec {
            pname = "slock";
            inherit version;

            src = ./.;

            buildInputs = with pkgs; [
              xorg.libX11
              xorg.libXext
              xorg.libXrandr
              imlib2
            ];

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            makeFlags = [
              "PREFIX=${placeholder "out"}"
              "CC=${pkgs.stdenv.cc.targetPrefix}cc"
            ];

            installPhase = ''
              runHook preInstall
              
              # Custom install without setuid bit
              mkdir -p $out/bin
              cp -f slock $out/bin/
              chmod 755 $out/bin/slock
              
              mkdir -p $out/share/man/man1
              sed "s/VERSION/${version}/g" <slock.1 >$out/share/man/man1/slock.1
              chmod 644 $out/share/man/man1/slock.1
              
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Simple screen locker";
              homepage = "https://tools.suckless.org/slock/";
              license = licenses.mit;
              maintainers = with maintainers; [ ];
              platforms = platforms.linux;
            };
          };

          default = self.packages.${system}.slock;
        };

        overlays.default = final: prev: {
          inherit (self.packages.${system}) slock;
        };

        nixosModules.slock = { config, lib, pkgs, ... }:
          with lib;
          {
            options.services.slock = {
              enable = mkEnableOption "slock screen locker";
            };

            config = mkIf config.services.slock.enable {
              environment.systemPackages = [ self.packages.${system}.slock ];
              security.wrappers.slock = {
                owner = "root";
                group = "root";
                setuid = true;
                source = "${self.packages.${system}.slock}/bin/slock";
              };
            };
          };
      });
}
