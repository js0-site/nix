{pkgs, ...}: {
  system.activationScripts = {
    setNoCOW = {
      text = ''
        dirs=("/data" "/var/log" "/tmp")

        for dir in "''${dirs[@]}"; do
          ${pkgs.e2fsprogs}/bin/lsattr -d $dir | grep -q C || ${pkgs.e2fsprogs}/bin/chattr +C $dir
        done

        mkdir -p /usr/local/bin
        chmod 755 /usr/local/bin
      '';
    };
    syncDiskFiles = {
      text = ''
        rsync="${pkgs.rsync}/bin/rsync -av"
        $rsync ${./disk}/ /
        $rsync ${./vps}/disk/ /
      '';
    };
  };
}
