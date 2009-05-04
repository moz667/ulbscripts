AUX_FECHA="`date +%Y%m%d_%H%M`"

BCK_FIL_DIR="/var/backups/backup-dir"

mkdir -p $BCK_FIL_DIR/$1

tar c -v $1 | bzip2 > $BCK_FIL_DIR/$1/$AUX_FECHA.tar.bz2

