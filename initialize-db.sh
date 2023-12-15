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
  BOOTSTRAPLOCATIONS[0]="http://142.132.150.31:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=540f604432e32e447f4a190e14587c5bfbd442ae4f9214b81a37a88a9bfa04ea"
  BOOTSTRAPLOCATIONS[1]="http://116.202.193.182:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=d94ede1c1fc6354aa1966f5c64e8c0590143ba1a2393270dd6def39bca9d2f2f"
  BOOTSTRAPLOCATIONS[2]="http://78.46.72.53:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=df661f6c8b3f609f2c731bf91e2f84529b80d7fa40d967231e2e6d7e8fa6462d"
  BOOTSTRAPLOCATIONS[3]="http://95.216.46.168:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=806a3d70149f5b51acff805b07a657054c7ce3cca22a5f2385bcb3affb609dc9"
  BOOTSTRAPLOCATIONS[4]="http://95.217.73.231:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=d41b04e0e59a709b3aad3023b2a47498dc3803b2f80984c451e9ad8145ed2f18"
  BOOTSTRAPLOCATIONS[5]="http://195.201.199.62:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=04f6233f31fc663967cbf6a9724c2ef7abc2047956b60fe47415dc8bfb26bc46"
  BOOTSTRAPLOCATIONS[6]="http://65.108.103.229:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=485f92ab5a086b9916fd59826d92a7c7465774a8f52bbda0b781a48964834708"
  BOOTSTRAPLOCATIONS[7]="http://5.9.120.15:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=9d36e5f5d105e10aa3b082d35d929d0d20ab38c8c18f61a5cd962e868521bd4e"
  BOOTSTRAPLOCATIONS[8]="http://95.216.117.49:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=1230e2de0e0d8d55e2f77d30a199604315779169aac713f5647d1581856fe981"
  BOOTSTRAPLOCATIONS[9]="http://95.216.34.93:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=08ad452eabaf7e5e4a82fcf1dfd2a9657c4224fa9cbad0d6e669021bed5f0303"
  BOOTSTRAPLOCATIONS[10]="http://95.216.35.182:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=68a17f6f328d1bc94fb938832fe705330eb7f13918c63e11d891412763ea9872"
  BOOTSTRAPLOCATIONS[11]="http://176.9.168.217:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=35e5b71516ff65ea320fb13aa5a2e2d33334ab40889a5ca651ef5d320e9734e2"
  BOOTSTRAPLOCATIONS[12]="http://95.216.29.182:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=635d692bb00e58d39e30cb8babe1d5e66616e3f45f5399a4b4de83b882f6537d"
  BOOTSTRAPLOCATIONS[13]="http://94.130.160.243:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=bbec1f5f4a8686954a0643d0e9fcc87420940232bc2b9cc9fa39191ced85b224"
  
  retry=0
  file_lenght=0
  while [[ "$file_lenght" -lt "10000000000" && "$retry" -lt 6 ]]; do
    index=$(shuf -i 0-13 -n 1)
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
