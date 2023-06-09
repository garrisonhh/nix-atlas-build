{
  inputs = {
    nixpkgs.url = github:NixOs/nixpkgs/nixos-23.05;
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      inherit (pkgs.stdenv) mkDerivation;
      pkgs = nixpkgs.legacyPackages.${system};

      atlasInputs = with pkgs; [
        gcc
        gfortran
      ];

      atlasPath = builtins.fetchTarball {
        url = "https://cfhcable.dl.sourceforge.net/project/math-atlas/Stable/3.10.3/atlas3.10.3.tar.bz2";
        sha256 = "sha256:04112hp3b1650ghp56sk35185wjwx9pk210gp9ybh6s9k6fmnq76";
      };

      mkPackage = cripple: mkDerivation {
        name = "atlas-base";
        src = self;

        configurePhase = ''
          ${atlasPath}/configure \
            ${if (cripple) then "--cripple-atlas-performance" else ""}\
            -Fa acg '-Wno-format-security' \
            --prefix="$out" \
            --incdir="$out/include" \
            --libdir="$out/lib"
        '';

        buildInputs = atlasInputs;
        buildPhase = ''
          make build
        '';

        checkPhase = ''
          make check
          make ptcheck
          make time
        '';

        installPhase = ''
          make install
        '';
      };
    in {
      packages.${system} = {
        default = mkPackage false;
        release = mkPackage false;
        crippled = mkPackage true;
      };
    };
}
