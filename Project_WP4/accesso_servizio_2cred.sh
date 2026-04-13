#!/bin/bash

#Definizioni per le cartelle
Utente_dir="Utente"
Aut1_dir="Aut1"
IPZS_dir="IPZS"
Aut2_dir="Aut2"

#File generali e utili
Utente_sk="$Utente_dir/Utente_sk.pem"
Utente_cert="$Utente_dir/Utente_cert.pem"
Utente_pk="$Utente_dir/Utente_pk.pem"
IPZS_crt="$IPZS_dir/IPZS_crt.pem"
Aut1_crt="$Aut1_dir/Aut1_crt.pem"
Aut1_pk="$Aut1_dir/Aut1_pk.pem"
Aut2_crt="$Aut2_dir/Aut2_crt.pem"
Aut2_pk="$Aut2_dir/Aut2_pk.pem"
Cred_finale="$Utente_dir/Cred_fin.txt"
Cred2_finale="$Utente_dir/Cred2_fin.txt"
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

#L'utente invia al serve per l'accesso la stringa il certificato digitale e le credenziali
echo "Invio al server della stringa, del certificato digitale e delle credenziali..."

##################################################### LATO SERVER #####################################################

#L'autorita riceve la richiesta
echo "Il server riceve le credenziali insieme al certificato e la stringa firmata..."

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

#Estrazione della credenziale 1
source $Cred_finale

Cred_utente=$Credenziale_completa
Root_firmata_utente=$Root_firmata
Cert_aut_utente=$Aut1_crt

IFS=';' read -r Tipo_credenziale Valore_credenziale Data_scadenza_cred <<< "$Cred_utente"

#Estrazione della credenziale 2
source $Cred2_finale

Cred_utente2=$Credenziale_completa2
Root_firmata_utente2=$Root_firmata2
Cert_aut_utente2=$Aut2_crt

IFS=';' read -r Tipo_credenziale2 Valore_credenziale2 Data_scadenza_cred2 <<< "$Cred_utente2"

#Controllo che la data di scadenzia sia valida
if [ $( cat $Data_scadenza_cred) -gt 2024 ]; then
    echo "Verifica della data della prima credenziale riuscita"
else
    echo "Data scaduta"
    exit 1
fi

#Controllo che la data di scadenzia sia valida
if [ $( cat $Data_scadenza_cred2) -gt 2024 ]; then
    echo "Verifica della data della seconda riuscita"
else
    echo "Data scaduta"
    exit 1
fi


#Verifico che il certificato dell'autorita che ha emesso la credenziale 1 sia stato firmato da IPZS
echo "Verifica del certificato dell'autorita che ha rilasciato la credenziale 1..."
openssl verify -CAfile $IPZS_crt $Aut1_crt

if [ $? -eq 0 ]; then
    echo "Verifica del certificati dell'autorita 1 riuscito"
else
    echo "Verifica non riuscita"
    exit 1
fi

#Verifico che il certificato dell'autorita che ha emesso la credenziale 2 sia stato firmato da IPZS
echo "Verifica del certificato dell'autorita che ha rilasciato la credenziale 2..."
openssl verify -CAfile $IPZS_crt $Aut2_crt

if [ $? -eq 0 ]; then
    echo "Verifica del certificati dell'autorita 2 riuscito"
else
    echo "Verifica non riuscita"
    exit 1
fi

#Estrazione chiave pubblica dell'autorita 1 che ha rilasciato le credenziali dal certificato digitale
echo "Estrazione della chiave pubblica dell'autorita 1 che ha rilasciato le credenziali dal certificato digitale..."
openssl x509 -in $Aut1_crt -pubkey -noout -out $Aut1_pk

#Estrazione chiave pubblica dell'autorita 2 che ha rilasciato le credenziali dal certificato digitale
echo "Estrazione della chiave pubblica dell'autorita 2 che ha rilasciato le credenziali dal certificato digitale..."
openssl x509 -in $Aut2_crt -pubkey -noout -out $Aut2_pk

#Calcolo della root del merkle tree per la prima credenziale
echo "Calcolo della root del merkle tree per la prima credenziale..."

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
    echo "Verifica della prima credenziale riuscita"
else
    echo "Verifica della prima credenziale non riuscita"
    exit 1
fi

#Puliamo i dati che non ci servono 
rm Utente_pk.bin Tipo_credenziale.bin Valore_credenziale.bin Data_scad.bin $hash_node1 $hash_node2 $hash_root 


#Calcolo della root del merkle tree per la seconda credenziale
echo "Calcolo della root del merkle tree per la seconda credenziale..."

# File di output per gli hash
hash_node1="hash_node1.bin"
hash_node2="hash_node2.bin"
hash_root="hash_root.bin"

#Calcolo delle foglie e della root
echo "Calcolo delle foglie del Markle tree..."
openssl dgst -sha256 -binary $Utente_pk > Utente_pk.bin
openssl dgst -sha256 -binary $Tipo_credenziale2 > Tipo_credenziale2.bin
openssl dgst -sha256 -binary $Valore_credenziale2 > Valore_credenziale2.bin
openssl dgst -sha256 -binary $Data_scadenza_cred2 > Data_scad2.bin
cat "Utente_pk.bin" "Tipo_credenziale2.bin" | openssl dgst -sha256 -binary > "$hash_node1"
cat "Valore_credenziale2.bin" "Data_scad2.bin" | openssl dgst -sha256 -binary > "$hash_node2"
cat "$hash_node1" "$hash_node2" | openssl dgst -sha256 -binary > "$hash_root"

#Verifica della firma sulla root del merkle tree
echo "Verifica della firma sulla root del merkle tree..."
openssl dgst -sha256 -verify $Aut2_pk -signature $Root_firmata_utente2 $hash_root



if [ $? -eq 0 ]; then
    echo "Verifica della seconda credenziale riuscita"
else
    echo "Verifica della seconda credenziale non riuscita"
    exit 1
fi

#Puliamo i dati che non ci servono 
rm Utente_pk.bin Tipo_credenziale2.bin Valore_credenziale2.bin Data_scad2.bin $hash_node1 $hash_node2 $hash_root $Stringa $Stringa_firmata


echo "Chiusura"