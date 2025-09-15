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
    
    # Seznam účtů, které budou smazány
    echo "Účty, které budou smazány:"
    awk -F: '$3 >= 1000 {print "- " $1 " (UID: " $3 ")"}' /etc/passwd
    echo ""
    
    read -p "Jste si jisti, že chcete pokračovat? (ano/ne): " confirm
    if [[ $confirm != "ano" ]]; then
        echo "Operace zrušena."
        return
    fi
    
    echo "Mazání všech uživatelských účtů..."
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read username; do
        if id "$username" &>/dev/null; then
            homedir=$(getent passwd "$username" | cut -d: -f6)
            echo "Mazání uživatele: $username (domovský adresář: $homedir)"
            userdel -r "$username" 2>/dev/null
            if id "$username" &>/dev/null; then
                echo "Chyba: účet $username nebyl smazán!"
            else
                echo "Smazán účet: $username"
            fi
        fi
    done
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
        
        echo "Uživatelé v databázi, kteří budou smazáni:"
        sqlite3 -csv "$DB_FILE" "SELECT jmeno, prijmeni FROM students;" | while IFS="," read -r jmeno prijmeni; do
            [ -z "$jmeno" ] && continue
            [ -z "$prijmeni" ] && continue
            login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
            login=$(remove_diacritics "$login")
            if id "$login" &>/dev/null; then
                echo "- $login ($jmeno $prijmeni)"
            fi
        done
        echo ""
        
        read -p "Pokračovat s mazáním uživatelů z databáze? (ano/ne): " confirm_db
        if [[ $confirm_db != "ano" ]]; then
            echo "Mazání z databáze zrušeno."
            return
        fi
        
        echo "Mazání systémových uživatelů podle databáze..."
        sqlite3 -csv "$DB_FILE" "SELECT jmeno, prijmeni FROM students;" | while IFS="," read -r jmeno prijmeni; do
            [ -z "$jmeno" ] && continue
            [ -z "$prijmeni" ] && continue
            login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
            login=$(remove_diacritics "$login")
            if id "$login" &>/dev/null; then
                homedir=$(getent passwd "$login" | cut -d: -f6)
                shell=$(getent passwd "$login" | cut -d: -f7)
                echo "Uživatel $login existuje. Domovský adresář: $homedir, shell: $shell"
                userdel -r "$login"
                if id "$login" &>/dev/null; then
                    echo "Chyba: účet $login nebyl smazán!"
                else
                    echo "Smazán účet: $login"
                fi
            else
                echo "Uživatel $login neexistuje."
            fi
        done
        
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
