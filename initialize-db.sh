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
      tar -xzvf bootstrap.tar.gz -C "$DBDIR"
      rm bootstrap.tar.gz
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
  # Getting Kadena bootstrap from Zel Servers
  BOOTSTRAPLOCATIONS[0]="http://89.58.3.209:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=675c85498d3d97bf5a0d36608ac55be5d63903b3cd0d6e8a38d319e844987d60"
  BOOTSTRAPLOCATIONS[1]="http://202.61.228.139:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=44415ab654fdaa89ce133bb1f03c6de075b6302c4a6fe6c3019efff9e10ea5f1"
  BOOTSTRAPLOCATIONS[2]="http://45.129.181.236:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=b42f0511bc6f3407cbb9cbc370f0a3a4f2b3940bcdf91421d308d6702c10d336"
  BOOTSTRAPLOCATIONS[3]="http://89.58.42.150:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=5ca646c197ad4cac9148455a6305ffeb846e821f3c5989f4551f69832663f3bc"
  BOOTSTRAPLOCATIONS[4]="http://202.61.243.237:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=13ea8054ac9613c54585b11308deea2740a9d9ff8e87793ce8d78f92417440ad"
  BOOTSTRAPLOCATIONS[5]="http://202.61.198.226:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=ec32b56c1469fd8fad8c58549953fa565e5ceab3ab6c57ad9f637b458f69f610"
  BOOTSTRAPLOCATIONS[6]="http://89.58.40.63:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=b20d0f90e1db2b80144884d4b7d21ca9b9c37ec1e0d885084613f5dbfcf536f6"
  BOOTSTRAPLOCATIONS[7]="http://37.120.188.23:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=66cf92f65800150a1c77f82c9ff7bdfa8f87410d9103263087a8410e8a129a5e"
  BOOTSTRAPLOCATIONS[8]="http://89.58.14.237:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=1808a0d0e45e9487db9e7ddac750f7faa02fd4d913bd4e172859b3c0380cd467"
  BOOTSTRAPLOCATIONS[9]="http://89.58.9.63:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=3677ad691a4c7baa13d9fed727de8cc1856f6fd55954b66d4918b8bd35ae171d"
  BOOTSTRAPLOCATIONS[10]="http://94.130.141.124:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=5d9a1f7c355f8ac2794ab7d1d586b9d2dc8b59e66902cfe18161d6bb34d5ecc5"
  BOOTSTRAPLOCATIONS[11]="http://176.9.16.182:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=68d225cd8a60095f70c28aa0674ac5c8a0dc28b300ce50f0ffc18b0e439d5c74"
  BOOTSTRAPLOCATIONS[12]="http://78.46.108.106:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=2bc3905b7421f156412286149374307b94b362290665176616fd3164c9473c79"
  BOOTSTRAPLOCATIONS[13]="http://195.201.57.122:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=5b2cac3d7888085ea55e30287c9f3ceb85905542bb7bfc1aaac92470479c176b"
  BOOTSTRAPLOCATIONS[14]="http://157.90.177.126:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=37a6312de5857959bdffa913dbd1d7f456515333747b0669c37f476b6e01b0c4"
  BOOTSTRAPLOCATIONS[15]="http://135.181.20.225:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=ce6c87d4b396215738c386f9718bf51fc56480802fcb69d4fd17ca162d792832"
  BOOTSTRAPLOCATIONS[16]="http://135.181.79.234:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=2b00cbb24154ecca46b2900d0d6f6c43ed3ed3ad75cbfc6ba0c9bce79a6e66ab"
  BOOTSTRAPLOCATIONS[17]="http://95.217.121.248:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=76458423547e15c08a9b55aeb0ecd7e840c514af7d74cdbe311828db7af43f65"
  BOOTSTRAPLOCATIONS[18]="http://135.181.57.52:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=15d134572455ce52c4dcf9b912a68b40fe5cecbb9bcdf453ff565600f6de848b"
  BOOTSTRAPLOCATIONS[19]="http://65.108.9.188:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=35b2419d88ce8f7640b03d265d33a1eb525ff31b64324c5a45f4505c7df35277"
  BOOTSTRAPLOCATIONS[20]="http://46.38.251.26:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=02e709cbd26bb9328dd3d9dc1fa44db8cea2da127ed8e7ed76473eee4f4a484e"
  BOOTSTRAPLOCATIONS[21]="http://5.45.111.210:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=259106bf5dbbff5f017019bf38a9b6127a323238f6da0f327fe855b26a1e3940"
  BOOTSTRAPLOCATIONS[22]="http://46.38.236.130:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=acc08adedbdcc04d7515d0f6deb803da9f1320eec17f5109942b399b0eea1aab"
  BOOTSTRAPLOCATIONS[23]="http://37.120.175.86:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=68ab87b2d31fe71760981de56b9d3e4b156aa93de1e3d3f87e085508ba57bd98"
  BOOTSTRAPLOCATIONS[24]="http://185.16.61.122:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=fc0de5b33759a9b5499e2a45b3f8a262102c078100e506445e72f90406268ba2"
  BOOTSTRAPLOCATIONS[25]="http://89.58.42.201:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=54ee1f03e69f290cca03944be2f1ff84361fd97b71b37159dce543ae9667f22a"
  BOOTSTRAPLOCATIONS[26]="http://37.221.197.179:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=f455d3594e62ae3ae2527f51e4160e60695b175532186b50dd9cbd3f86232a89"
  BOOTSTRAPLOCATIONS[27]="http://89.58.37.73:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=6cce25a5555322f4b51c18f8a3a6556f27a0c0f5abd1ba25c2d9aed2a07482ec"
  BOOTSTRAPLOCATIONS[28]="http://45.129.182.59:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=70b7d6b180ef278427eef82c125007d46e55367238887af3e55476c25041c4a7"
  BOOTSTRAPLOCATIONS[29]="http://94.16.104.218:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=8a515213f43959357085ee185d334c40a883f1f139e5cd51526ebd6f605a719f"
  BOOTSTRAPLOCATIONS[30]="http://65.108.226.146:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=7f726610528e52c964344130c799a3a81b428c779a4a3d88d5e1ea1026213812"
  BOOTSTRAPLOCATIONS[31]="http://65.108.33.215:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=193df95005b56540ce3a4ac37cbc6173885cbcd7b63419596d263715ff0d6c8b"
  BOOTSTRAPLOCATIONS[32]="http://5.9.77.39:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=47e1163d7d985788ad55147560a80add6675a945a4340e45098a7052185bdb65"
  BOOTSTRAPLOCATIONS[33]="http://176.9.183.28:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=3646aa306c9afc9fbde9fef7963cf916530b20112458110b9a1abb227ed7b1eb"
  BOOTSTRAPLOCATIONS[34]="http://65.108.230.174:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=4fad996b740c5c659ef9e21d9f2209d63769396700be14174d861d931a59ce88"
  BOOTSTRAPLOCATIONS[35]="http://65.108.230.178:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=64501876cdd7f249df8376428bd1fbfa15c3499110a58b45945c464448e071ce"
  BOOTSTRAPLOCATIONS[36]="http://65.108.230.178:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=64501876cdd7f249df8376428bd1fbfa15c3499110a58b45945c464448e071ce"
  BOOTSTRAPLOCATIONS[37]="http://65.108.230.184:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=7b949f458abe0fb35d64a8ce566c30f0a23d0812f09e17b0bc3bc68450d9be56"
  BOOTSTRAPLOCATIONS[38]="http://65.108.226.203:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=bdf5e43ac6f0cce414cc9e708c70db172cf71688e9fee82d61e2d5c991818f5c"
  BOOTSTRAPLOCATIONS[39]="http://65.108.226.234:16127/apps/fluxshare/getfile/kda_bootstrap.tar.gz?token=3e905c2a9683a35b56f614ff4d7390572793ffc887ed6a0846c86bda6217b9bd"
  BOOTSTRAP_LENGTH=${#BOOTSTRAPLOCATIONS[@]}
  retry=0
  file_lenght=0
  while [[ "$file_lenght" -lt "10000000000" && "$retry" -lt 6 ]]; do
    index=$(shuf -i 0-$(($BOOTSTRAP_LENGTH-1)) -n 1)
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
      -o bootstrap.tar.gz "${BOOTSTRAPLOCATIONS[$index]}"
  else
    echo "None bootstrap was found, will download blockchain from node peers"
  fi
fi
