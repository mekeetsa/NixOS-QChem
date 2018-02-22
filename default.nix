let
  # prefer 18.03-pre (master branch)
  pkgs = import (fetchTarball http://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {};

  callPackage = pkgs.lib.callPackageWith (pkgs // pkgs-qc);

  pkgs-qc = with pkgs; rec {

    ### Quantum Chem
    cp2k = callPackage ./cp2k { };

    molden = pkgs.molden;

    gamess = callPackage ./gamess { mathlib=atlas; };

    gamess-mkl = callPackage ./gamess { mathlib=callPackage ./mkl { } ; useMkl = true; };

    ga = callPackage ./ga { };

    libxc = pkgs.libxc;

    nwchem = callPackage ./nwchem { };

    octopus = pkgs.octopus;

    openmolcas = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      openblas=openblas;
    };

    qdng = callPackage ./qdng { };

    scalapackCompat = callPackage ./scalapack { openblas=openblasCompat; };

    scalapack = callPackage ./scalapack { mpi=openmpi-ilp64; };

    ### HPC libs and Tools

    ibsim = callPackage ./ibsim { };

    impi = callPackage ./impi { };

    infiniband-diags = callPackage ./infiniband-diags { };

    libfabric = callPackage ./libfabric { };

    libint = callPackage ./libint { };

    mkl = callPackage ./mkl { };

    openmpi-ilp64 = callPackage ./openmpi { gfortran=gfortran-ilp64; };

    openmpi = callPackage ./openmpi { };

    openshmem = callPackage ./openshmem { };

    openshmem-smp = openshmem;

    openshmem-udp = callPackage ./openshmem { conduit="udp"; };

    openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

    openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

    opensm =  callPackage ./opensm { };

    slurmSpankX11 = pkgs.slurmSpankX11; # make X11 work in srun sessions

    ucx = callPackage ./ucx { };

    # nix-wrappers
    gfortran-ilp64 = with pkgs; stdenv.mkDerivation  {
      name = "gfortran-ilp64";
      nativeBuildInputs = [ makeWrapper ];
      buildInputs = [ gfortran ];
      propagatedBuildInputs = [ gfortran.lib ];

      buildCommand = ''
        mkdir -p $out/bin
        makeWrapper ${gfortran}/bin/g77 $out/bin/g77 --add-flags -fdefault-integer-8
        makeWrapper ${gfortran}/bin/f77 $out/bin/f77 --add-flags -fdefault-integer-8
        makeWrapper ${gfortran}/bin/gfortran $out/bin/gfortran --add-flags -fdefault-integer-8
      '';
    };

    fortranPackages = gfc : {
      openblas = appendToName "${gfc.name}" (pkgs.openblas.override { gfortran=gfc; });
    };

    gf64 = fortranPackages gfortran-ilp64;
    gf32 = fortranPackages gfortran;
  };

in pkgs-qc

