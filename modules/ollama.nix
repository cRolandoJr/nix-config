{
  pkgs,
  lib,
  ...
}:

# Arranque manual: `sudo systemctl start ollama`.
{
  services.ollama = {
    enable = true;
    # CPU por VRAM de 4 GB; para <=3B probar ollama-vulkan antes que rocm (gfx1034).
    package = pkgs.ollama-cpu;

    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "30m";
      # Sin esto, 4 GB VRAM fuerza contexto de 4096 y trunca el system prompt.
      OLLAMA_CONTEXT_LENGTH = "16384";
    };
  };

  environment.systemPackages = [ pkgs.ollama ];
  systemd.services.ollama.wantedBy = lib.mkForce [ ];
}
