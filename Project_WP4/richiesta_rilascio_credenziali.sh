#!/bin/bash

#Definizioni per le cartelle
Utente_dir="Utente"
Aut1_dir="Aut1"
IPZS_dir="IPZS"
IPZS_crt="$IPZS_dir/IPZS_crt.pem"

#File generati e utili
Utente_sk="$Utente_dir/Utente_sk.pem"
Utente_cert="$Utente_dir/Utente_cert.pem"
Utente_pk="$Utente_dir/Utente_pk.pem"
Aut1_crt="$Aut1_dir/Aut1_crt.pem"
Aut1_sk="$Aut1_dir/Aut1_sk.pem"
Aut1_pk="$Aut1_dir/Aut1_pk.pem"
Richiesta="$Utente_dir/richiesta_cred.txt"
Stringa="$Utente_dir/stringa.txt"
Stringa_firmata="$Utente_dir/stringa_firmata.sig"
Root_firmata="$Utente_dir/root_firmata.sig"
Cred_finale="$Utente_dir/Cred_fin.txt"
Richiesta="$Utente_dir/richiesta.txt"
Data_scadenza_cred="$Utente_dir/data_scadenza.txt"
Tipo_credenziale="$Utente_dir/tipo_credenziale.txt"
Valore_credenziale="$Utente_dir/valore_credenziale.txt"

#Supponiamo che tra l'utente e l'autorita di rilascio credenziali ci sia una comunicazione TLS
#quindi tutti i dati scambiati tra le due parti sono cifrati e sicuri

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


echo "ISEE" > $Tipo_credenziale
Richiesta_credenziale="<5000"


#Richiesta delle credenziali da parte dell'utente
echo "Richiesta per una specifica credenziale" # (ad esempio ISEE<5000)
echo -e "Tipo_credenziale=\"$Tipo_credenziale\"\nRichiesta_credenziale=\"$Richiesta_credenziale\"" > "$Richiesta"


#Supponiamo che l'utente abbia ricevuto dall'autorita una stringa casuale da firmare
echo "prova" > $Stringa

#L'utente firma la stringa casuale con la sua sk per dimostrare all'autorita che e il possessore della CIE
echo "Firma stringa casuale con sk..."
openssl dgst -sha256 -sign $Utente_sk -out $Stringa_firmata $Stringa

#Invio richiesta credenziale all'autorita
echo "L'utente invia all'autorita la richiesta di credenziale insieme alla stringa firmata ed al suo certificato digitale..."
cat $Richiesta

##################################################### LATO AUTORITA #####################################################

#L'autorita riceve la richiesta
echo "L'autorita riceve la richesta insieme al certificato e la stringa firmata..."

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

#Controllo che l'utente rispetti i requisiti per avere le credenziali
echo "Controllo requisiti per l'utente..." #In questo caso ISEE < 5000
#Supponiamo che l'utente rispetti in questo caso i requisiti sull'ISEE e il suo ISEE sia di 2500
echo "2500" > $Valore_credenziale
echo "Requisiti soddisfatti. Rilascio credenziali..."

#Creazione della credenziale
echo "Creazione della credenziale..."
echo "2026" > $Data_scadenza_cred #Supponiamo che la scadenza della credenziale sia nel 2026

#Creazione Merkle tree
echo "Creazione Merkle tree..."

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

#Firma della root con chiave privata dell'autorita
echo "Firma della root con chiave privata dell'autorita..."
openssl dgst -sha256 -sign $Aut1_sk -out $Root_firmata $hash_root


# Rilascio delle credenziali all'utente insieme al proprio certificato digitale
Credenziale_completa="$Tipo_credenziale;$Valore_credenziale;$Data_scadenza_cred;"
echo -e "Credenziale_completa=\"$Credenziale_completa\"\nRoot_firmata=\"$Root_firmata\" \nCertificato_aut=\"$Aut1_crt\" " > $Cred_finale


#Puliamo i dati che non ci servono 
rm Utente_pk.bin Tipo_credenziale.bin Valore_credenziale.bin Data_scad.bin $hash_node1 $hash_node2 $hash_root $Stringa $Stringa_firmata
