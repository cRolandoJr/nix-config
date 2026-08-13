{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  mesa,
  nspr,
  nss,
  udev,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "balena-etcher";
  version = "2.1.6";

  src = fetchurl {
    url = "https://github.com/balena-io/etcher/releases/download/v${finalAttrs.version}/balenaEtcher-linux-x64-${finalAttrs.version}.zip";
    hash = "sha256-MXVfx5kgWHOCl6tjO8YPdZmfNNuUaAzWykydoiK9T3U=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    expat
    glib
    gtk3
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    mesa
    nspr
    nss
    stdenv.cc.cc.lib
    udev
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "balena-etcher";
      desktopName = "balenaEtcher";
      comment = "Flash OS images to SD cards and USB drives";
      exec = "balena-etcher %U";
      icon = "balena-etcher"; # lo resuelve el tema Papirus
      categories = [ "Utility" ];
      startupWMClass = "balena-etcher";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/balena-etcher
    cp -r . $out/opt/balena-etcher

    # chrome-sandbox necesita setuid y el store no lo permite → --no-sandbox
    makeWrapper $out/opt/balena-etcher/balena-etcher $out/bin/balena-etcher \
      --add-flags "--no-sandbox" \
      --set NIXOS_OZONE_WL 1 \
      --set ELECTRON_OZONE_PLATFORM_HINT wayland

    runHook postInstall
  '';

  meta = {
    description = "Flash OS images to SD cards and USB drives";
    homepage = "https://etcher.balena.io";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "balena-etcher";
  };
})
