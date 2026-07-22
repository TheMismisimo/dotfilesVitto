{
  config,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;

    # 1. Soluciona la segunda advertencia (apaga los defaults inyectados)
    enableDefaultConfig = false;

    # 2. Reemplaza matchBlocks por settings
    settings = {
      # Configuración de GitHub
      "github.com" = {
        Hostname = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      # Atajo para el servidor Cerebro
      "cerebro" = {
        Hostname = "10.16.58.96";
        User = "pi";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      # Atajo para el Proxy de cámaras de acceso
      "proxy_acceso" = {
        Hostname = "10.16.58.97";
        User = "armando";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      # Atajo para el Proxy de cámaras de checkpoint
      "proxy_checkpoint" = {
        Hostname = "10.16.58.98";
        User = "armando";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      # Atajo para el servidor de accessme
      "droplet_accessme" = {
        Hostname = "143.198.154.101";
        User = "armando";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      # Atajo para Droplet de servicios
      "droplet_servicios" = {
        Hostname = "174.138.73.97";
        User = "root"; # O el usuario que uses en DigitalOcean
        IdentityFile = "~/.ssh/id_ed25519_do"; # Puedes separar llaves por seguridad
      };
    };
  };

  services.ssh-agent.enable = true;
}
