#!/bin/bash

# =================================================================
# DIRTY FRAG & COPY FAIL 2 - HARDENING TOOL v2.0
# REPO: github.com/lsmithx2/DIRTY-FRAG-COPY-FAIL-2---MITIGATION-TOOL
# =================================================================

CONF_FILE="/etc/modprobe.d/dirtyfrag_mitigation.conf"
MODULES=("esp4" "esp6" "rxrpc" "algif_aead" "af_alg")

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- HELPER FUNCTIONS ---

check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${RED}Error: Must run as root.${NC}" && exit 1
}

check_status() {
    echo -e "\n${CYAN}Current Security Posture:${NC}"
    echo -e "MODULE\t\tLOADED\t\tBLACKLISTED"
    echo -e "-------------------------------------------"
    for mod in "${MODULES[@]}"; do
        # Check if loaded
        LOAD_STR="${GREEN}No${NC}"
        lsmod | grep -q "^$mod" && LOAD_STR="${RED}YES${NC}"
        
        # Check if blacklisted in our file
        BLOCK_STR="${RED}No${NC}"
        [[ -f "$CONF_FILE" ]] && grep -q "$mod" "$CONF_FILE" && BLOCK_STR="${GREEN}YES${NC}"
        
        printf "%-15s\t%-15b\t%-15b\n" "$mod" "$LOAD_STR" "$BLOCK_STR"
    done
}

apply_mitigation() {
    echo -e "\n${YELLOW}[*] Locking down kernel modules...${NC}"
    printf "# Mitigation for Dirty Frag & Copy Fail 2\n" > "$CONF_FILE"
    for mod in "${MODULES[@]}"; do
        echo "install $mod /bin/false" >> "$CONF_FILE"
        # Force unload
        modprobe -r "$mod" 2>/dev/null || rmmod "$mod" 2>/dev/null
    done
    
    echo -e "${YELLOW}[*] Flushing page cache to purge 'dirty' memory...${NC}"
    sync; echo 3 > /proc/sys/vm/drop_caches
    
    echo -e "${GREEN}[✓] System Hardened.${NC}"
}

rollback() {
    if [[ -f "$CONF_FILE" ]]; then
        rm -f "$CONF_FILE"
        echo -e "${GREEN}[+] Blacklist removed. Functionality restored.${NC}"
    else
        echo -e "${YELLOW}[-] No mitigation file found to remove.${NC}"
    fi
}

# --- LOGIC ---

check_root

# Handle CLI Flags
if [[ "$1" == "--apply" ]]; then
    apply_mitigation
    exit 0
elif [[ "$1" == "--rollback" ]]; then
    rollback
    exit 0
fi

# Main Interactive Loop
while true; do
    echo -e "\n${CYAN}=========================================${NC}"
    echo -e "${CYAN}    DIRTY FRAG MITIGATION INTERFACE      ${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo " 1) Check Status (Audit)"
    echo " 2) Apply Mitigation (Secure)"
    echo " 3) Rollback (Restore)"
    echo " 4) Exit"
    echo -ne "${CYAN}Selection: ${NC}"
    
    # Secure read from terminal
    read choice < /dev/tty

    case "$choice" in
        1) check_status ;;
        2) apply_mitigation ;;
        3) rollback ;;
        4) echo "Exiting."; exit 0 ;;
        *) echo -e "${RED}Invalid selection.${NC}"; sleep 1 ;;
    esac
done
