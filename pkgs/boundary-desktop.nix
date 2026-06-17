{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zstd,
  gtk3,
  glib,
  nss,
  nspr,
  atk,
  cups,
  libdrm,
  dbus,
  expat,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  mesa,
  alsa-lib,
  libpulseaudio,
  udev,
}:

stdenv.mkDerivation rec {
  pname = "boundary-desktop";
  version = "2.6.0";

  src = fetchurl {
    url = "https://releases.hashicorp.com/boundary-desktop/${version}/boundary-desktop_${version}_amd64.deb";
    sha256 = "105p85gmx9n1w2jmqxijihm4pcwh51i7vv0i5x01i285vzj5nkpb";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    zstd
  ];

  buildInputs = [
    gtk3
    glib
    nss
    nspr
    atk
    cups
    libdrm
    dbus
    expat
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    mesa
    alsa-lib
    libpulseaudio
    udev
  ];

  # chrome-sandbox tiene setuid; Nix no lo permite en el store → extraer sin perms, --no-sandbox en wrapper.
  unpackPhase = ''
    mkdir -p $out
    ar x $src
    tar -xf data.tar.* -C $out --no-same-permissions --no-same-owner
  '';

  installPhase = ''
    mv $out/usr/* $out/
    rmdir $out/usr

    rm $out/bin/boundary-desktop # el .deb pone un symlink; reemplazar con wrapper real
    makeWrapper $out/lib/boundary-desktop/boundary-desktop $out/bin/boundary-desktop \
      --add-flags "--no-sandbox" \
      --set NIXOS_OZONE_WL 1 \
      --set ELECTRON_OZONE_PLATFORM_HINT wayland
  '';

  meta = with lib; {
    description = "HashiCorp Boundary Desktop Client";
    homepage = "https://www.boundaryproject.io";
    license = licenses.bsl11;
    platforms = [ "x86_64-linux" ];
    mainProgram = "boundary-desktop";
  };
}
