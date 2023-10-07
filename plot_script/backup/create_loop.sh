sudo mount -t tmpfs -o size=180G none /mnt/ram
tail --bytes 179G /dev/zero > /mnt/ram/loopbackfile.img
sudo losetup /dev/loop100 /mnt/ram/loopbackfile.img
sudo mkfs.ext4 /dev/loop100
sudo mount /dev/loop100 /mnt/tmp_vol/
sudo chmod 777 /mnt/tmp_vol/
