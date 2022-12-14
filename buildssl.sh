#!/bin/bash
script_path=$(dirname "$(readlink -f "$0")")
cd "${script_path}" || exit 1
pwd
built_openssl="${script_path}"/openssl111s
if test -d "${built_openssl}"
then
    echo "found directory ${built_openssl}, delete it first"
else
    mkdir -p "${built_openssl}"
fi
if test -f openssl-OpenSSL_1_1_1s.zip 
then
    if test -d openssl-OpenSSL_1_1_1s
    then
        rm -rfv openssl-OpenSSL_1_1_1s
    fi
    unzip openssl-OpenSSL_1_1_1s.zip
    if test -d openssl-OpenSSL_1_1_1s
    then
        echo "unzipped openssl-OpenSSL_1_1_1s"
        pushd openssl-OpenSSL_1_1_1s||exit 1
        find ./ -type f |xargs touch
        rm -rf doc
        popd
    else
        echo "failed to unzip openssl-OpenSSL_1_1_1s"
        exit 1
    fi
    if test -d buildssl
    then
        rm -rfv buildssl
    fi
    mkdir buildssl
    pushd buildssl || exit 1
        ../openssl-OpenSSL_1_1_1s/config no-asm no-shared -fvisibility=hidden --prefix="${built_openssl}"
        make
        make install
    popd ||exit 1
else
    echo "no fount openssl-OpenSSL_1_1_1s.zip"
    exit 1
fi
