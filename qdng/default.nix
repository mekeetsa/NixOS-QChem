{ stdenv, fetchurl, requireFile, gfortran, fftw, protobuf, openblas
, automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
}:

let
  version = "20180527";

in stdenv.mkDerivation {
  name = "qdng-${version}";

  src = requireFile {
    name = "qdng-${version}.tar.xz";
    sha256 = "16agzp2aqb6yjmdpbnshjh6cw4kliqfvgfrbj76xcrycrbyk8hf9";
  };

  patches = [ ./multistate.patch ];

  configureFlags = [ "--enable-openmp" "--with-blas=-lopenblas" ];

  enableParallelBuilding = true;

  preConfigure = ''
    ./genbs
  '';

  buildInputs = [ gfortran fftw protobuf openblas
                  bzip2 zlib libxml2 flex bison ];
  nativeBuildInputs = [ automake autoconf libtool ];

  meta = {
    description = "Quantum dynamics program package";
    platforms = stdenv.lib.platforms.linux;
    maintainer = "markus.kowalewski@gmail.com";
  };

}
