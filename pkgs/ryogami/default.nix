# Ryogami: daemon de wallpaper + selector (wall-ui), vendorizado desde
# Ryoku (github.com/Ryoku-dev/ryoku, GPL-3; el wall-ui es MIT de liixini).
#
# Vendorizado a propósito y no pinneado con fetchFromGitHub: llevamos tres
# parches propios sobre este código, y el fork del que salió tiene `main`
# congelado. Mantener parches contra un upstream quieto es lo peor de los dos
# mundos, así que esto pasa a ser código nuestro.
#
# Los tres parches, todos verificados antes de entrar acá:
#   1. wall-ui/qml/services/DaemonClient.qml  — deleteItem mandaba `name` y el
#      daemon lee `key`, así que el botón de borrar no borraba nada.
#   2. (fuera de este paquete, en dotfiles) modules/wallpaper/Singletons/Motion.qml
#      — sacarle la dependencia de `shell.services` deja la superficie autocontenida.
#   3. daemon/verbs.go + wall-ui/{shell.qml,qml/services/DaemonClient.qml} — verbo
#      `browse` para abrir el selector directo en Wallhaven desde un keybind.
#
# NO soportado en esta build, por no estar verificado:
#   - wallpapers de video: QtMultimedia acá no trae backend (falta gstreamer) y
#     el renderer `ryogami-live` (C) no se empaqueta.
#   - upscale con waifu2x: upscale.go apunta a /usr/share/waifu2x-ncnn-vulkan.
{
  lib,
  stdenv,
  go,
  makeWrapper,
  quickshell,
  qt6,
  imagemagick,
  ffmpeg,
  matugen,
  curl,
  inotify-tools,
  coreutils,
  procps,
}:

let
  qtQmlPath = lib.makeSearchPath "lib/qt-6/qml" [
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qt5compat
    qt6.qtsvg
    qt6.qtimageformats
  ];

  # qtimageformats expone los plugins de imagen (libqwebp.so) por QT_PLUGIN_PATH,
  # no por QML_IMPORT_PATH. Sin esto los thumbnails del selector, que son .webp,
  # se renderizan en negro: el log dice "Unsupported image format".
  qtPluginPath = lib.makeSearchPath "lib/qt-6/plugins" [
    qt6.qtimageformats
    qt6.qtsvg
  ];

  runtimePath = lib.makeBinPath [
    coreutils
    procps
    ffmpeg
    imagemagick
    matugen
    curl
    inotify-tools
    quickshell
  ];
in

stdenv.mkDerivation {
  pname = "ryogami";
  version = "0.60.1-rc";

  src = ./.;

  nativeBuildInputs = [
    go
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    root="$PWD"
    cd daemon

    export HOME="$TMPDIR"
    export GOCACHE="$TMPDIR/go-cache"
    export GOTOOLCHAIN=local
    export CGO_ENABLED=0

    go test ./...
    go build -trimpath -o ryogami .

    cd "$root"

    runHook postBuild
  '';

  installPhase = ''
        runHook preInstall

        install -Dm755 daemon/ryogami "$out/bin/ryogami"

        mkdir -p "$out/share/ryogami"
        cp -a wall-ui/. "$out/share/ryogami/"

        # El daemon lanza el selector con `quickshell -p $RYOGAMI_SHELL_QML`, y ese
        # proceso hijo hereda este entorno: sin QML_IMPORT_PATH el selector no
        # encuentra QtMultimedia y directamente no abre.
        # La superficie que PINTA el fondo vive en dotfiles (editable sin rebuild),
        # pero necesita el mismo entorno Qt que el selector. Este wrapper la lanza
        # con ese entorno, para no tener que repetir las variables en el autostart.
        cat > "$out/bin/ryogami-surface" <<'EOS'
    #!/bin/sh
    exec quickshell -p "''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/wallpaper/shell.qml"
    EOS
        chmod +x "$out/bin/ryogami-surface"

        wrapProgram "$out/bin/ryogami-surface" \
          --set QML_IMPORT_PATH "${qtQmlPath}" \
          --set QML2_IMPORT_PATH "${qtQmlPath}" \
          --set QT_PLUGIN_PATH "${qtPluginPath}" \
          --prefix PATH : "${runtimePath}"

        wrapProgram "$out/bin/ryogami" \
          --set RYOGAMI_SHELL_QML "$out/share/ryogami/shell.qml" \
          --set QML_IMPORT_PATH "${qtQmlPath}" \
          --set QML2_IMPORT_PATH "${qtQmlPath}" \
          --set QT_PLUGIN_PATH "${qtPluginPath}" \
          --prefix PATH : "${runtimePath}"

        runHook postInstall
  '';

  meta = {
    description = "Daemon y selector de wallpapers de Ryoku, parcheado";
    homepage = "https://github.com/Ryoku-dev/ryoku";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ryogami";
  };
}
