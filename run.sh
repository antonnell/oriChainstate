#!/bin/sh

SCRIPT=$(cd $(dirname $0); /bin/pwd)
COIN=${1:-bitcoin}
COINDIR=${2:-$COIN}
RANDOMSTR=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
BALANCES_FILE=balances-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}
CS_OUT_FILE=cs-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.out
CS_ERR_FILE=cs-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.err

echo "Cleaning old state files..."
rm state/*

echo "Copying chainstate..."
cp -Rp ~/.${COINDIR}/chainstate/* state

echo "Syncing..."
sync

echo "Running chainstate parser..."
./chainstate ${COIN} >${CS_OUT_FILE} 2>${CS_ERR_FILE}

echo "Generated output:"
ls -l ${CS_OUT_FILE} ${CS_ERR_FILE}

if test ! -e ${CS_OUT_FILE}; then
    echo "Missing input file (${CS_OUT_FILE})"
    exit 1
fi

echo "Generating & sorting final balances..."
cut -d';' -f3,4 ${CS_OUT_FILE} | \
    sort | \
    awk -F ';' '{ if ($1 != cur) { if (cur != "") { print cur ";" sum }; sum = 0; cur = $1 }; sum += $2 } END { print cur ";" sum }' | \
    sort -t ';' -k 2 -g -r > ${BALANCES_FILE}

echo "Compressing balances"
gzip ${BALANCES_FILE}

echo "Generated archive:"
ls -l ${BALANCES_FILE}.gz

echo "Moving state"
mv /opt/chainstate/${CS_OUT_FILE} /data/${COIN}/
mv /opt/chainstate/${CS_ERR_FILE} /data/${COIN}/
mv /opt/chainstate/${BALANCES_FILE}.gz /data/${COIN}/


exit 0
