#!/bin/sh
xtrabackup --backup --target-dir=/backup
xtrabackup --prepare --target-dir=/backup
xtrabackup --print-param --prepare --target-dir=/backup
