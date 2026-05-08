#!/bin/bash

# Configuration
CONF_FILE="/etc/modprobe.d/dirtyfrag_mitigation.conf"
MODULES=("esp4" "esp6" "rxrpc" "algif_aead" "af_alg")

# Check for root
[[ $EUID -ne 0 ]] && echo "Run as root!" && exit 1

# --- THE CLEAN LOOP ---
while true; do
    echo -e "\n--- MAIN MENU ---"
    echo "1) Check status"
    echo "2) Apply mitigation"
    echo "3) Rollback"
    echo "4) Exit"
    echo "-----------------"
    
    # Force read to wait for the keyboard (terminal)
    echo -n "Selection [1-4]: "
    read choice < /dev/tty

    case "$choice" in
        1)
            for mod in "${MODULES[@]}"; do
                lsmod | grep -q "^$mod" && echo "[!] LOADED: $mod" || echo "[✓] Clean: $mod"
            done
            ;;
        2)
            printf "install %s /bin/false\n" "${MODULES[@]}" > "$CONF_FILE"
            for mod in "${MODULES[@]}"; do modprobe -r "$mod" 2>/dev/null || rmmod "$mod" 2>/dev/null; done
            sync; echo 3 > /proc/sys/vm/drop_caches
            echo "Mitigation applied."
            ;;
        3)
            rm -f "$CONF_FILE" && echo "Rollback complete."
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid selection. Waiting 2 seconds..."
            sleep 2 # This stops the infinite scrolling "spam"
            ;;
    esac
done
