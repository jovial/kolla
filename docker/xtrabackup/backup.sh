#!/bin/sh
BACKUP_DIR=/backup/

if [ -d $BACKUP_DIR/base ]; then
	xtrabackup --backup --target-dir=$BACKUP_DIR/incremental \
		--incremental-basedir=$BACKUP_DIR/base
else
	xtrabackup --backup --target-dir=$BACKUP_DIR/base
	xtrabackup --prepare --target-dir=$BACKUP_DIR/base
	xtrabackup --print-param --prepare --target-dir=$BACKUP_DIR/base
fi

