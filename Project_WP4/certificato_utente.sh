#!/bin/bash

#Definizioni per le cartelle
IPZS_dir="IPZS"
Utente_dir="Utente"

#File generati
IPZS_sk="$IPZS_dir/IPZS_sk.pem"
IPZS_crt="$IPZS_dir/IPZS_crt.pem"
Utente_sk="$Utente_dir/Utente_sk.pem"
Utente_cer_csr="$Utente_dir/Utente_cer_csr.pem"
Utente_cert="$Utente_dir/Utente_cert.pem"

#Generazione chiave privata per la CA IPZS
echo "Generazione chiave privata IPZS..."
openssl ecparam -genkey -name prime256v1 -out $IPZS_sk

#Creazione del certificato autofirmato della CA IPZS
echo "Generazione certificato autofirmato per la CA IPZS..."
openssl req -x509 -new -key $IPZS_sk -sha256 -days 365 -out $IPZS_crt -subj "/C=IT/ST=Lazio/L=Rome/O=IPZS/CN=IPZS_CA"

#Creazione chiave privata per l'utente
echo "Generazione chiave private per l'utente..."
openssl ecparam -genkey -name prime256v1 -out $Utente_sk

#Creazione richiesta certificato dell'utente
echo "Creazione richiesta certificato dell'utente..."
openssl req -new -key $Utente_sk -out $Utente_cer_csr -subj "/C=IT/ST=Lazio/L=Rome/O=ExampleO/CN=ExampleCN" 

#Firma del certificato dell'utente da parte della CA IPZS
echo "Firma del certificato dell'utente da parte della CA IPZS..."
openssl x509 -req -in $Utente_cer_csr -CA $IPZS_crt -CAkey $IPZS_sk -CAcreateserial -out $Utente_cert -days 365 -sha256

#Verifica del certificato dell'utente
echo "Verifica del certificato dell'utente..."
openssl verify -CAfile $IPZS_crt $Utente_cert


