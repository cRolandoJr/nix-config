# Ryogami: daemon de wallpaper + selector, vendorizado desde Ryoku
# (github.com/Ryoku-dev/ryoku, GPL-3; el wall-ui es MIT de liixini).
#
# Vendorizado y no pinneado con fetchFromGitHub porque llevamos parches propios
# sobre este código y el fork del que salió tiene `main` congelado: mantener
# parches contra un upstream quieto es lo peor de los dos mundos. El detalle de
# cada parche vive en el historial de git.
#
# Sin soporte: wallpapers de video (QtMultimedia acá no trae backend y no se
# empaqueta el renderer ryogami-live) y upscale con waifu2x.
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

        # La superficie vive en dotfiles, fuera del store, para poder editarla
        # sin rebuild; este wrapper le da el entorno Qt que igual necesita.
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

        # El daemon lanza el selector como proceso hijo, que hereda este entorno:
        # sin QML_IMPORT_PATH no encuentra QtMultimedia y no abre.
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
