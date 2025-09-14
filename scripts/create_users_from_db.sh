#!/bin/bash
# Vytvoří systémové účty pro studenty z databáze studenti.db (omezená práva)
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

# Funkce pro odstranění diakritiky
remove_diacritics() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]'
}

# Získání studentů z databáze
sqlite3 -csv "$DB_FILE" "SELECT jmeno, prijmeni FROM students;" | while IFS="," read -r jmeno prijmeni; do
  [ -z "$jmeno" ] && continue
  [ -z "$prijmeni" ] && continue
  login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
  login=$(remove_diacritics "$login")
  if id "$login" &>/dev/null; then
    echo "Uživatel $login již existuje."
  else
    useradd -m -s /usr/sbin/nologin "$login"
    chmod 700 "/home/$login"
    echo "$login:$login" | chpasswd
    echo "Vytvořen omezený účet: $login (heslo: $login, shell: /usr/sbin/nologin)"
  fi
done
