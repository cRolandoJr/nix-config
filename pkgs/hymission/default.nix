{ pkgs, src }:

pkgs.hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "hymission";
  version = "0.12.1-4fe476c";
  inherit src;

  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    python3
  ];

  buildInputs = with pkgs; [
    lua
    glib
    gtk4
    libadwaita
    gtk4-layer-shell
    wayland
  ];

  cmakeFlags = [
    "-DBUILD_TESTING=ON"
    "-DHYPRLAND_TEST_EXECUTABLE=${pkgs.hyprland}/bin/.Hyprland-wrapped"
  ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    ctest --output-on-failure
    runHook postCheck
  '';

  meta = {
    description = "Mission Control overview for Hyprland";
    license = pkgs.lib.licenses.gpl3Only;
  };
}
