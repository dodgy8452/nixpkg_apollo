# nixpkg_apollo
Package for installing Apollo gamestreaming client 
version = Apollo-0.3.1-hotfox.1

Edit you configuration.nix with the following lines:

environment.systemPackages = with pkgs; [                          
  (callPackage /path/to/file/apollo.nix { })
];

networking.firewall = {
    enable = true; # Ensure the firewall is enabled
    allowedTCPPorts = [
         80 # TCP port 80  
        443 # TCP port 443
      47984 # TCP port 47984
      47989 # TCP port 47989
      47990 # TCP port 47990
      48010 # TCP port 48010
    ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48000; } # UDP ports 47998 to 48000
    ];
  };
  
  # Add the package to security.wrappers
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = toString (pkgs.callPackage /path/to/file/apollo.nix { }) + "/bin/sunshine"; # Absolute path to the binary
  };

