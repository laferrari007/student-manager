#!/bin/bash
# Testovací verze - smaže jen první 3 studenty pro test
# Spouštějte jako root!

DB_FILE="../data/studenti.db"

echo "Testování mazání uživatelů (jen první 3 studenti)..."

# Funkce pro odstranění diakritiky (stejná jako v create_users_from_db.sh)
remove_diacritics() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]'
}

if [ -f "$DB_FILE" ]; then
  if ! command -v sqlite3 &>/dev/null; then
    echo "Chybí sqlite3! Nelze načíst uživatele z databáze."
  else
    echo "Mazání testovacích systémových uživatelů podle databáze (jen první 3)..."
    sqlite3 -csv "$DB_FILE" "SELECT jmeno, prijmeni FROM students LIMIT 3;" | while IFS="," read -r jmeno prijmeni; do
      [ -z "$jmeno" ] && continue
      [ -z "$prijmeni" ] && continue
      login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
      login=$(remove_diacritics "$login")
      if id "$login" &>/dev/null; then
        homedir=$(getent passwd "$login" | cut -d: -f6)
        shell=$(getent passwd "$login" | cut -d: -f7)
        echo "Našel uživatele $login (pro $jmeno $prijmeni). Domovský adresář: $homedir, shell: $shell"
        echo "Mažu uživatele $login..."
        userdel -r "$login"
        if id "$login" &>/dev/null; then
          echo "CHYBA: účet $login nebyl smazán!"
        else
          echo "✓ Smazán účet: $login"
        fi
      else
        echo "Uživatel $login neexistuje."
      fi
    done
  fi
else
  echo "Databáze $DB_FILE neexistuje."
fi

echo "Test mazání dokončen."