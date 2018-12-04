#!/bin/sh
SCRIPT=$(cd $(dirname $0); /bin/pwd)
COIN=bitcoin
INCOMING_DIRECTORY=/data/${COIN}/incoming/
CS_OUT_FILE=${INCOMING_DIRECTORY}cs-bitcoin-20181203-0610-CGZ3cas7.out
DROP="DROP TABLE IF EXISTS tmp_bitcoin_utxo"
CREATE="CREATE TABLE tmp_bitcoin_utxo AS SELECT * FROM bitcoin_utxo WITH NO DATA;"
COPY="\\COPY tmp_bitcoin_utxo (txn_hash, txn_no, address, amount) FROM '${CS_OUT_FILE}' WITH DELIMITER ';';"
INSERT="INSERT INTO bitcoin_utxo SELECT * FROM tmp_bitcoin_utxo ON CONFLICT DO NOTHING;"

. /opt/chainstate/config.cfg

echo "Importing UTXOs"
sudo -u postgres PGPASSWORD=${password} psql --host=${host} --port=${port} --username=${username} --dbname=${database} -c "${DROP}" -c "${CREATE}" -c "${COPY}" -c "${INSERT}"

exit 0
