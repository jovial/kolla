#!/bin/bash
## ================================================
## CONSTANTS
## ================================================
BACKUP_DIR='/var/local/backup'
BACKUP_RETENTION='7'
MYSQL_USER='backup'
MYSQL_PASS=xxx
USE_INNOBACKUPX='true'
PRUNE_BACKUPS='true'
COMPRESS_BACKUPS='true'
XTRABACKUP_OPTIONS=''
INNOBACKUPX_OPTIONS=''
LOGFILE='/var/log/xtrabackup.log'
BACKUP_LOCATION="${BACKUP_DIR}/`date +%F`"
## ================================================
## FUNCTIONS
## ================================================
exit_with_error ()
{
  log "ERROR: $*"
  log "ERROR: There was a problem with the xtrabackup run. See the logfile: ${LOGFILE}"
  exit 1
}

log () {
  LOGSTRING="[ `date +%Y/%m/%d:%H:%M:%S` ] : $*"
  echo ${LOGSTRING}
  echo ${LOGSTRING} >> ${LOGFILE}
}

check_status () {
  if [ $? -ne 0 ]; then
    exit_with_error "$1 Something went wrong with the backup. View the log file for more
Info."
    exit 1
  Fi
}

prepare_env() {
  mkdir -p ${BACKUP_LOCATION}
}

run_xtrabackup() {
  log "INFO: Starting backup process"
  time xtrabackup ${XTRABACKUP_OPTIONS} --backup --user ${MYSQL_USER} --password ${MYSQL_PASS}
--target-dir=${BACKUP_LOCATION} >> ${LOGFILE} 2>&1
  Check_status
  log "INFO: Preparing backup files phase 1"
  time xtrabackup --prepare --target-dir=${BACKUP_LOCATION} >> ${LOGFILE} 2>&1
  Check_status
  log "INFO: Preparing backup files phase 2"
  time xtrabackup --prepare --target-dir=${BACKUP_LOCATION} >> ${LOGFILE} 2>&1
  Check_status
  log "INFO: Backup Process Complete"
}
run_innobackupx() {
  log "INFO: Starting backup process"
  time innobackupex ${INNOBACKUPX_OPTIONS} ${BACKUP_LOCATION} >> $LOGFILE 2>&1
  Check_status
  log "INFO: Preparing backup files"
  INNOBACKUP_LOCATION=$(find ${BACKUP_LOCATION}/* -type d -print -quit)
  time innobackupex --apply-log $INNOBACKUP_LOCATION >> $LOGFILE 2>&1
  Check_status
  log "INFO: Backup Process Complete"
}
run_prune_backups() {
  log "INFO: Clearing backups older than ${BACKUP_RETENTION} days"
  find ${BACKUP_DIR}/* -type d -ctime +${BACKUP_RETENTION} -exec rm -rf {} + >> ${LOGFILE} 2>&1
  Check_status
}

run_compress_backups() {
  log "INFO: Compressing backups"
  time innobackupex --stream=tar ${INNOBACKUP_LOCATION} | bzcat -zc > ${BACKUP_LOCATION}/$(date +%Y%m%d-%H%M%S).tar.bz2 && rm -r ${INNOBACKUP_LOCATION}
  Check_status
}
## ================================================
## MAIN
## ================================================
prepare_env
if [ ${USE_INNOBACKUPX} == true ]; then
  run_innobackupx
else
  run_xtrabackup
fi
if [ ${PRUNE_BACKUPS} == true ]; then
  run_prune_backups
fi
if [ ${COMPRESS_BACKUPS} == true ]; then
  run_compress_backups
fi
