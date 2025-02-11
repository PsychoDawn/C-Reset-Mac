#!/bin/bash

# Konfigürasyon dosya yolu
STORAGE_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"

# Rastgele ID oluştur
generate_random_id() {
    openssl rand -hex 32
}

# Rastgele UUID oluştur
generate_random_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# Yeni oluştur IDs
NEW_MACHINE_ID=${1:-$(generate_random_id)}
NEW_MAC_MACHINE_ID=$(generate_random_id)
NEW_DEV_DEVICE_ID=$(generate_random_uuid)

# Yedek oluştur
backup_file() {
    if [ -f "$STORAGE_FILE" ]; then
        cp "$STORAGE_FILE" "${STORAGE_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
        echo "Yedekleme dosyası oluşturuldu."
    fi
}

# Dizinin var olduğunu doğrula
mkdir -p "$(dirname "$STORAGE_FILE")"

# Yedek oluştur
backup_file

# Eğer dosya mevcut değilse, yeni bir JSON oluştur
if [ ! -f "$STORAGE_FILE" ]; then
    echo "{}" > "$STORAGE_FILE"
fi

# Tüm telemetri ID'lerini güncelle
tmp=$(mktemp)
perl -i -pe 's/"telemetry\.machineId":\s*"[^"]*"/"telemetry.machineId": "'$NEW_MACHINE_ID'"/' "$STORAGE_FILE"
perl -i -pe 's/"telemetry\.macMachineId":\s*"[^"]*"/"telemetry.macMachineId": "'$NEW_MAC_MACHINE_ID'"/' "$STORAGE_FILE"
perl -i -pe 's/"telemetry\.devDeviceId":\s*"[^"]*"/"telemetry.devDeviceId": "'$NEW_DEV_DEVICE_ID'"/' "$STORAGE_FILE"

echo "ID Başarıyla değiştirildi:"
echo "machineId: $NEW_MACHINE_ID"
echo "macMachineId: $NEW_MAC_MACHINE_ID"
echo "devDeviceId: $NEW_DEV_DEVICE_ID"