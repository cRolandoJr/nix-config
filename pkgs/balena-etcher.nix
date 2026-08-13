{
  lib,
  stdenv,
  fetchurl,
  bash,
  unzip,
  asar,
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
  libglvnd,
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

  # El sidecar que escribe el disco se lanza con `pkexec ... /bin/bash -c`, y en
  # NixOS ninguno de los dos paths existe (pkexec vive en el wrapper setuid y
  # /bin sólo tiene sh). pkexec valida el programa antes de autenticar, así que
  # sin esto falla sin siquiera pedir la contraseña.
  postPatch = ''
    asar extract resources/app.asar app-patched
    substituteInPlace app-patched/.webpack/renderer/main_window/index.js \
      --replace-fail /usr/bin/pkexec /run/wrappers/bin/pkexec \
      --replace-fail '"/bin/bash"' '"${bash}/bin/bash"'
    rm -rf resources/app.asar resources/app.asar.unpacked
    asar pack app-patched resources/app.asar --unpack "*.node"
    rm -rf app-patched
  '';

  nativeBuildInputs = [
    unzip
    asar
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
    cp resources/etcher-util $NIX_BUILD_TOP/etcher-util.pristine

    # chrome-sandbox necesita setuid y el store no lo permite → --no-sandbox
    # GL/EGL entran por dlopen desde ANGLE: RUNPATH no se hereda, va por LD_LIBRARY_PATH
    makeWrapper $out/opt/balena-etcher/balena-etcher $out/bin/balena-etcher \
      --add-flags "--no-sandbox" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libglvnd ]}" \
      --set NIXOS_OZONE_WL 1 \
      --set ELECTRON_OZONE_PLATFORM_HINT wayland

    runHook postInstall
  '';

  # etcher-util es un binario `pkg`: lee su payload JS de un offset fijo grabado
  # adentro, y patchelf le corre el archivo 4 KB. Se parchea todo lo demás a mano
  # y se restaura el original; sus libs las resuelve nix-ld.
  dontAutoPatchelf = true;

  postFixup = ''
    autoPatchelf $out/opt/balena-etcher
    install -m755 $NIX_BUILD_TOP/etcher-util.pristine \
      $out/opt/balena-etcher/resources/etcher-util
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
