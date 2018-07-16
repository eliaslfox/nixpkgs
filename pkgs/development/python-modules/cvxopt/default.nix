{ lib
, buildPythonPackage
, fetchPypi
, isPyPy
, python
, openblasCompat # build segfaults with regular openblas
, suitesparse
, glpk ? null
, gsl ? null
, fftw ? null
, withGlpk ? true
, withGsl ? true
, withFftw ? true
}:

buildPythonPackage rec {
  pname = "cvxopt";
  version = "1.2.0";

  disabled = isPyPy; # hangs at [translation:info]

  src = fetchPypi {
    inherit pname version;
    sha256 = "3296c9d49b7dcb894b20db5d7d1c1a443912b4d82358e03f836575e8398e0d60";
  };

  # similar to Gsl, glpk, fftw there is also a dsdp interface
  # but dsdp is not yet packaged in nixpkgs
  preConfigure = ''
    export CVXOPT_BLAS_LIB_DIR=${openblasCompat}/lib
    export CVXOPT_BLAS_LIB=openblas
    export CVXOPT_LAPACK_LIB=openblas
    export CVXOPT_SUITESPARSE_LIB_DIR=${suitesparse}/lib
    export CVXOPT_SUITESPARSE_INC_DIR=${suitesparse}/include
  '' + lib.optionalString withGsl ''
    export CVXOPT_BUILD_GSL=1
    export CVXOPT_GSL_LIB_DIR=${gsl}/lib
    export CVXOPT_GSL_INC_DIR=${gsl}/include
  '' + lib.optionalString withGlpk ''
    export CVXOPT_BUILD_GLPK=1
    export CVXOPT_GLPK_LIB_DIR=${glpk}/lib
    export CVXOPT_GLPK_INC_DIR=${glpk}/include
  '' + lib.optionalString withFftw ''
    export CVXOPT_BUILD_FFTW=1
    export CVXOPT_FFTW_LIB_DIR=${fftw}/lib
    export CVXOPT_FFTW_INC_DIR=${fftw.dev}/include
  '';

  # https://github.com/cvxopt/cvxopt/issues/122
  # This is fixed on staging (by #43234, status 2018-07-15), but until that
  # lands we should disable the tests. Otherwise the 99% of use cases that
  # should be unaffected by that failure are affected.
  doCheck = false;
  checkPhase = ''
    ${python.interpreter} -m unittest discover -s tests
  '';

  meta = {
    homepage = http://cvxopt.org/;
    description = "Python Software for Convex Optimization";
    longDescription = ''
      CVXOPT is a free software package for convex optimization based on the
      Python programming language. It can be used with the interactive
      Python interpreter, on the command line by executing Python scripts,
      or integrated in other software via Python extension modules. Its main
      purpose is to make the development of software for convex optimization
      applications straightforward by building on Python's extensive
      standard library and on the strengths of Python as a high-level
      programming language.
    '';
    maintainers = with lib.maintainers; [ edwtjo ];
    license = lib.licenses.gpl3Plus;
  };
}
