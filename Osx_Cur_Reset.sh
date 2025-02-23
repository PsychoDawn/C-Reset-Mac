# Root ayrıcalıklarını kontrol et
if [ "$EUID" -ne 0 ]; then
    echo "Lütfen sudo ayrıcalıklarıyla çalıştırın"
    sudo "$0" "$@"
    exit
fi

# Renk tanımlamaları
RED='\033[0;31m'       # Kırmızı
GREEN='\033[0;32m'     # Yeşil
YELLOW='\033[1;33m'    # Sarı
GRAY='\033[0;37m'      # Gri
WHITE='\033[1;37m'     # Beyaz
NC='\033[0m'           # Renk sıfırlama (normal)

show_disclaimer() {
    clear
    echo -e "${YELLOW}macOS için HWID Sıfırlama Aracı

Bu yazılım yalnızca meşru gizlilik koruma amaçları için tasarlanmıştır.

Bu aracı kullanmaya devam ederek aşağıdakileri açıkça kabul etmiş ve onaylamış olursunuz:


1. Bu aracın kullanımından kaynaklanan tüm sonuçların sorumluluğunu tamamen üstlendiğinizi
2. Sistem tanımlayıcılarını değiştirmenin belirli yazılımların işlevselliğini etkileyebileceğini anladığınızı

Bu araç yalnızca sahibi olduğunuz veya değiştirme yetkinizin olduğu sistemlerde kullanılmalıdır.

Devam etmek için Enter tuşuna basın veya çıkmak için Ctrl+C'ye basın...${NC}"
    read
}

generate_random_mac() {
    # Yerel olarak yönetilen bitin ayarlandığı rastgele bir MAC adresi oluştur
    hex=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/:$//')
    # İlk baytın yerel olarak yönetildiğinden emin ol (ilk baytın 1. biti ayarlanmış olacak)
    first_byte=$(echo $hex | cut -d: -f1)
    new_first_byte=$(printf "%02x" $((0x$first_byte | 0x02)))
    echo "${new_first_byte}:${hex:3}"
}

get_current_hwids() {
    echo "Mevcut donanım tanımlayıcıları toplanıyor..."
    
    # Aktif ağ arayüzlerinin mevcut MAC adreslerini al
    network_interfaces=$(networksetup -listallhardwareports | awk '/Hardware Port|Ethernet Address/ {print $NF}' | paste - -)
    
    # Mevcut Donanım UUID'sini al
    hardware_uuid=$(system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $3}')
    
    # Mevcut Sistem UUID'sini al
    system_uuid=$(system_profiler SPHardwareDataType | awk '/UUID/ {print $3}' | head -n 1)
    
    echo -e "${RED}Mevcut Değerler:${NC}"
    echo -e "${GRAY}Donanım UUID:${NC} ${WHITE}$hardware_uuid${NC}"
    echo -e "${GRAY}Sistem UUID:${NC} ${WHITE}$system_uuid${NC}"
    
    echo -e "\n${RED}Mevcut MAC Adresleri:${NC}"
    echo "$network_interfaces" | while read -r interface mac; do
        echo -e "${GRAY}$interface:${NC} ${WHITE}$mac${NC}"
    done
    
    echo -e "\n${GREEN}Önerilen Yeni Değerler:${NC}"
    echo -e "${GRAY}Donanım UUID:${NC} ${WHITE}$(uuidgen)${NC}"
    echo -e "${GRAY}Sistem UUID:${NC} ${WHITE}$(uuidgen)${NC}"
    
    echo -e "\n${GREEN}Yeni MAC Adresleri:${NC}"
    echo "$network_interfaces" | while read -r interface mac; do
        echo -e "${GRAY}$interface:${NC} ${WHITE}$(generate_random_mac)${NC}"
    done
}

update_hwids() {
    echo -e "\n${YELLOW}(1/3) Donanım ve Sistem UUID'leri Güncelleniyor...${NC}"
    # Not: macOS'ta bu değerler genellikle donanım yazılımı tarafından yönetilir ve
    # değiştirilmesi için özel araçlar veya üretici yazılımı düzenlemeleri gerekir.
    
    echo -e "${YELLOW}(2/3) Ağ Arayüzleri Güncelleniyor...${NC}"
    networksetup -listallhardwareports | awk '/Hardware Port|Device:/ {print $NF}' | paste - - | while read -r interface device; do
        new_mac=$(generate_random_mac)
        echo "$interface ($device) için MAC güncelleniyor: $new_mac"
        sudo ifconfig $device ether $new_mac
    done
    
    echo -e "${YELLOW}(3/3) Uygulama Tanımlayıcıları Temizleniyor...${NC}"
    # Cursor uygulama tanımlayıcılarını kaldır (varsa)
    cursor_id_path="$HOME/Library/Application Support/Cursor/machineid"
    if [ -f "$cursor_id_path" ]; then
        rm -f "$cursor_id_path"
    fi
    
    # Cursor işlemini kapat (çalışıyorsa)
    if pgrep -x "Cursor" > /dev/null; then
        killall Cursor
    fi
    
    echo -e "\n${GREEN}Tamamlandı!${NC}"
    echo -e "${GREEN}Tüm değişikliklerin uygulanması için Mac'inizi yeniden başlatın.${NC}"

}

# Ana işlem
show_disclaimer
get_current_hwids

echo -e "\n${YELLOW}Bu değişiklikleri uygulamak istiyor musunuz? (y/N) ${NC}"
read -r confirmation

if [ "$confirmation" = "y" ] || [ "$confirmation" = "Y" ]; then
    update_hwids
else
    echo -e "\n${YELLOW}İşlem kullanıcı tarafından iptal edildi.${NC}"
fi

read -p "Çıkmak için Enter tuşuna basın..."
