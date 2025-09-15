#!/bin/bash
# Smaže databázi studenti.db a všechny systémové uživatele vytvořené z této databáze
# Nebo může smazat všechny uživatelské účty kromě důležitých systémových
# Spouštějte jako root!

DB_FILE="../data/studenti.db"

# Funkce pro zobrazení menu
show_menu() {
    echo "========================================="
    echo "   SPRÁVA UŽIVATELSKÝCH ÚČTŮ"
    echo "========================================="
    echo "1) Smazat pouze uživatele z databáze"
    echo "2) Smazat VŠECHNY uživatelské účty (kromě systémových)"
    echo "3) Ukončit bez změn"
    echo "========================================="
}

# Funkce pro smazání všech uživatelských účtů kromě systémových
delete_all_users() {
    echo "VAROVÁNÍ: Tato operace smaže VŠECHNY uživatelské účty s UID >= 1000!"
    echo "Systémové účty (root, daemon, mail, atd.) zůstanou zachovány."
    echo ""
    
    # Počet účtů před mazáním
    users_before=$(awk -F: '$3 >= 1000' /etc/passwd | wc -l)
    total_accounts_before=$(wc -l < /etc/passwd)
    
    echo "Statistiky před mazáním:"
    echo "- Celkem účtů v systému: $total_accounts_before"
    echo "- Uživatelských účtů (UID >= 1000): $users_before"
    echo ""
    
    # Seznam účtů, které budou smazány (ukázka prvních 10)
    echo "Ukázka účtů, které budou smazány (prvních 10):"
    awk -F: '$3 >= 1000 {print "- " $1 " (UID: " $3 ")"}' /etc/passwd | head -10
    if [ $users_before -gt 10 ]; then
        echo "... a dalších $((users_before - 10)) účtů"
    fi
    echo ""
    
    read -p "Jste si jisti, že chcete pokračovat? (ano/ne): " confirm
    if [[ $confirm != "ano" ]]; then
        echo "Operace zrušena."
        return
    fi
    
    echo "Mazání všech uživatelských účtů... (může trvat několik sekund)"
    deleted_count=0
    failed_count=0
    
    # Vytvoření seznamu uživatelů pro rychlejší zpracování
    userlist=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)
    total_to_delete=$(echo "$userlist" | wc -l)
    current=0
    
    # Progress indikátor
    echo -n "Průběh: "
    
    # Rychlejší for loop místo while read
    for username in $userlist; do
        ((current++))
        
        # Rychlejší mazání bez zbytečných kontrol
        if userdel -r "$username" 2>/dev/null; then
            ((deleted_count++))
        else
            ((failed_count++))
        fi
        
        # Progress bar každých 100 uživatelů nebo na konci
        if (( current % 100 == 0 )) || (( current == total_to_delete )); then
            progress=$((current * 100 / total_to_delete))
            echo -n "${progress}% "
        fi
    done
    echo ""
    
    # Statistiky po mazání
    users_after=$(awk -F: '$3 >= 1000' /etc/passwd | wc -l)
    total_accounts_after=$(wc -l < /etc/passwd)
    actual_deleted=$((users_before - users_after))
    
    echo ""
    echo "========================================="
    echo "           STATISTIKY MAZÁNÍ"
    echo "========================================="
    echo "Účty před mazáním:"
    echo "- Celkem účtů: $total_accounts_before"
    echo "- Uživatelských účtů: $users_before"
    echo ""
    echo "Účty po mazání:"
    echo "- Celkem účtů: $total_accounts_after"
    echo "- Uživatelských účtů: $users_after"
    echo ""
    echo "Výsledek:"
    echo "- Skutečně smazáno: $deleted_count účtů"
    echo "- Chyby při mazání: $failed_count účtů"
    echo "- Zachováno systémových účtů: $((total_accounts_after - users_after))"
    echo "========================================="
    echo "Hromadné mazání dokončeno."
}

# Funkce pro odstranění diakritiky (stejná jako v create_users_from_db.sh)
remove_diacritics() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]'
}

# Funkce pro smazání uživatelů z databáze
delete_users_from_database() {
    if [ -f "$DB_FILE" ]; then
        if ! command -v sqlite3 &>/dev/null; then
            echo "Chybí sqlite3! Nelze načíst uživatele z databáze."
            return
        fi
        
        # Počet uživatelů v databázi
        db_users_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM students;")
        existing_users_count=0
        
        echo "Databáze obsahuje: $db_users_count studentů"
        echo ""
        
        # Rychlejší kontrola existujících uživatelů
        echo "Kontrolujem existující uživatele..."
        temp_userlist=""
        existing_users_count=0
        
        # Vytvoření rychlejšího seznamu bez opakovaných volání
        while IFS="," read -r jmeno prijmeni; do
            [ -z "$jmeno" ] && continue
            [ -z "$prijmeni" ] && continue
            login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
            login=$(remove_diacritics "$login")
            temp_userlist="$temp_userlist$login:$jmeno:$prijmeni\n"
        done < <(sqlite3 -csv "$DB_FILE" "SELECT jmeno, prijmeni FROM students;")
        
        echo "Uživatelé z databáze, kteří existují v systému:"
        echo "$temp_userlist" | while IFS=":" read -r login jmeno prijmeni; do
            [ -z "$login" ] && continue
            if id "$login" &>/dev/null 2>&1; then
                echo "- $login ($jmeno $prijmeni)"
                ((existing_users_count++))
            fi
        done
        
        # Statistiky před mazáním
        users_before=$(awk -F: '$3 >= 1000' /etc/passwd | wc -l)
        total_accounts_before=$(wc -l < /etc/passwd)
        
        echo ""
        echo "Statistiky před mazáním:"
        echo "- Studenti v databázi: $db_users_count"
        echo "- Existující uživatelé z databáze: bude spočítáno..."
        echo "- Celkem uživatelských účtů v systému: $users_before"
        echo "- Celkem všech účtů: $total_accounts_before"
        echo ""
        
        read -p "Pokračovat s mazáním uživatelů z databáze? (ano/ne): " confirm_db
        if [[ $confirm_db != "ano" ]]; then
            echo "Mazání z databáze zrušeno."
            return
        fi
        
        echo "Mazání uživatelů z databáze... (může trvat několik sekund)"
        deleted_count=0
        failed_count=0
        not_found_count=0
        current_db=0
        
        # Progress indikátor pro databázi
        echo -n "Průběh: "
        
        # Použití temp_userlist pro rychlejší zpracování
        echo -e "$temp_userlist" | while IFS=":" read -r login jmeno prijmeni; do
            [ -z "$login" ] && continue
            ((current_db++))
            
            if userdel -r "$login" 2>/dev/null; then
                ((deleted_count++))
            else
                if id "$login" &>/dev/null 2>&1; then
                    ((failed_count++))
                else
                    ((not_found_count++))
                fi
            fi
            
            # Progress každých 50 uživatelů
            if (( current_db % 50 == 0 )) || (( current_db == db_users_count )); then
                progress=$((current_db * 100 / db_users_count))
                echo -n "${progress}% "
            fi
        done
        echo ""
        
        # Statistiky po mazání
        users_after=$(awk -F: '$3 >= 1000' /etc/passwd | wc -l)
        total_accounts_after=$(wc -l < /etc/passwd)
        actually_deleted=$((users_before - users_after))
        
        echo ""
        echo "========================================="
        echo "      STATISTIKY MAZÁNÍ Z DATABÁZE"
        echo "========================================="
        echo "Databáze:"
        echo "- Celkem studentů v DB: $db_users_count"
        echo ""
        echo "Mazání:"
        echo "- Úspěšně smazáno: $deleted_count účtů"
        echo "- Chyby při mazání: $failed_count účtů"
        echo "- Neexistovalo v systému: $not_found_count účtů"
        echo ""
        echo "Systém po mazání:"
        echo "- Celkem účtů: $total_accounts_after (bylo: $total_accounts_before)"
        echo "- Uživatelských účtů: $users_after (bylo: $users_before)"
        echo "- Systémových účtů: $((total_accounts_after - users_after))"
        echo "========================================="
        
        read -p "Smazat také databázi $DB_FILE? (ano/ne): " confirm_db_delete
        if [[ $confirm_db_delete == "ano" ]]; then
            echo "Mazání databáze $DB_FILE..."
            rm "$DB_FILE"
            echo "Databáze $DB_FILE byla smazána."
        else
            echo "Databáze byla zachována."
        fi
    else
        echo "Databáze $DB_FILE neexistuje."
    fi
}

# Hlavní program
show_menu

while true; do
    read -p "Vyberte možnost (1-3): " choice
    case $choice in
        1)
            echo ""
            echo "=== MAZÁNÍ UŽIVATELŮ Z DATABÁZE ==="
            delete_users_from_database
            break
            ;;
        2)
            echo ""
            echo "=== MAZÁNÍ VŠECH UŽIVATELSKÝCH ÚČTŮ ==="
            delete_all_users
            break
            ;;
        3)
            echo "Ukončeno bez změn."
            exit 0
            ;;
        *)
            echo "Neplatná volba! Vyberte 1, 2 nebo 3."
            ;;
    esac
done

echo "Mazání dokončeno."
