#!/bin/bash

#Definizioni per le cartelle
IPZS_dir="IPZS"
Aut1_dir="Aut1"

#File generati e utili
Aut1_sk="$Aut1_dir/Aut1_sk.pem"
Aut1_csr="$Aut1_dir/Aut1_csr.pem"
Aut1_crt="$Aut1_dir/Aut1_crt.pem"
IPZS_sk="$IPZS_dir/IPZS_sk.pem"
IPZS_crt="$IPZS_dir/IPZS_crt.pem"



#Generazione della chiave privata del'Autorita1
echo "Generazione della chiave privata per Aut1..."
openssl ecparam -genkey -name prime256v1 -out $Aut1_sk

#Creazione richiesta certificato per Aut1
echo "Creazione richiesta certificato dell'Autorita1..."
openssl req -new -key $Aut1_sk -out $Aut1_csr -subj "/C=IT/ST=Lazio/L=Rome/O=Aut1/CN=Autoria1"

#Firma del certificato dell'Autorita1 da parte della CA IPZS
echo "Firma del certificato dell'utente da parte della CA IPZS..."
openssl x509 -req -in $Aut1_csr -CA $IPZS_crt -CAkey $IPZS_sk -CAcreateserial -out $Aut1_crt -days 365 -sha256

#Verifica del certificato dell'Autorita1
echo "Verifica del certificato dell'Autorita1..."
openssl verify -CAfile $IPZS_crt $Aut1_crt