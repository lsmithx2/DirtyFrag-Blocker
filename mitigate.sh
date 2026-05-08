#!/bin/bash

# Configuration
CONF_FILE="/etc/modprobe.d/dirtyfrag_mitigation.conf"
LOG_FILE="/var/log/boogaloo_mitigation.log"
MODULES=("esp4" "esp6" "rxrpc" "algif_aead" "af_alg")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

# Root check
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (sudo).${NC}"
   exit 1
fi

touch "$LOG_FILE" 2>/dev/null

# Clear ONCE at the very beginning
clear
echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}    DIRTY FRAG & COPY FAIL 2 - MITIGATION TOOL       ${NC}"
echo -e "${BLUE}=====================================================${NC}"

while true; do
    echo -e "\n${BLUE}--- MAIN MENU ---${NC}"
    echo "1) Check status"
    echo "2) Apply mitigation"
    echo "3) Rollback"
    echo "4) Exit"
    echo -ne "${BLUE}=====================================================${NC}\n"
    
    # Use -r to handle backslashes and read input
    read -p "Selection [1-4]: " raw_choice
    
    # Sanitize input: remove any hidden carriage returns or spaces
    choice=$(echo "$raw_choice" | tr -d '\r' | xargs)

    case "$choice" in
        1)
            echo -e "\n${YELLOW}[*] Checking modules...${NC}"
            for mod in "${MODULES[@]}"; do
                if lsmod | grep -q "^$mod"; then
                    echo -e "  [${RED}!${NC}] LOADED: $mod"
                else
                    echo -e "  [${GREEN}✓${NC}] Clean:  $mod"
                fi
            done
            ;;
        2)
            echo -e "\n${YELLOW}[*] Applying Blacklist & Flushing Cache...${NC}"
            printf "install %s /bin/false\n" "${MODULES[@]}" > "$CONF_FILE"
            for mod in "${MODULES[@]}"; do
                modprobe -r "$mod" 2>/dev/null || rmmod "$mod" 2>/dev/null
            done
            sync; echo 3 > /proc/sys/vm/drop_caches
            echo -e "${GREEN}[✓] Mitigation applied.${NC}"
            ;;
        3)
            [ -f "$CONF_FILE" ] && rm "$CONF_FILE" && echo -e "${GREEN}[+] Rollback complete.${NC}" || echo "[-] No config found."
            ;;
        4)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection: '$choice'. Please type 1, 2, 3, or 4.${NC}"
            ;;
    esac
done
