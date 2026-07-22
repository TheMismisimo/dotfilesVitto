{ config, pkgs, ... }:

{
  networking.wg-quick.interfaces = {
    wg-trabajo = {
      # El túnel estará activo en segundo plano sin secuestrar el internet
      autostart = true; 

      address = [ "172.16.253.3/24" "fc00:0:0:216::5/128" ];
      listenPort = 13232;
      
      privateKeyFile = "/home/armando/.wireguard/wg_trabajo.key";

      peers = [
        {
          publicKey = "9Drx46p9Ja7UijYiIPLwDcPv1en7io0VZyOTnEUoqno=";
          
          # Split Tunneling: Solo encripta el tráfico hacia estas IPs
          allowedIPs = [ 
            "10.16.58.96/32" # Cerebro
            "10.16.58.97/32" # Proxy Acceso
            "10.16.58.98/32" # Proxy Checkpoint
          ];
          
          endpoint = "cd620c93c068.sn.mynetname.net:13232";
          persistentKeepalive = 30;
        }
        {
          publicKey = "//////////////////////////////////////////8=";
          allowedIPs = [ "0.0.0.0/32" ]; 
          endpoint = "cd620c93c068.sn.mynetname.net:13232";
          persistentKeepalive = 15;
        }
      ];
    };
  };
}