# 📚 Práce s databází studentů v SQLite

Tento projekt ukazuje, jak spravovat databázi studentů pomocí SQLite v Linuxu.

## ✨ Funkčnost programu

- 🧑‍🎓 Studenti jsou generováni skriptem `scripts/generate_students.py`.
- 🔢 Skript se při spuštění zeptá na počet studentů k vygenerování (výchozí je 500).
- 💾 Všechna data jsou ukládána do databáze `data/studenti.db` (tabulka `students`).
- ➕ Skript lze spustit opakovaně – noví studenti se přidávají do existující databáze.
- 🗑️ Pro kompletní smazání všech studentů a databáze použijte skript `scripts/delete_students.sh`.
- ❌ Skript `delete_students.sh` smaže databázi `studenti.db` a případně i uživatelské účty podle students.txt (pokud existuje).
- ⚠️ Systémové účty studentů se již automaticky nevytvářejí (skript create_students.sh byl odstraněn).

## 🗂️ Struktura projektu

- `scripts/` – 🛠️ skripty pro generování a správu dat (např. generate_students.py, delete_students.sh)
- `data/` – 💾 databáze a exportovaná data (např. studenti.db)
- `docs/` – 📄 dokumentace

## 🏗️ Instalace SQLite

Na Ubuntu/Debian:
```bash
sudo apt update
sudo apt install sqlite3
```

## Vytvoření databáze a tabulky

Databáze je generována skriptem `scripts/generate_students.py` a uložena v `data/studenti.db`.

Ruční vytvoření tabulky (rozšířená struktura):
```bash
sqlite3 data/studenti.db "CREATE TABLE students (id INTEGER PRIMARY KEY, jmeno TEXT, prijmeni TEXT, email TEXT, adresa TEXT, telefon TEXT, kontakt_osoba TEXT, pojistovna TEXT, datum_narozeni TEXT, rodne_cislo TEXT, poznamka TEXT);"
```

## Výpis záznamů

Zobrazení všech studentů:
```bash
sqlite3 data/studenti.db "SELECT * FROM students;"
```

## Práce s databází v Pythonu

Ukázkový Python skript pro výpis studentů:
```python
import sqlite3

conn = sqlite3.connect('data/studenti.db')
c = conn.cursor()
c.execute('SELECT * FROM students')
for row in c.fetchall():
    print(row)
conn.close()
```

## Základní příkazy v sqlite3

Spusťte sqlite3 databázi:
```bash
sqlite3 data/studenti.db
```

V interaktivním režimu můžete používat tyto příkazy:
- `.tables` — vypíše všechny tabulky v databázi
- `.schema` — zobrazí SQL definici tabulek
- `.headers on` — zapne zobrazení hlaviček sloupců
- `.mode column` — zobrazí výstup v přehledných sloupcích
- `SELECT * FROM students;` — vypíše všechny záznamy z tabulky students
- `.exit` nebo `.quit` — ukončí sqlite3

Příklad práce v interaktivním režimu:
```sql
.headers on
.mode column
SELECT * FROM students;
.exit
```

## Další možnosti
- Můžete generovat náhodné studenty pomocí Pythonu a vkládat je do databáze.
- Lze exportovat data do students.txt pro použití v dalších skriptech.
- Databázi lze snadno rozšířit o další sloupce (např. telefon, datum narození, atd.).

Pokud potřebujete konkrétní skript nebo rozšíření, dejte vědět!
