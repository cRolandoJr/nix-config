_: {
  # 1. Bloquear módulos de kernel innecesarios (reduce superficie de ataque)
  # - acpi_tad: corrige tu /dev/rtc (pasa a usar rtc_cmos) y quita el error ACPI VRTC.
  # - dccp, sctp, rds, tipc: protocolos de red poco usados con historial de CVEs.
  boot.blacklistedKernelModules = [
    "acpi_tad"
    "dccp"
    "sctp"
    "rds"
    "tipc"
  ];

  # 2. Parámetros de seguridad del kernel (sysctl)
  boot.kernel.sysctl = {
    # --- Protección de memoria y kernel ---
    # Oculta direcciones de memoria del kernel en /proc/kallsyms (dificulta exploits locales)
    "kernel.kptr_restrict" = 2;
    # Bloquea eBPF para usuarios sin privilegios (vector frecuente de escalada de privilegios)
    "kernel.unprivileged_bpf_disabled" = 1;
    # Endurece el compilador JIT de BPF contra JIT-spraying
    "net.core.bpf_jit_harden" = 2;
    # Evita que binarios setuid generen coredumps con secretos en memoria
    "fs.suid_dumpable" = 0;

    # --- Protección de archivos temporales (/tmp) ---
    # Previene ataques TOCTOU / secuestro de FIFOs y archivos en directorios sticky (/tmp)
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # --- Red (anti-spoofing y anti-MITM) ---
    # No aceptar redirecciones ICMP falsas (evita desvío de tráfico en Wi-Fi públicas)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # No enviar redirecciones ICMP
    "net.ipv4.conf.all.send_redirects" = 0;
    # Reverse Path Filtering en modo loose (2): protege contra IP spoofing
    # sin romper VPNs, podman ni libvirtd (1 es estricto y puede cortar VMs)
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
    # Registrar paquetes con IPs imposibles ("martians") en los logs
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
  };

  # 3. Limitar retención de coredumps en disco (privacidad/seguridad)
  systemd.coredump.settings.Coredump = {
    MaxUse = "100M";
  };
}
