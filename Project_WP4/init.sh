#Definizione cartelle IPZS, AUt1 e Utente
IPZS_dir="IPZS" 
Aut1_dir="Aut1" #Cartella per autorita riconosciuta per il rilascio delle credenziali
Utente_dir="Utente" #Cartella per l'utente 

#Creazione cartelle se non esistono
mkdir -p $IPZS_dir
mkdir -p $Aut1_dir
mkdir -p $Utente_dir

echo "Le directory sono state create correttamente"

