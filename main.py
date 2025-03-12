import boto3
import os
import re
import logging
from datetime import datetime

# Configurazione logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Carica le variabili d'ambiente dal file .env
from dotenv import load_dotenv
load_dotenv()  

# Configurazione
BUCKET_NAME = "demetra-filestore-prd"
DOWNLOAD_DIR = "downloaded_files/"
CLEANED_DIR = "cleaned_files/"
LIST_FILE = "list.txt"
TIME_RANGE = ("2025-02-03", "2025-02-11")  # Facoltativo, formato YYYY-MM-DD
MISSING_FILES_LOG = "missing_files.txt"

# Connessione a S3
session = boto3.Session(
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    aws_session_token=os.getenv("AWS_SESSION_TOKEN")
)
s3 = session.client("s3")

def list_s3_files(bucket, time_range=None):
    if time_range==None:
        logger.info(f"Recupero lista file da bucket: {bucket},\nsenza filtri di prefisso,\nsenza TIME_RANGE")
    else:
        logger.info(f"Recupero lista file da bucket: {bucket},\nsenza filtri di prefisso,\nTIME_RANGE = {time_range}")
    files = []
    paginator = s3.get_paginator("list_objects_v2")
    
    for page in paginator.paginate(Bucket=bucket):
        if "Contents" in page:
            for obj in page["Contents"]:
                key = obj["Key"]
                last_modified = obj["LastModified"].strftime("%Y-%m-%d")
                
                if time_range:
                    start_date, end_date = time_range
                    if not (start_date <= last_modified <= end_date):
                        continue  # Salta i file fuori range
                
                files.append(key)
    logger.info(f"Trovati {len(files)} file nel bucket.")
    return files

def download_s3_file(bucket, key, download_dir):
    local_filename = os.path.join(download_dir, key)
    os.makedirs(os.path.dirname(local_filename), exist_ok=True)
    
    try:
        logger.debug(f"Scaricamento file: {key}")
        s3.download_file(bucket, key, local_filename)
        logger.info(f"File scaricato: {local_filename}")
        return local_filename
    except Exception as e:
        logger.error(f"Errore nel download {key}: {e}")
        return None

def clean_file(filename, cleaned_dir, original_key):
    cleaned_subdir = os.path.join(cleaned_dir, os.path.dirname(original_key))
    os.makedirs(cleaned_subdir, exist_ok=True)
    base, ext = os.path.splitext(filename)
    cleaned_name = re.sub(r"_w_.*", "", base) + ext
    cleaned_path = os.path.join(cleaned_subdir, os.path.basename(cleaned_name))
    
    with open(filename, "rb") as src, open(cleaned_path, "wb") as dst:
        dst.write(src.read())
    
    logger.info(f"File pulito salvato in: {cleaned_path}")

def main():
    # Lista dei file nel bucket
    # s3_files = list_s3_files(BUCKET_NAME, TIME_RANGE)
    s3_files = list_s3_files(BUCKET_NAME)
    
    # Leggi la lista dei nomi file da cercare
    with open(LIST_FILE, "r") as f:
        search_list = set(line.strip() for line in f.readlines())
    
    missing_files = []
    
    # Processa i file trovati in S3
    counter = 0
    for s3_file in s3_files:
        if any(item in s3_file for item in search_list):
            counter = counter + 1
            logger.debug(f"Match trovato: {s3_file}")
            local_file = download_s3_file(BUCKET_NAME, s3_file, DOWNLOAD_DIR)
            if local_file:
                clean_file(local_file, CLEANED_DIR, s3_file)
            else:
                missing_files.append(s3_file)
    
    if counter > 0:
        logger.error(f"✅ Trovati {counter} elementi su {len(search_list)}")
        if missing_files:
            logger.warning(f"⚠️ File mancanti {len(missing_files)} su {len(search_list)}")
            with open(MISSING_FILES_LOG, "w") as f:
                for missing in missing_files:
                    f.write(missing + "\n")
            logger.info(f"✅ Lista file mancanti salvata in {MISSING_FILES_LOG}")
        else:
            logger.info(f"✅ Tutti i {len(search_list)} file richiesti sono stati scaricati e puliti con successo.")
    else:
        logger.error(f"❌ Nessun elemento dei {len(search_list)} presenti sulla lista trovato")
    
if __name__ == "__main__":
    main()
