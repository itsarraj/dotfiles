# Static information about the filesystems.
# See fstab(5) for details.

# <file system> <dir> <type> <options> <dump> <pass>
# /dev/mapper/land-root
UUID=52ea8b92-a91c-4b9c-8aca-821764991120	/         	ext4      	rw,relatime	0 1

# /dev/nvme0n1p1
UUID=1B1D-A9D3      	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2


# /dev/sdc1 LABEL=elbe
UUID=74A0D19FA0D167DE  /run/media/uranium/data  ntfs-3g  defaults,noauto,nofail  0  0

/swapfile none swap defaults 0 0

# SATA SSD (NTFS) - Data drive for models, projects, etc.
UUID=74A0D19FA0D167DE  /mnt/data  ntfs-3g  uid=1000,gid=1000,dmask=022,fmask=133,noatime,windows_names,nofail  0  0

# External HDD
# /dev/sdc1 LABEL=elbe
UUID=762D9C7C7E4F79A3  /run/media/uranium/elbe  ntfs-3g  defaults,noauto,nofail  0  0

# /dev/sdc1 LABEL=HDD1
UUID=042BE69517C656C1  /run/media/uranium/HDD1  ntfs-3g  defaults,noauto,nofail  0  0

# /dev/sdc1 LABEL=HDD8
UUID=449353793044BF05  /run/media/uranium/HDD8  ntfs-3g  defaults,noauto,nofail  0  0

# /dev/sdc1 LABEL=HDD10
UUID=1c2b0323-d095-4542-aca6-c18c697178d7  /run/media/uranium/HDD10  ext4  defaults,noauto,nofail  0  0

