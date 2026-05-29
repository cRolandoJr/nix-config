{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper
, gtk3, glib, nss, nspr, atk, cups, libdrm, dbus, expat
, xorg, mesa, alsa-lib, libpulseaudio, udev
}:

stdenv.mkDerivation rec {
  pname = "boundary-desktop";
  version = "2.6.0";

  src = fetchurl {
    url = "https://releases.hashicorp.com/boundary-desktop/${version}/boundary-desktop_${version}_amd64.deb";
    sha256 = "105p85gmx9n1w2jmqxijihm4pcwh51i7vv0i5x01i285vzj5nkpb";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

  buildInputs = [
    gtk3 glib nss nspr atk cups libdrm dbus expat
    xorg.libX11 xorg.libXcomposite xorg.libXdamage
    xorg.libXext xorg.libXfixes xorg.libXrandr
    xorg.libxcb mesa alsa-lib libpulseaudio udev
  ];

  unpackPhase = "dpkg-deb -x $src $out";

  installPhase = ''
    mkdir -p $out/bin
    mv $out/usr/* $out/ 2>/dev/null || true
    mv $out/opt/boundary-desktop $out/opt/boundary-desktop 2>/dev/null || true
    
    makeWrapper $out/opt/boundary-desktop/boundary-desktop $out/bin/boundary-desktop \
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
