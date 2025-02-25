# S3 File Handler

## Descrizione
Questo script Python si collega ad un bucket S3 di Amazon, elenca i file presenti, filtra quelli che contengono una stringa specificata in un file di input, li scarica e li pulisce, salvandoli nella cartella appropriata mantenendo la struttura originale del bucket.

## Funzionalità principali
- **Elenco file S3**: Recupera la lista completa dei file nel bucket, senza filtri di prefisso.
- **Filtro per data**: Può considerare solo file modificati in un intervallo di tempo specificato.
- **Download dei file**: Scarica solo i file che contengono una stringa presente in `delivery_3PL.txt`.
- **Pulizia dei file**: Rimuove tutto ciò che è presente dopo `_w_` nel nome del file.
- **Salvataggio nella struttura originale**: I file puliti vengono salvati nella directory `cleaned_files/`, rispettando la sottocartella originale del bucket.
- **Log dei file mancanti**: Registra i file che non sono stati trovati e salva l'elenco in `missing_files.txt`.

## Requisiti
- Python 3.7+
- AWS CLI configurato con credenziali valide oppure un file `.env` contenente:
  ```ini
  AWS_ACCESS_KEY_ID=your_access_key
  AWS_SECRET_ACCESS_KEY=your_secret_key
  AWS_SESSION_TOKEN=your_session_token
  ```
- Librerie Python necessarie:
  ```bash
  pip install boto3 python-dotenv
  ```

## Come usarlo
1. **Configurare le credenziali AWS**
   - Assicurarsi che il file `.env` sia correttamente impostato o che le credenziali siano configurate tramite `aws configure`.
   
2. **Preparare il file di input**
   - Creare un file `delivery_3PL.txt` contenente una lista di stringhe (una per riga) che devono essere cercate nei nomi dei file S3.
   
3. **Eseguire lo script la prima volta**
   ```bash
   setup.ps1
   ```

3. **Eseguire lo script successivamente**
   ```bash
   run.ps1
   ```

4. **Output**
   - I file scaricati si trovano in `downloaded_files/`
   - I file puliti sono salvati in `cleaned_files/` rispettando la struttura delle cartelle del bucket.
   - I file mancanti sono registrati in `missing_files.txt`.

## Debug e Log
- I log sono stampati in console per tracciare il progresso.
- È possibile modificare il livello di log da `INFO` a `DEBUG` nel codice per avere più dettagli:
  ```python
  logging.basicConfig(level=logging.DEBUG)
  ```

## Limitazioni e miglioramenti futuri
- Attualmente, i file vengono filtrati solo in base alla stringa nel nome.
- Potrebbe essere utile aggiungere un'opzione per eseguire il processo in parallelo per una maggiore efficienza.
- Integrazione con servizi di notifiche per segnalare errori e successi.