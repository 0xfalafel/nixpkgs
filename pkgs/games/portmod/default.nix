{ lib, callPackage, python3Packages, fetchFromGitLab, cacert,
  rustPlatform, bubblewrap, git, perlPackages, imagemagick, fetchurl, fetchzip,
  jre, makeWrapper, tr-patcher, tes3cmd, fetchpatch }:

let
  version = "2.0.3";

  src = fetchFromGitLab {
    owner = "portmod";
    repo = "Portmod";
    rev = "v${version}";
    sha256 = "sha256-vMdyaI1Ps7bFoRvwdVNVG9vPFEiGb7CPvKEWfxiM128=";
  };

  portmod-rust = rustPlatform.buildRustPackage rec {
    inherit src version;
    pname = "portmod-rust";

    cargoHash = "sha256-tAghZmlg34jHr8gtNgL3MQ8EI7K6/TfDcTbBjxdWLr0=";

    nativeBuildInputs = [ python3Packages.python ];

    doCheck = false;
  };

  bin-programs = [
    bubblewrap
    git
    python3Packages.virtualenv
    tr-patcher
    tes3cmd
    imagemagick
  ];

in
python3Packages.buildPythonApplication rec {
  inherit src version;

  pname = "portmod";

  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  # build the rust library independantly
  prePatch = ''
    substituteInPlace setup.py \
      --replace "from setuptools_rust import Binding, RustExtension" "" \
      --replace "RustExtension(\"portmodlib.portmod\", binding=Binding.PyO3, strip=True)" ""
  '';

  patches = [
    (fetchpatch {
      # fix error when symlinks are present in the path (https://gitlab.com/portmod/portmod/-/merge_requests/393)
      # happen with ~/.nix-profile
      url = "https://gitlab.com/portmod/portmod/-/merge_requests/393.patch";
      sha256 = "sha256-XHifwD/Nh7UiMZdvSNudVF7qpBOpjGTKSr4VVdJqUdA=";
    })
  ];

  propagatedBuildInputs = with python3Packages; [
    setuptools-scm
    setuptools
    requests
    chardet
    colorama
    restrictedpython
    appdirs
    GitPython
    progressbar2
    python-sat
    redbaron
    patool
    packaging
    fasteners
  ];

  checkInputs = with python3Packages; [
    pytestCheckHook
  ] ++ bin-programs;

  preCheck = ''
    cp ${portmod-rust}/lib/libportmod.so portmodlib/portmod.so
    export HOME=$(mktemp -d)
  '';

  # some test require network access
  disabledTests = [
    "test_masters_esp"
    "test_logging"
    "test_execute_network_permissions"
    "test_execute_permissions_bleed"
    "test_git"
    "test_sync"
    "test_manifest"
    "test_add_repo"
  ];

  # for some reason, installPhase doesn't copy the compiled binary
  postInstall = ''
    cp ${portmod-rust}/lib/libportmod.so $out/${python3Packages.python.sitePackages}/portmodlib/portmod.so

    makeWrapperArgs+=("--prefix" "GIT_SSL_CAINFO" ":" "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      "--prefix" "PATH" ":" "${lib.makeBinPath bin-programs }")
  '';

  meta = {
    description = "mod manager for openMW based on portage";
    homepage = "https://gitlab.com/portmod/portmod";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ marius851000 ];
  };
}
