{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/5cb5ccb54229efd9a4cd1fccc0f43e0bbed81c5d.tar.gz") {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python38
  ];

  shellHook = ''
    set -h     # enable `hash` for .venv/bin/activate
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
  '';
}
