#!/bin/bash -xe
# -*- coding: utf-8 -*-

case "$TRAVIS_OS_NAME" in
  "osx")
    # Install Wine
    mkdir /tmp/osx-wine
    pushd /tmp/osx-wine
    wget https://dl.winehq.org/wine-builds/macosx/i686/portable-winehq-devel-1.9.12-osx64.tar.gz
    tar --strip-components=2 -xf *.tar.gz
    ls -l bin
    popd
    echo "$PATH"
    which wine
    # Create CA
    openssl req -newkey rsa:4096 -days 1 -x509 -nodes -subj \
      "/C=CI/ST=Travis/L=Developer/O=Developer/CN=Developer CA" \
      -out /tmp/root.cer -keyout /tmp/root.key
    touch /tmp/certindex
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
      /tmp/root.cer
    # Create dev certificate
    openssl req -newkey rsa:1024 -nodes -subj \
      "/C=CI/ST=Travis/L=Developer/O=Developer/CN=Developer CodeCert" \
      -out codesign.csr -keyout codesign.key
    openssl ca -batch -config $(pwd)/test/ci/dev_ca.cnf -notext -create_serial \
      -in codesign.csr -out codesign.cer
    openssl pkcs12 -export -in codesign.cer -inkey codesign.key -out codesign.p12 -password pass:12345
    security import codesign.p12 -k ~/Library/Keychains/login.keychain -P 12345 -T /usr/bin/codesign
    ;;
esac
