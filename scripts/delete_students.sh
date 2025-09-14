#!/bin/bash

INPUT_FILE="../data/students.txt"
DB_FILE="../data/studenti.db"

echo "Mazání uživatelů podle $INPUT_FILE a databáze $DB_FILE..."

# Funkce pro odstranění diakritiky (stejná jako v create_students.sh)
remove_diacritics() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]'
}

if [ ! -f "$INPUT_FILE" ]; then
  echo "Soubor $INPUT_FILE neexistuje!"
else
  while read -r line; do
    [ -z "$line" ] && continue
    first=$(echo "$line" | awk '{print $1}')
    last=$(echo "$line" | cut -d' ' -f2-)
    username="$(echo "${first:0:1}$last" | tr '[:upper:]' '[:lower:]')"
    username=$(remove_diacritics "$username")
    if [ -z "$username" ]; then
      echo "Přeskakuji prázdný login pro řádek: $line"
      continue
    fi
    if id "$username" &>/dev/null; then
      homedir=$(getent passwd "$username" | cut -d: -f6)
      shell=$(getent passwd "$username" | cut -d: -f7)
      echo "Uživatel $username existuje. Domovský adresář: $homedir, shell: $shell"
      userdel -r "$username"
      if id "$username" &>/dev/null; then
        echo "Chyba: účet $username nebyl smazán!"
      else
        echo "Smazán účet: $username"
      fi
    else
      echo "Uživatel $username neexistuje."
    fi
  done < "$INPUT_FILE"
fi

if [ -f "$DB_FILE" ]; then
  rm "$DB_FILE"
  echo "Databáze $DB_FILE byla smazána."
else
  echo "Databáze $DB_FILE neexistuje."
fi

echo "Mazání dokončeno."
