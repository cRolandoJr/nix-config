{
  pkgs,
  lib,
  ...
}:

# Servidor de modelos local. Escucha en 127.0.0.1:11434 y habla el protocolo de
# OpenAI en /v1, que es el tercer adaptador que ai-loop-cli ya trae cableado
# (ANTHROPIC_API_KEY -> GEMINI_API_KEY -> OPENAI_BASE_URL). Arranque manual:
# `sudo systemctl start ollama`.

{
  services.ollama = {
    enable = true;

    # La aceleración se elige por paquete: ollama{,-cpu,-vulkan,-rocm,-cuda}.
    # (`acceleration` está deprecada en este nixpkgs y la assertion lo rechaza.)
    #
    # CPU a propósito, no por no tener GPU. Con 4 GB de VRAM un modelo de 7B en Q4
    # no entra junto con el contexto, así que la GPU compraría poco; con 30 GB de
    # RAM el camino de CPU es el que sirve para el modelo que queremos.
    # Gatillo para revisar: si bajamos a un modelo de <=3B, probar `ollama-vulkan`
    # ANTES que `ollama-rocm` — la dGPU es Navi 24 (gfx1034), que ROCm no soporta
    # oficialmente y sólo anda haciéndola pasar por gfx1030, mientras que Vulkan
    # la maneja por RADV sin trucos.
    package = pkgs.ollama-cpu;

    # El loop hace 3-6 llamadas por fase con una revisión humana en el medio. Con
    # el default de 5 min el modelo se descarga entre revisión y revisión y hay
    # que releer 5 GB cada vez.
    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "30m";

      # Sin esto ollama elige la ventana POR VRAM, y con 4 GB nos manda al
      # escalón de 4096 aunque qwen2.5-coder soporte 32768. Medido: el prompt
      # inicial de ailoop ya usa ~2000 tokens, y al pasarse ollama TRUNCA EN
      # SILENCIO lo más viejo — que es el system prompt y el protocolo de
      # herramientas. El síntoma es un agente que "no sabe usar herramientas".
      # 16k y no 32k: el KV cache en CPU cuesta velocidad y el enmascarado de
      # ailoop arranca a los 12k igual.
      OLLAMA_CONTEXT_LENGTH = "16384";
    };
  };

  # La CLI, para `ollama pull` y `ollama ps` desde el usuario.
  environment.systemPackages = [ pkgs.ollama ];

  # Sin autostart, por el mismo criterio que k3s: un servicio cuyo costo en reposo
  # no se midió arranca a mano. Revertir es borrar esta línea.
  systemd.services.ollama.wantedBy = lib.mkForce [ ];
}
