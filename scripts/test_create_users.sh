#!/bin/bash
# Testovací verze - vytvoří jen 3 účty pro test
# Spouštějte jako root!

DB_FILE="../data/studenti.db"

if ! command -v sqlite3 &>/dev/null; then
  echo "Chybí sqlite3! Nainstalujte: apt install sqlite3"
  exit 1
fi

if [ ! -f "$DB_FILE" ]; then
  echo "Databáze $DB_FILE neexistuje!"
  exit 1
fi

echo "Vytváření testovacích účtů (jen první 3 studenti)..."

# Funkce pro odstranění diakritiky
remove_diacritics() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]'
}

# Vytvoření jen prvních 3 uživatelů
sqlite3 -csv "$DB_FILE" "SELECT jmeno, prijmeni FROM students LIMIT 3;" | while IFS="," read -r jmeno prijmeni; do
  [ -z "$jmeno" ] && continue
  [ -z "$prijmeni" ] && continue
  
  login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
  login=$(remove_diacritics "$login")
  
  if [ -z "$login" ]; then
    echo "Přeskakuji prázdný login pro: $jmeno $prijmeni"
    continue
  fi
  
  if id "$login" &>/dev/null; then
    echo "Uživatel $login už existuje!"
  else
    useradd -m -s /usr/sbin/nologin "$login"
    chmod 700 "/home/$login"
    echo "Vytvořen účet: $login (pro $jmeno $prijmeni)"
    echo "  Domovský adresář: /home/$login"
    echo "  Shell: /usr/sbin/nologin"
  fi
done

echo "Test dokončen."