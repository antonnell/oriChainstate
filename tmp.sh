#!/bin/sh
SCRIPT=$(cd $(dirname $0); /bin/pwd)
COIN=bitcoin
INCOMING_DIRECTORY=/data/${COIN}/incoming/
CS_OUT_FILE=${INCOMING_DIRECTORY}cs-bitcoin-20181203-0610-CGZ3cas7.out
COPYUTXOS="\\COPY '${COIN}'_utxo(txn_hash, txn_no, address, amount) FROM '${CS_OUT_FILE}' WITH DELIMITER ';' ON CONFLICT DO UPDATE "

source "/opt/chainstate/config.cfg"

echo "Importing UTXOs"
sudo -u postgres psql --host=${host} --port=${port} --username=${username} --dbname=${database} -c "${COPYUTXOS}"

exit 0
