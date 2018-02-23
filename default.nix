let
  # prefer 18.03-pre (master branch)
  #pkgs = import (fetchTarball http://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {};
  pkgs = import /home/markus/src/nixpkgs {};

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
    wrapFCWith = { name ? "", cc, bintools, libc, extraFFlags ? "", extraPackages ? [], extraBuildCommands ? "" }:
        ccWrapperFun rec {
      nativeTools = targetPlatform == hostPlatform && stdenv.cc.nativeTools or false;
      nativeLibc = targetPlatform == hostPlatform && stdenv.cc.nativeLibc or false;
      nativePrefix = stdenv.cc.nativePrefix or "";
      noLibc = !nativeLibc && (libc == null);

      isGNU = cc.isGNU or false;
      isClang = cc.isClang or false;

      inherit name cc bintools libc extraBuildCommands extraPackages extraFFlags;
    };


    wrapFC = cc: wrapFCWith {
      name = lib.optionalString (targetPlatform != hostPlatform) "gcc-cross-wrapper";
      inherit cc;
      # This should be the only bintools runtime dep with this sort of logic. The
      # Others should instead delegate to the next stage's choice with
      # `targetPackages.stdenv.cc.bintools`. This one is different just to
      # provide the default choice, avoiding infinite recursion.
      bintools = if targetPlatform.isDarwin then darwin.binutils else binutils;
      libc = if targetPlatform != hostPlatform then libcCross else stdenv.cc.libc;

      extraFFlags = "-fdefault-integer-8";
    };

    gfortran-ilp64 = wrapFC (gcc7.cc.override {
      name = "gfortran-ilp64";
      langFortran = true;
      langCC = false;
      langC = false;
      profiledCompiler = false;
    });

    fortranPackages = gfc : {
      openblas = appendToName "${gfc.name}" (pkgs.openblas.override { gfortran=gfc; });
    };

    gf64 = fortranPackages gfortran-ilp64;
    gf32 = fortranPackages gfortran;
  };

in pkgs-qc

