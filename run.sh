#!/bin/sh
SCRIPT=$(cd $(dirname $0); /bin/pwd)
COIN=${1:-bitcoin}
COINDIR=${2:-$COIN}
TABLE=${3:-$COIN}
RANDOMSTR=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
INCOMING_DIRECTORY=/data/${COIN}/incoming/
ARCHIVE_DIRECTORY=/data/${COIN}/archive/
BALANCES_FILE=balances-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.out
CS_OUT_FILE=cs-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.out
CS_ERR_FILE=cs-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}.err
UTXO_DROP="DROP TABLE IF EXISTS tmp_${TABLE}_utxo"
UTXO_CREATE="CREATE TABLE tmp_${TABLE}_utxo AS SELECT * FROM ${TABLE}_utxo WITH NO DATA;"
UTXO_COPY="\\COPY tmp_${TABLE}_utxo (txn_hash, txn_no, address, amount) FROM '${INCOMING_DIRECTORY}${CS_OUT_FILE}' WITH DELIMITER ';';"
UTXO_DROP_MAIN="DROP TABLE IF EXISTS ${TABLE}_utxo"
UTXO_RENAME="ALTER TABLE tmp_${TABLE}_utxo RENAME TO ${TABLE}_utxo"
UTXO_INSERT="INSERT INTO ${TABLE}_utxo SELECT * FROM tmp_${TABLE}_utxo ON CONFLICT DO NOTHING;"
ACC_DROP="DROP TABLE IF EXISTS tmp_${TABLE}_accounts"
ACC_CREATE="CREATE TABLE tmp_${TABLE}_accounts AS SELECT * FROM ${TABLE}_accounts WITH NO DATA;"
ACC_COPY="\\COPY tmp_${TABLE}_accounts (acc_hash, balance) FROM '${INCOMING_DIRECTORY}${BALANCES_FILE}' WITH DELIMITER ';';"
ACC_DROP_MAIN="DROP TABLE IF EXISTS ${TABLE}_accounts"
ACC_RENAME="ALTER TABLE tmp_${TABLE}_accounts RENAME TO ${TABLE}_accounts"
ACC_INSERT="INSERT INTO ${TABLE}_accounts SELECT * FROM tmp_${TABLE}_accounts ON CONFLICT DO NOTHING;"

echo "Killing blockchain daemon"
if [ "${COIN}" = "bitcoin" ]
then
  bitcoin-cli stop &
fi

if [ "${COIN}" = "bitcoin-abc" ]
then
  /opt/bitcoin-abc/bitcoin-abc-0.18.4/bin/bitcoin-cli stop &
fi

if [ "${COIN}" = "litecoin" ]
then
  /opt/litecoin/litecoin-0.16.3/bin/litecoin-cli stop &
fi

if [ "${COIN}" = "dashcore" ]
then
  /opt/dashcore/dashcore-0.12.3/bin/dash-cli stop &
fi

wait

echo "Cleaning old state files..."
rm state/*

echo "Copying chainstate..."
cp -Rp ~/.${COINDIR}/chainstate/* state

echo "Syncing..."
sync

echo "Running chainstate parser..."
./chainstate ${COIN} >${INCOMING_DIRECTORY}${CS_OUT_FILE} 2>${INCOMING_DIRECTORY}${CS_ERR_FILE}

if test ! -e ${INCOMING_DIRECTORY}${CS_OUT_FILE}; then
    echo "Missing input file (${CS_OUT_FILE})"
    exit 1
fi

echo "Generating & sorting final balances..."
cut -d';' -f3,4 ${INCOMING_DIRECTORY}${CS_OUT_FILE} | \
    sort | \
    awk -F ';' '{ if ($1 != cur) { if (cur != "") { print cur ";" sum }; sum = 0; cur = $1 }; sum += $2 } END { print cur ";" sum }' | \
    sort -t ';' -k 2 -g -r > ${INCOMING_DIRECTORY}${BALANCES_FILE}

. /opt/chainstate/config.cfg

echo "Importing UTXOs"
sudo -u postgres PGPASSWORD=${password} psql --host=${host} --port=${port} --username=${username} --dbname=${database} -c "${UTXO_DROP}" -c "${UTXO_CREATE}" -c "${UTXO_COPY}" -c "${UTXO_DROP_MAIN}" -c "${UTXO_RENAME}" -c "${UTXO_DROP}"

echo "Importing Accounts"
sudo -u postgres PGPASSWORD=${password} psql --host=${host} --port=${port} --username=${username} --dbname=${database} -c "${ACC_DROP}" -c "${ACC_CREATE}" -c "${ACC_COPY}" -c "${ACC_DROP_MAIN}" -c "${ACC_RENAME}" -c "${ACC_DROP}"

echo "Moving Files"
mv ${INCOMING_DIRECTORY}${BALANCES_FILE} ${ARCHIVE_DIRECTORY}${BALANCES_FILE}
mv ${INCOMING_DIRECTORY}${CS_OUT_FILE} ${ARCHIVE_DIRECTORY}${CS_OUT_FILE}
mv ${INCOMING_DIRECTORY}${CS_ERR_FILE} ${ARCHIVE_DIRECTORY}${CS_ERR_FILE}

echo "Killing blockchain daemon"
if [ "${COIN}" = "bitcoin" ]
then
  bitcoind -daemon
fi

if [ "${COIN}" = "bitcoin-abc" ]
then
  /opt/bitcoin-abc/bitcoin-abc-0.18.4/bin/bitcoind -daemon
fi

if [ "${COIN}" = "litecoin" ]
then
  /opt/litecoin/litecoin-0.16.3/bin/litecoind -daemon
fi

if [ "${COIN}" = "dashcore" ]
then
  /opt/dashcore/dashcore-0.12.3/bin/dashd -daemon
fi

exit 0
