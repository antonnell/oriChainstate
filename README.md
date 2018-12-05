# Bitcoin core chainstate parser

It is based on bitcoin core 0.15.1 client.

The bitcoin core's chainstate stores all blockchain's UTXOs. By parsing it, you can know where bitcoins are, how much are stored on each wallets, etc.

This parser handles all types of bitcoins addresses, like P2PKH (starting by 1), P2SH (starting by 1 or 3) and newer P2WPKH (bech32).

Some code was ripped of the Bitcoin core client, by the way. So, this software is under MIT licence.


# dependencies


Couple of libraries required for chainstate/levevldb

```
apt-get update
apt-get install autoconf libtool libleveldb-dev libssl-dev git build-essential cmake
```


You need to get google's leveldb with C++ headers installed, or it won't compile/link.

## Installing Level DB

```
export VER="1.20"
wget https://github.com/google/leveldb/archive/v${VER}.tar.gz
tar xvf v${VER}.tar.gz
rm -f v${VER}.tar.gz

cd leveldb-${VER}

make
scp -r out-static/lib* out-shared/lib* "/usr/local/lib"
cd include
scp -r leveldb /usr/local/include
ldconfig
```

You need to get PostgreSQL otherwsie you will not be able to copy data to the RDS.


## Installing PostgreSQL

```
apt-get install postgresql postgresql-contrib
```


## Installing the relevant blockcahin

```
install bitcoinCore
install litecoinCore
install dashCore
install bitcoin-abc
```

## Creating output directories

```
mkdir /data/bitcoin
mkdir /data/bitcoin-abc
mkdir /data/litecoin
mkdir /data/dashcore
```


# Chainstate

## Config

create config.cfg file for postgres connection details

## Build

```base
$ git submodule init
$ git submodule update
$ make
[...]
g++ -o chainstate chainstate.o hex.o varint.o pubkey.o -Lsecp256k1/.libs -lsecp256k1 -lcrypto -lleveldb -Llibbase58/.libs -lbase58 -Lbech32/ref/c -lbech32
$
```

If it doesn't build, you may have additional deps configured in a submodule. You will want to add those deps into the Makefile as well. Or you can also contribute by doing a proper Makefile ;)


# Run

You should stop bitcoin's client or daemon before running:

```
./run.sh bitcoin bitcoin
./run.sh dashcore dashcore
./run.sh litecoin litecoin
./run.sh bitcoin-abc bitcoin
```

# Want to thank me ? More feature or more explanations ?

Full credit goes to the original developer: https://github.com/mycroft/chainstate
Information on how to contribute to him below.

Please consider helping him:

- BTC: 3G734WzCrphZxN7afnrbwunZjV8MBqWUUV
- BCH: 1MQEd3csWAVRWcgVbqk8CoZYf312VM9vp1
- LTC: MEQA2uDajDiT3EyH1opRvNwywTDLvskLnq
