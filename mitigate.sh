#!/bin/bash

# =================================================================
# TITLE: Dirty Frag & Copy Fail 2 Mitigation Tool
# REPO: github.com/lsmithx2/DIRTY-FRAG-COPY-FAIL-2---MITIGATION-TOOL
# =================================================================

CONF_FILE="/etc/modprobe.d/dirtyfrag_mitigation.conf"
MODULES=("esp4" "esp6" "rxrpc" "algif_aead" "af_alg")
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

while true; do
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BLUE}    DIRTY FRAG & COPY FAIL 2 - MITIGATION TOOL       ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo "1) Check status"
    echo "2) Apply mitigation"
    echo "3) Rollback"
    echo "4) Exit"
    echo -e "${BLUE}=====================================================${NC}"
    
    # Using /dev/tty ensures it reads from your keyboard even if piped
    read -p "Selection [1-4]: " choice < /dev/tty

    case "$choice" in
        1)
            echo -e "\n[*] Checking module status..."
            for mod in "${MODULES[@]}"; do
                if lsmod | grep -q "^$mod"; then
                    echo "  [!] LOADED: $mod"
                else
                    echo "  [✓] Clean:  $mod"
                fi
            done
            ;;
        2)
            echo -e "\n[*] Applying mitigations..."
            printf "install %s /bin/false\n" "${MODULES[@]}" > "$CONF_FILE"
            for mod in "${MODULES[@]}"; do
                modprobe -r "$mod" 2>/dev/null || rmmod "$mod" 2>/dev/null
            done
            sync; echo 3 > /proc/sys/vm/drop_caches
            echo "[+] Done. Cache flushed and modules blacklisted."
            ;;
        3)
            echo -e "\n[*] Rolling back..."
            [ -f "$CONF_FILE" ] && rm "$CONF_FILE" && echo "[+] Blacklist removed."
            ;;
        4)
            echo "Exiting."
            exit 0
            ;;
        "") 
            # This catches empty enters to prevent the spam you saw
            continue 
            ;;
        *)
            echo -e "\nInvalid selection: '$choice'"
            ;;
    esac
done
