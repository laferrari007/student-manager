#!/bin/bash
# Smaže databázi studenti.db a všechny systémové uživatele vytvořené z této databáze
# Spouštějte jako root!

DB_FILE="../data/studenti.db"

echo "Mazání uživatelů z databáze a samotné databáze..."

# Funkce pro odstranění diakritiky (stejná jako v create_users_from_db.sh)
remove_diacritics() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]'
}

# Nejprve smazat uživatele, pokud databáze existuje
if [ -f "$DB_FILE" ]; then
  if ! command -v sqlite3 &>/dev/null; then
    echo "Chybí sqlite3! Nelze načíst uživatele z databáze."
  else
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
  fi
  echo "Mazání databáze $DB_FILE..."
  rm "$DB_FILE"
  echo "Databáze $DB_FILE byla smazána."
else
  echo "Databáze $DB_FILE neexistuje."
fi

echo "Mazání dokončeno."
