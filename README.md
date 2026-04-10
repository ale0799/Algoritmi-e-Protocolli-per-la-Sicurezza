# Algoritmi-e-Protocolli-per-la-Sicurezza: Sistema di Gestione Credenziali Digitali

## Descrizione
Questo progetto implementa un sistema per la **gestione e verifica di credenziali digitali**, che permette agli utenti di accedere a servizi protetti in modo sicuro.

L’utente può:
- autenticarsi tramite identità digitale
- richiedere credenziali a un’autorità
- utilizzare tali credenziali per accedere a servizi

Il sistema verifica automaticamente la validità delle credenziali prima di concedere l’accesso.

---

## Obiettivo
Garantire che solo utenti autorizzati possano accedere a determinati servizi, mantenendo sicurezza e affidabilità durante tutto il processo.

---

## Funzionalità principali

- Creazione e gestione di certificati digitali
- Rilascio di credenziali da parte di autorità fidate
- Verifica delle credenziali lato server
- Accesso ai servizi con una o più credenziali
- Simulazione completa del flusso di autenticazione

---

## Implementazione (WP4)

Il progetto include una serie di script Bash che simulano il funzionamento del sistema:

- inizializzazione dell’ambiente
- generazione certificati utente e autorità
- richiesta credenziali
- accesso ai servizi

Sono supportati:
- accesso con una credenziale
- accesso con più credenziali

---

## Esecuzione

### Accesso con una credenziale

./init.sh
./certificato_utente.sh
./certificato_autorità.sh
./richiesta_rilascio_credenziali.sh
./accesso_servizio.sh


### Accesso con due credenziali
./init.sh
./certificato_utente.sh
./certificato_autorità.sh
./certificato_autorità2.sh
./richiesta_rilascio_credenziali.sh
./richiesta_rilascio_credenziali2.sh
./accesso_servizio_2cred.sh

## Tecnologie utilizzate
- Tecnologie utilizzate
- Bash scripting
- OpenSSL
- Certificati digitali X.509
- Crittografia asimmetrica
- Firma digitale (ECDSA)
- Hashing (SHA-256)
- Protocollo TLS

## Team
- Alessia Lettieri (ale0799)
- Marco Panico (mpanico20)
- Domenico Napolitano (Domy0909)
- Alessandro Passannante (AlessandroPassannanteUNI)
