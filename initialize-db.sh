#!/usr/bin/env bash

# Retries a command a configurable number of times with backoff.
#
# The retry count is given by ATTEMPTS (default 5), the initial backoff
# timeout is given by TIMEOUT in seconds (default 1.)
#
# Successive backoffs double the timeout.
function with_backoff() {
  local max_attempts=${ATTEMPTS-5}
  local timeout=${TIMEOUT-1}
  local attempt=1
  local exitCode=0

  while (($attempt < $max_attempts)); do
    if "$@"; then
      echo "Bootstrap downloaded creating $DBDIR"
      mkdir -p "$DBDIR"
      echo "Extracting bootstrap to $DBDIR"
      tar -xzvf /data/bootstrap.tar.gz -C "$DBDIR"
      rm /data/bootstrap.tar.gz
      echo "Bootstrap extract finish"
      return 0
    else
      exitCode=$?
    fi

    echo "Failure! Retrying in $timeout.." 1>&2
    sleep $timeout
    attempt=$((attempt + 1))
    timeout=$((timeout * 2))
  done

  if [[ $exitCode != 0 ]]; then
    rm -rf /data/chainweb-db/
    echo "Failed for the last time! ($@)" 1>&2
  fi

  return $exitCode
}

DBDIR="/data/chainweb-db/0"
# Double check if dbdir already exists, only download bootstrap if it doesn't
if [ -d $DBDIR ]; then
  echo "Directory $DBDIR already exists, we will not download any bootstrap, if you want to download the bootstrap you need to delete chainweb-db folder first"
else
  echo "$DBDIR does not exists, lets download the bootstrap"
  # Getting Kadena bootstrap from Flux Servers
  BOOTSTRAPLOCATIONS[0]="http://176.9.51.184:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=fbb8fd41babd63052cc7f45e31b6c84a7bdc935ee7266ca3bd297c8801940a97"
  BOOTSTRAPLOCATIONS[1]="http://176.9.51.185:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=624152edfc15c3c81d68303605e8a035a211cb99012c176c5661478202455e73"
  BOOTSTRAPLOCATIONS[2]="http://176.9.51.186:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=4c1427e81900cf4634e9a17009845053cc3383ac0c8fcc985d17f8488788f126"
  
  retry=0
  file_lenght=0
  while [[ "$file_lenght" -lt "10000000000" && "$retry" -lt 6 ]]; do
    index=$(shuf -i 0-2 -n 1)
    echo "Testing bootstrap location ${BOOTSTRAPLOCATIONS[$index]}"
    file_lenght=$(curl -sI -m 5 ${BOOTSTRAPLOCATIONS[$index]} | egrep 'Content-Length|content-length' | sed 's/[^0-9]*//g')

    if [[ "$file_lenght" -gt "10000000000" ]]; then
      echo "File lenght: $file_lenght"
    else
      echo "File not exist! Source skipped..."
    fi
    retry=$(expr $retry + 1)
  done


  if [[ "$file_lenght" -gt "10000000000" ]]; then
    echo "Bootstrap location valid"
    echo "Downloading bootstrap"
    # Install database
    with_backoff curl --keepalive-time 30 \
      -C - \
      -o /data/bootstrap.tar.gz "${BOOTSTRAPLOCATIONS[$index]}"
  else
    echo "None bootstrap was found, will download blockchain from node peers"
  fi
fi
