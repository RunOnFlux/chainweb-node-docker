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
  BOOTSTRAPLOCATIONS[3]="http://78.46.17.79:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=72bba4cba2ec8fed703fd29b2cd75bf132d8c3ca65b389a0653149214e759449"
  BOOTSTRAPLOCATIONS[4]="http://78.46.17.80:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=8348d5425cba5cee51acb98003a139dbbe7d7b11c8f44bc838b73a83833d9a04"
  BOOTSTRAPLOCATIONS[5]="http://78.46.17.81:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=46b61b5207abd775f23b5a6abf2c0e5c8613ac3647dc610e36109354927c4712"
  BOOTSTRAPLOCATIONS[6]="http://65.109.53.14:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=cbc1f0509759ca3e833b546868d5fd13f423a9eaab0e91bb8dceb8c41ef9b25a"
  BOOTSTRAPLOCATIONS[7]="http://65.109.53.15:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=6c176db3dd7458f6d6104462e2c8a55a2d361aebe58b2d0e673020203de9274b"
  BOOTSTRAPLOCATIONS[8]="http://65.108.35.254:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=7fa6bb76331a5479b6a2976399bc8c29cc1cd9b56d5677e2cdaac7ce6e6ecbe8"
  BOOTSTRAPLOCATIONS[9]="http://65.108.199.67:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=f0d1f8ee3db3cc9a4c87d80fa3ea87410b93391cfebaa346149bf964364d0761"
  
  retry=0
  file_lenght=0
  while [[ "$file_lenght" -lt "10000000000" && "$retry" -lt 6 ]]; do
    index=$(shuf -i 0-9 -n 1)
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
