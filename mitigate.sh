#!/bin/bash

# =================================================================
# TITLE: Dirty Frag & Copy Fail 2 Mitigation Tool
# REPO: github.com/lsmithx2/DIRTY-FRAG-COPY-FAIL-2---MITIGATION-TOOL
# DESCRIPTION: Prevents LPE exploits by blacklisting vulnerable 
#              kernel modules and flushing the page cache.
# =================================================================

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

log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

header() {
    clear
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${BLUE}    DIRTY FRAG & COPY FAIL 2 - MITIGATION TOOL       ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo -e " Kernel: $(uname -r)"
    echo -e " Log:    $LOG_FILE"
    echo -e "${BLUE}=====================================================${NC}"
}

check_status() {
    echo -e "\n${YELLOW}[*] Current Module Status:${NC}"
    local found=0
    for mod in "${MODULES[@]}"; do
        if lsmod | grep -q "^$mod"; then
            echo -e "  [${RED}!${NC}] LOADED: $mod"
            found=1
        else
            echo -e "  [${GREEN}✓${NC}] Clean:  $mod"
        fi
    done
    if [ $found -eq 1 ]; then
        echo -e "\n${RED}STATUS:${NC} System is currently in a vulnerable state."
    else
        echo -e "\n${GREEN}STATUS:${NC} Vulnerable modules are not active."
    fi
    read -p "Press enter to return to menu..."
}

apply_mitigation() {
    echo -e "\n${YELLOW}[*] Applying Mitigations...${NC}"
    
    # 1. Blacklist
    echo "    - Writing blacklist to $CONF_FILE"
    printf "install %s /bin/false\n" "${MODULES[@]}" > "$CONF_FILE"
    log_message "Applied blacklist to $CONF_FILE"

    # 2. Unload
    for mod in "${MODULES[@]}"; do
        if lsmod | grep -q "^$mod"; then
            echo -ne "    - Unloading $mod... "
            modprobe -r "$mod" 2>/dev/null || rmmod "$mod" 2>/dev/null
            if [ $? -eq 0 ]; then 
                echo -e "${GREEN}DONE${NC}"
                log_message "Unloaded module: $mod"
            else 
                echo -e "${RED}FAILED (In Use)${NC}"
                log_message "Failed to unload module: $mod"
            fi
        fi
    done

    # 3. Cache Flush
    echo -e "    - Flushing Page Cache... "
    sync; echo 3 > /proc/sys/vm/drop_caches
    log_message "Page cache flushed."
    
    echo -e "\n${GREEN}[✓] Mitigation sequence complete.${NC}"
    read -p "Press enter to return to menu..."
}

remove_mitigation() {
    echo -e "\n${YELLOW}[*] Rolling Back Mitigations...${NC}"
    if [ -f "$CONF_FILE" ]; then
        rm "$CONF_FILE"
        echo -e "    ${GREEN}[+] Removed blacklist configuration.${NC}"
        log_message "Mitigation rolled back (config deleted)."
    else
        echo -e "    [-] No mitigation file found."
    fi
    read -p "Press enter to return to menu..."
}

# Main Loop
while true; do
    header
    echo "1) Check status"
    echo "2) Apply mitigation (Secure System)"
    echo "3) Rollback mitigation (Restore functions)"
    echo "4) Exit"
    echo -e "${BLUE}=====================================================${NC}"
    read -p "Selection: " choice

    case $choice in
        1) check_status ;;
        2) apply_mitigation ;;
        3) remove_mitigation ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid selection.${NC}"; sleep 1 ;;
    esac
done
