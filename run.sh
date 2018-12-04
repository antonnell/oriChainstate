#!/bin/sh
source ./config.cfg

SCRIPT=$(cd $(dirname $0); /bin/pwd)
COIN=${1:-bitcoin}
COINDIR=${2:-$COIN}
RANDOMSTR=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
INCOMING_DIRECTORY=/data/${COIN}/incoming/
BALANCES_FILE=${INCOMING_DIRECTORY}balances-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.out
CS_OUT_FILE=${INCOMING_DIRECTORY}cs-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.out
CS_ERR_FILE=${INCOMING_DIRECTORY}cs-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.err
COPYUTXOS="\\COPY '${COIN}'_utxo(txn_hash, txn_no, address, amount) FROM '${CS_OUT_FILE}' WITH DELIMITER ';' ON CONFLICT DO UPDATE "
COPYACCOUNTS="\\COPY '${COIN}'_balances(acc_hash, balance) FROM '${BALANCES_FILE}' WITH DELIMITER ';' ON CONFLICT DO UPDATE"

echo "Cleaning old state files..."
rm state/*

echo "Copying chainstate..."
cp -Rp ~/.${COINDIR}/chainstate/* state

echo "Syncing..."
sync

echo "Running chainstate parser..."
./chainstate ${COIN} >${CS_OUT_FILE} 2>${CS_ERR_FILE}

if test ! -e ${CS_OUT_FILE}; then
    echo "Missing input file (${CS_OUT_FILE})"
    exit 1
fi

echo "Generating & sorting final balances..."
cut -d';' -f3,4 ${CS_OUT_FILE} | \
    sort | \
    awk -F ';' '{ if ($1 != cur) { if (cur != "") { print cur ";" sum }; sum = 0; cur = $1 }; sum += $2 } END { print cur ";" sum }' | \
    sort -t ';' -k 2 -g -r > ${BALANCES_FILE}

echo "Importing UTXOs"
sudo -u postgres $(psql --host=${host} --port=${port} --username=${username} --password=${password} --dbname=${database} -c "${COPYUTXOS}")

echo "Importing Accounts"
sudo -u postgres $(psql --host=${host} --port=${port} --username=${username} --password=${password} --dbname=${database} -c "${COPYACCOUNTS}")

exit 0
