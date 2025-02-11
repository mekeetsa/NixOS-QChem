{ stdenv, pkgs, fetchFromGitLab, fetchpatch, cmake, gfortran, perl
, openblas, hdf5-cpp, python3, texLive
, armadillo, mpi ? pkgs.openmpi, globalarrays, openssh
, makeWrapper, fetchFromGitHub
} :

let
  version = "20190529";
  gitLabRev = "c159f8842972107d7b959f0f837049df3f27cf12";

  python = python3.withPackages (ps : with ps; [ six pyparsing ]);

  srcLibwfa = fetchFromGitHub {
    owner = "libwfa";
    repo = "libwfa";
    rev = "efd3d5bafd403f945e3ea5bee17d43e150ef78b2";
    sha256 = "0qzs8s0pjrda7icws3f1a55rklfw7b94468ym5zsgp86ikjf2rlz";
  };

in stdenv.mkDerivation {
  name = "openmolcas-${version}";

  src = fetchFromGitLab {
    owner = "Molcas";
    repo = "OpenMolcas";
    rev = gitLabRev;
    sha256 = "1s5px704li6xhxnf5j5q2j2vd32krsp862r7dg6m11b72q41svg4";
  };

  prePatch = ''
    rm -r External/libwfa
    cp -r ${srcLibwfa} External/libwfa
    chmod -R u+w External/
  '';


  nativeBuildInputs = [ perl cmake texLive makeWrapper ];
  buildInputs = [ gfortran openblas hdf5-cpp python armadillo mpi globalarrays openssh ];

  # tests are not running right now.
  doCheck = false;

  doInstallCheck = true;

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DOPENMP=ON"
    "-DGA=ON"
    "-DMPI=ON"
    "-DLINALG=${if (builtins.parseDrvName openblas.name).name == "mkl" then "MKL" else "OpenBLAS"}"
    "-DTOOLS=ON"
    "-DHDF5=ON"
    "-DFDE=ON"
    "-DWFA=ON"
    "-DCTEST=ON"
  ] ++ (if (builtins.parseDrvName openblas.name).name == "mkl" then [ "-DMKLROOT=${openblas}" ] else  [ "-DOPENBLASROOT=${openblas}" ]);

  GAROOT=globalarrays;

  postConfigure = ''
    # The Makefile will install pymolcas during the build grrr.
    mkdir -p $out/bin
    export PATH=$PATH:$out/bin
  '';

  postFixup = ''
    # Wrong store path in shebang (no Python pkgs), force re-patching
    sed -i "1s:/.*:/usr/bin/env python:" $out/bin/pymolcas
    patchShebangs $out/bin

    wrapProgram $out/bin/pymolcas --set MOLCAS $out
  '';

  installCheckPhase = ''
     #
     # Minimal check if installation runs properly
     #

     export MOLCAS_WORKDIR=./
     inp=water

     cat << EOF > $inp.xyz
     3
     Angstrom
     O       0.000000  0.000000  0.000000
     H       0.758602  0.000000  0.504284
     H       0.758602  0.000000 -0.504284
     EOF

     cat << EOF > $inp.inp
     &GATEWAY
     coord=water.xyz
     basis=sto-3g
     &SEWARD
     &SCF
     EOF

     $out/bin/pymolcas $inp.inp > $inp.out

     echo "Check for sucessful run:"
     grep "Happy landing" $inp.status
     echo "Check for correct energy:"
     grep "Total SCF energy" $inp.out | grep 74.880174
  '';

  checkPhase = ''
    make test
  '';

  meta = with stdenv.lib; {
    description = "Quantum chemistry software package";
    homepage = https://gitlab.com/Molcas/OpenMolcas;
    maintainers = [ maintainers.markuskowa ];
    license = licenses.lgpl21;
    platforms = platforms.linux;
  };
}

