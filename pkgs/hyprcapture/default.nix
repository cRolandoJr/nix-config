{ pkgs, src }:

let
  # GitLab responde 403; el espejo de TensorFlow conserva el mismo SHA-256.
  source = pkgs.applyPatches {
    name = "hyprcapture-source";
    inherit src;
    postPatch = ''
      substituteInPlace nix/aec-sources.json \
        --replace-fail \
        'https://gitlab.com/libeigen/eigen/-/archive/' \
        'https://storage.googleapis.com/mirror.tensorflow.org/gitlab.com/libeigen/eigen/-/archive/'
    '';
  };
in
pkgs.callPackage "${source}/nix/package.nix" { src = source; }
