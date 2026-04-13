#!/bin/bash

#Definizioni per le cartelle
Utente_dir="Utente"
Aut1_dir="Aut1"
IPZS_dir="IPZS"

#File generali e utili
Utente_sk="$Utente_dir/Utente_sk.pem"
Utente_cert="$Utente_dir/Utente_cert.pem"
Utente_pk="$Utente_dir/Utente_pk.pem"
IPZS_crt="$IPZS_dir/IPZS_crt.pem"
Aut1_crt="$Aut1_dir/Aut1_crt.pem"
Aut1_pk="$Aut1_dir/Aut1_pk.pem"
Cred_finale="$Utente_dir/Cred_fin.txt"
Stringa="$Utente_dir/stringa.txt"
Stringa_firmata="$Utente_dir/stringa_firmata.sig"

#Supponiamo che tra l'utente e l'autorita di rilascio credenziali ci sia una comunicazione TLS
#quindi tutti i dati scabiati tra le due parti sono cifrati e sicuri

##################################################### LATO UTENTE ##################################################### 
#L'utente accede identificansodi con la propria CIE
echo "Inserimento del Pin della CIE..."
CIE_PIN="123456789" #Supponiamo l'utente abbia inserito il pin e che il pin corretto sia 123456789

if [ "$CIE_PIN" != "123456789" ]; then
    echo "Pin errato"
    exit 1
else
    echo "Pin corretto"
fi

#Supponiamo che l'utente abbia ricevuto dall'autorita una stringa casuale da firmare
echo "prova" > $Stringa

#L'utente firma una stringa casuale con la sua sk per dimostrare all'autorita che e il possessore della CIE
echo "Firma stringa casuale con sk..."
openssl dgst -sha256 -sign $Utente_sk -out $Stringa_firmata $Stringa

#L'utente invia al serve per l'accesso la stringa il certificato digitale e la credenziale
echo "Invio al server della stringa, del certificato digitale e della credenziale..."

##################################################### LATO SERVER #####################################################

#L'autorita riceve la richiesta
echo "Il server riceve la credenziale insieme al certificato e la stringa firmata..."

#Verifica del certificato dell'utente
echo "Verifica del certificato dell'utente..."
openssl verify -CAfile $IPZS_crt $Utente_cert

if [ $? -eq 0 ]; then
    echo "Verifica del certificato riuscita"
else
    echo "certificato non valido"
    exit 1
fi

#Estrazione chiave pubblica dell'utente dal certificato digitale
echo "Estrazione della chiave pubblica dal certificato digitale dell'utente..."
openssl x509 -in $Utente_cert -pubkey -noout -out $Utente_pk

#Verifica della firma sulla stringa casuale
echo "Verifica della firma sulla stringa casuale..."
openssl dgst -sha256 -verify $Utente_pk -signature $Stringa_firmata $Stringa

if [ $? -eq 0 ]; then
    echo "Verifica della firma riuscita"
else
    echo "Firma non valida"
    exit 1
fi

#Estrazione delle credenziali
source $Cred_finale

Cred_utente=$Credenziale_completa
Root_firmata_utente=$Root_firmata
Cert_aut_utente=$Aut1_crt

IFS=';' read -r Tipo_credenziale Valore_credenziale Data_scadenza_cred <<< "$Cred_utente"



#Controllo che la data di scadenzia sia valida
if [ $( cat $Data_scadenza_cred) -gt 2024 ]; then
    echo "Verifica della data riuscita"
else
    echo "Data scaduta"
    exit 1
fi


#Verifico che il certificato dell'autorita che ha emesso le credenziali sia stato firmato da IPZS
echo "Verifica del certificato dell'autorita che ha rilasciato le credenziali..."
openssl verify -CAfile $IPZS_crt $Aut1_crt

if [ $? -eq 0 ]; then
    echo "Verifica del certificati dell'autorita riuscito"
else
    echo "Verifica non riuscita"
    exit 1
fi

#Estrazione chiave pubblica dell'autorita che ha rilasciato le credenziali dal certificato digitale
echo "Estrazione della chiave pubblica dell'autorita che ha rilasciato le credenziali dal certificato digitale..."
openssl x509 -in $Aut1_crt -pubkey -noout -out $Aut1_pk

#Calcolo della root del merkle tree
echo "Calcolo della root del merkle tree..."

# File di output per gli hash
hash_node1="hash_node1.bin"
hash_node2="hash_node2.bin"
hash_root="hash_root.bin"

#Calcolo delle foglie e della root
echo "Calcolo delle foglie del Markle tree..."
openssl dgst -sha256 -binary $Utente_pk > Utente_pk.bin
openssl dgst -sha256 -binary $Tipo_credenziale > Tipo_credenziale.bin
openssl dgst -sha256 -binary $Valore_credenziale > Valore_credenziale.bin
openssl dgst -sha256 -binary $Data_scadenza_cred > Data_scad.bin
cat "Utente_pk.bin" "Tipo_credenziale.bin" | openssl dgst -sha256 -binary > "$hash_node1"
cat "Valore_credenziale.bin" "Data_scad.bin" | openssl dgst -sha256 -binary > "$hash_node2"
cat "$hash_node1" "$hash_node2" | openssl dgst -sha256 -binary > "$hash_root"

#Verifica della firma sulla root del merkle tree
echo "Verifica della firma sulla root del merkle tree..."
openssl dgst -sha256 -verify $Aut1_pk -signature $Root_firmata_utente $hash_root



if [ $? -eq 0 ]; then
    echo "Verifica delle credenziali riuscita"
else
    echo "Verifica delle credenziali non riuscita"
    exit 1
fi

#Puliamo i dati che non ci servono 
rm Utente_pk.bin Tipo_credenziale.bin Valore_credenziale.bin Data_scad.bin $hash_node1 $hash_node2 $hash_root $Stringa $Stringa_firmata

echo "Chiusura"