# nixpkg_apollo

https://github.com/ClassicOldSong/Apollo

version = Apollo-0.3.1-hotfox.1

NIXOS package for installing Apollo gamestreaming client 

I have used https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/su/sunshine/package.nix as a template to get this working.

I've never done anything like this before so could be pretty rough around the edges and some things might not work as intended.

For now it runs and I can connect to Apollo and stream to my phone. I can't however change any settings in webui and it doesn't auto launch steam client.

I can game though when just using desktop and mouse to select game to play.

Copy both the apollo.nix and package-lock.json to folder apollo-nix in location of your choosing.

Then edit you configuration.nix with info from add_to_config file.
