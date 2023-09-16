#!/bin/bash
set -e

#vars
#Number of backups to store
daily_store=6
weekly_store=4
monthly_store=3
yearly_store=1

# Check the first input arguments
if [ -z "$1" ]; then
  read -r -p "Enter path to archive current folder: " STORRAGE_PATH
else
  STORRAGE_PATH=$1
fi

# Check the second input arguments
if [ -z "$2" ]; then
  CURRENT_PATH="$PWD"
elif [ -d "$2" ]; then
    CURRENT_PATH=$2
else
  echo "Wrong path to dir with files."
  exit 1
fi


# Check zip-archiver
if ! zip --version &> /dev/null; then
  echo "You must install zip archiver."
  exit 1
fi

# Backup function
# $1 - path to store archives
backup() {
  day=$(date +%d)
  weekday=$(date +%u) # 7 - is Sunday
  month=$(date +%m)
  backup_type="daily"

  if [ "$day" == "31" ] && [ "$month" == "12" ]; then
      backup_type="yearly"
  elif [ "$day" == "01" ]; then
      backup_type="monthly"
  elif [ "$weekday" == "7" ]; then
      backup_type="weekly"
  fi

  # Create dir
  backup_dir="$1/$backup_type"
  mkdir -p "$backup_dir"  
  backup_file="$(date +%Y-%m-%d_%H-%M-%S)_$(basename "$CURRENT_PATH").zip"
  backup_file_path="$backup_dir/$backup_file"
  # Make archive
  zip -r "$backup_file_path" "$CURRENT_PATH"
  status=$?
  if [ $status -eq 0 ]; then
    echo "Backup $backup_file_path has been created."
  else
    echo "Can't create backup"
    return $status
  fi
}

# Clean folder
# $1 - storrage_path
# $2 - backup_type
# $3 - numbers of files to store
clean_folder() {
  if [ ! -d "$1/$2" ]; then
    echo "There isn't $2 folder yet."
    return 0
  fi

  foldername="$(basename "$CURRENT_PATH")"
  # list of files sorted by time only for CURRENT FOLDER name
  files=$(ls -t "$1/$2/"*_"$foldername.zip")
  count=$(echo "$files" | wc -l)

  if [ "$count" -gt "$3" ]; then
      echo "$files" | tail -n +$(($3 + 1)) | xargs rm -f
      echo "Removed $((count - $3)) files in $1/$2 archives for $foldername."
  else
      echo "No files to remove in $1/$2 archives for $foldername."
  fi
}

# Clean backups
clean_backups() {
  clean_folder "$STORRAGE_PATH" "daily" "$daily_store"
  clean_folder "$STORRAGE_PATH" "weekly" "$weekly_store"
  clean_folder "$STORRAGE_PATH" "monthly" "$monthly_store"
  clean_folder "$STORRAGE_PATH" "yearly" "$yearly_store"
}

backup "$STORRAGE_PATH"
clean_backups