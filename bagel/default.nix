{ stdenv, lib, pkgs, fetchFromGitHub, autoconf, automake, libtool
, python, boost159, mpi ? pkgs.openmpi, libxc, fetchpatch, blas
, scalapack, withScalapack ? false
, makeWrapper, openssh
} :

let
  version = "1.2.2";

  blasName = (builtins.parseDrvName blas.name).name;

  mpiName = (builtins.parseDrvName mpi.name).name;
  mpiType = if mpiName == "openmpi" then mpiName
       else if mpiName == "mpich"  then "mvapich"
       else if mpiName == "mvapich"  then mpiName
       else throw "mpi type ${mpiName} not supported";

in stdenv.mkDerivation {
  name = "bagel-${version}" + lib.optionalString (blasName != "openblas") "-${blasName}";

  src = fetchFromGitHub {
    owner = "nubakery";
    repo = "bagel";
    rev = "v${version}";
    sha256 = "184p55dkp49s99h5dpf1ysyc9fsarzx295h7x0id8y0b1ggb883d";
  };

  nativeBuildInputs = [ autoconf automake libtool openssh boost159 ];
  buildInputs = [ python boost159 libxc blas mpi ]
                ++ lib.optional withScalapack scalapack;

  #
  # Furthermore, if relativistic calculations fail without MKL,
  # users may consider reconfiguring and recompiling with -DZDOT_RETURN in CXXFLAGS.
  CXXFLAGS="-DNDEBUG -O3 -mavx -DCOMPILE_J_ORB "
           + lib.optionalString (blasName == "openblas") "-lopenblas -DZDOT_RETURN"
           + lib.optionalString (blasName == "mkl") "-L${blas}/lib/intel64";

  LDFLAGS = lib.optionalString (blasName == "mkl") "-L${blas}/lib/intel64";

  BOOST_ROOT=boost159;

  configureFlags = [ "--with-libxc" "--with-mpi=${mpiType}" "--with-boost=${boost159}" ]
                   ++ lib.optional ( blasName == "mkl" ) "--enable-mkl"
                   ++ lib.optional ( !withScalapack ) "--disable-scalapack";

#  outputs = [ "out" ];

  postPatch = ''
    # Fixed upstream
    sed -i '/using namespace std;/i\#include <string.h>' src/util/math/algo.cc
  '';

  preConfigure = ''
    ./autogen.sh
  '';

  enableParallelBuilding = true;

  postInstall = ''
    cat << EOF > $out/bin/bagel
    if [ \$# -lt 1 ]; then
    echo
    echo "Usage: `basename \\$0` [mpirun parameters] <input file>"
    echo
    exit
    fi
    ${mpi}/bin/mpirun \''${@:1:\$#-1} $out/bin/BAGEL \''${@:\$#}
    EOF
    chmod 755 $out/bin/bagel

    # install test jobs
    mkdir -p $out/share/tests
    cp test/* $out/share/tests
  '';

  installCheckPhase = ''
    echo "Running HF test"
    export OMP_NUM_THREADS=1
    export MV2_ENABLE_AFFINITY=0
    mpirun -np 1 $out/bin/BAGEL test/hf_svp_hf.json > log
    echo "Check output"
    grep "SCF iteration converged" log
    grep "99.847790" log
  '';

  doInstallCheck = false;

  doCheck = true;

  meta = with stdenv.lib; {
    description = "Brilliantly Advanced General Electronic-structure Library";
    homepage = http://www.shiozaki.northwestern.edu/bagel.php;
    license = licenses.gpl3;
    maintainers = maintainers.markuskowa;
    platforms = platforms.linux;
  };
}

