{ lib
, buildPythonPackage
, fetchPypi
, pythonOlder
, setuptools-scm
, typing-extensions
, toml
, zipp
}:

buildPythonPackage rec {
  pname = "importlib-metadata";
  version = "4.6.4";
  disabled = pythonOlder "3.6";

  src = fetchPypi {
    pname = "importlib_metadata";
    inherit version;
    sha256 = "sha256-ezCnjbKSLXim9H+zBoMVahTzxqpcwj93zIln6astAC8=";
  };

  nativeBuildInputs = [ setuptools-scm ];

  propagatedBuildInputs = [
    toml
    zipp
  ] ++ lib.optionals (pythonOlder "3.8") [
    typing-extensions
  ];

  # Cyclic dependencies due to pyflakefs
  doCheck = false;
  pythonImportsCheck = [ "importlib_metadata" ];

  meta = with lib; {
    description = "Read metadata from Python packages";
    homepage = "https://importlib-metadata.readthedocs.io/";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
