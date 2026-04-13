#!/bin/bash

#Definizioni per le cartelle
IPZS_dir="IPZS"
Aut2_dir="Aut2"

#Creazione cartelle se non esistono
mkdir -p $Aut2_dir

#File generati e utili
Aut2_sk="$Aut2_dir/Aut2_sk.pem"
Aut2_csr="$Aut2_dir/Aut2_csr.pem"
Aut2_crt="$Aut2_dir/Aut2_crt.pem"
IPZS_sk="$IPZS_dir/IPZS_sk.pem"
IPZS_crt="$IPZS_dir/IPZS_crt.pem"



#Generazione della chiave privata del'Autorita2
echo "Generazione della chiave privata per Aut2..."
openssl ecparam -genkey -name prime256v1 -out $Aut2_sk

#Creazione richiesta certificato per Aut2
echo "Creazione richiesta certificato dell'Autorita2..."
openssl req -new -key $Aut2_sk -out $Aut2_csr -subj "/C=IT/ST=Lazio/L=Rome/O=Aut1/CN=Autoria2"

#Firma del certificato dell'Autorita2 da parte della CA IPZS
echo "Firma del certificato dell'utente da parte della CA IPZS..."
openssl x509 -req -in $Aut2_csr -CA $IPZS_crt -CAkey $IPZS_sk -CAcreateserial -out $Aut2_crt -days 365 -sha256

#Verifica del certificato dell'Autorita2
echo "Verifica del certificato dell'Autorita2..."
openssl verify -CAfile $IPZS_crt $Aut2_crt