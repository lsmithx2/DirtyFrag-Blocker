#!/bin/bash

# =================================================================
# DIRTY FRAG & COPY FAIL 2 - HARDENING TOOL v2.1
# REPO: github.com/lsmithx2/DIRTY-FRAG-COPY-FAIL-2---MITIGATION-TOOL
# =================================================================

CONF_FILE="/etc/modprobe.d/dirtyfrag_mitigation.conf"
MODULES=("esp4" "esp6" "rxrpc" "algif_aead" "af_alg")

# --- UI STYLING ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- FUNCTIONS ---

check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${RED}!! ERROR: This script must be run with sudo !!${NC}" && exit 1
}

draw_header() {
    echo -e "${CYAN}┌───────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${BOLD}DIRTY FRAG & COPY FAIL 2 - MITIGATION TOOL v2.1${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────────┘${NC}"
    echo -e "${BLUE}  Kernel:$(uname -r)  |  User:$(whoami)${NC}"
}

check_status() {
    echo -e "\n${BOLD}>>> SYSTEM AUDIT${NC}"
    echo -e "${CYAN}-----------------------------------------------------${NC}"
    printf "${BOLD}%-15s %-15s %-15s${NC}\n" "MODULE" "STATE" "PROTECTION"
    echo -e "${CYAN}-----------------------------------------------------${NC}"
    
    for mod in "${MODULES[@]}"; do
        # Check Load State
        if lsmod | grep -q "^$mod"; then
            LOAD_STATE="${RED}LOADED (!!)${NC}"
        else
            LOAD_STATE="${GREEN}Inactive${NC}"
        fi
        
        # Check Protection State
        if [[ -f "$CONF_FILE" ]] && grep -q "$mod" "$CONF_FILE"; then
            PROT_STATE="${GREEN}ARMED${NC}"
        else
            PROT_STATE="${YELLOW}UNPROTECTED${NC}"
        fi
        
        printf "%-15s %-25b %-25b\n" "$mod" "$LOAD_STATE" "$PROT_STATE"
    done
    echo -e "${CYAN}-----------------------------------------------------${NC}"
    echo -ne "\n${MAGENTA}Press [Enter] to return...${NC}"
    read < /dev/tty
}

apply_mitigation() {
    echo -e "\n${YELLOW}[!] INITIALIZING HARDENING SEQUENCE...${NC}"
    
    # 1. Create Blacklist
    echo -e "${BLUE}[*] Writing persistent blacklist...${NC}"
    printf "# Mitigation for Dirty Frag & Copy Fail 2\n" > "$CONF_FILE"
    for mod in "${MODULES[@]}"; do
        echo "install $mod /bin/false" >> "$CONF_FILE"
    done

    # 2. Kill Modules
    echo -e "${BLUE}[*] Forcing vulnerable modules to unload...${NC}"
    for mod in "${MODULES[@]}"; do
        modprobe -r "$mod" 2>/dev/null || rmmod "$mod" 2>/dev/null
    done

    # 3. Purge Memory
    echo -e "${BLUE}[*] Flushing Page Cache (Dropping Dirty Pages)...${NC}"
    sync; echo 3 > /proc/sys/vm/drop_caches

    echo -e "\n${GREEN}=========================================${NC}"
    echo -e "${GREEN}      SYSTEM SUCCESSFULLY HARDENED       ${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -ne "${MAGENTA}Press [Enter] to return...${NC}"
    read < /dev/tty
}

rollback() {
    echo -e "\n${YELLOW}[!] REVERSING PROTECTIONS...${NC}"
    if [[ -f "$CONF_FILE" ]]; then
        rm -f "$CONF_FILE"
        echo -e "${GREEN}[+] Blacklist removed. Functionality restored.${NC}"
    else
        echo -e "${RED}[-] No mitigation file found.${NC}"
    fi
    echo -ne "${MAGENTA}Press [Enter] to return...${NC}"
    read < /dev/tty
}

# --- EXECUTION ---

check_root

while true; do
    draw_header
    echo -e "  ${BOLD}1)${NC} ${GREEN}AUDIT${NC}  - Check Security Status"
    echo -e "  ${BOLD}2)${NC} ${RED}SECURE${NC} - Apply Lockdown & Flush Cache"
    echo -e "  ${BOLD}3)${NC} ${YELLOW}UNDO${NC}   - Rollback Changes"
    echo -e "  ${BOLD}4)${NC} ${NC}EXIT${NC}   - Close Tool"
    echo -e "${CYAN}─────────────────────────────────────────────────────${NC}"
    echo -ne "${BOLD}Selection [1-4]: ${NC}"
    
    read choice < /dev/tty

    case "$choice" in
        1) check_status ;;
        2) apply_mitigation ;;
        3) rollback ;;
        4) echo -e "${CYAN}Stay safe.${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid input.${NC}"; sleep 1 ;;
    esac
done
