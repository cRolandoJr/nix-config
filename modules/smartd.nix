_:

{
  services.smartd = {
    enable = true;
    # autodetect (default true) → DEVICESCAN toma /dev/nvme0n1 solo.
    # Self-tests programados. Formato smartd.conf: T/MES/DÍA/DÍA-SEMANA/HORA (.=cualquiera).
    # S/../.././02 = short diario 02:00; L/../../7/04 = long los domingos(7) 04:00.
    # defaults.autodetected hereda de monitored, así que aplica al device escaneado.
    defaults.monitored = "-a -s (S/../.././02|L/../../7/04)";
    notifications = {
      systembus-notify.enable = true; # system-bus → mako (Wayland)
      x11.enable = false; # default true por el xserver del greeter SDDM; xmessage no va en Wayland
      # wall.enable queda true (default): cablea el -M exec + fallback a terminales
      # mail.enable queda false (default): sin MTA
      test = true; # notif de prueba al arrancar; poner false tras verificar
    };
  };
}
