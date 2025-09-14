# 🎓 Student Manager - Kompletní Systém pro Správu Studentů

[![GitHub Badge](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/your-username/student_manager_main)
[![Docker Badge](https://img.shields.io/badge/Docker-Compatible-blue?logo=docker)](https://www.docker.com/)
[![Tested Badge](https://img.shields.io/badge/Tested-✅-green)](docs/TESTING.md)
[![SQLite Badge](https://img.shields.io/badge/SQLite-Database-orange)](https://sqlite.org/)

Kompletní systém pro správu studentů s databází SQLite, generování testovacích dat a správu systémových účtů Linux. Navrženo pro Ubuntu Docker kontejnery.

---

## 📋 Přehled

Student Manager je robustní systém poskytující:

- **📊 SQLite databázi** s rozšířeným schématem studentských dat
- **🎲 Generování realistických dat** pomocí knihovny Faker (podpora 100k+ studentů)
- **🇨🇿 České lokalizované údaje** (jména, adresy, telefony, pojišťovny, rodná čísla)
- **👥 Automatickou správu Linux systémových účtů** na základě databáze
- **🔒 Bezpečnostní omezení** pro studentské účty (nologin shell, omezená práva)
- **🧪 Testovací nástroje** pro ověření funkčnosti
- **🗑️ Kompletní cleanup** uživatelů a databáze

---

## 🚀 Rychlé Spuštění

```bash
# 1. Příprava virtuálního prostředí
cd student_manager/scripts
python3 -m venv venv
source venv/bin/activate
pip install faker

# 2. Generování testovacích dat (např. 100 studentů)
echo "100" | python3 generate_students.py

# 3. Vytvoření systémových účtů z databáze
sudo ./create_users_from_db.sh

# 4. Kontrola vytvořených účtů
getent passwd | grep nologin | tail -5

# 5. Smazání všech uživatelů a databáze
sudo ./delete_students.sh
```

---

## 🏗️ Struktura Projektu

```
student_manager/
├── scripts/                      # Spustitelné skripty
│   ├── generate_students.py      # Generování dat do SQLite
│   ├── create_users_from_db.sh   # Vytváření Linux účtů z DB
│   ├── delete_students.sh        # Mazání účtů a databáze
│   ├── test_create_users.sh      # Test vytváření (jen 3 účty)
│   └── test_delete_users.sh      # Test mazání (jen 3 účty)
├── data/                         # Databázové soubory
│   └── studenti.db              # SQLite databáze (vytvořena automaticky)
└── docs/                        # Dokumentace
    ├── README.md               # Tento soubor
    ├── DATABASE_SCHEMA.md      # Schéma databáze
    ├── TESTING.md             # Dokumentace testování
    └── EXAMPLES.md            # Praktické příklady použití
```

---

## 📊 Databázové Schéma

### Tabulka `students`

| Sloupec | Typ | Popis | Příklad |
|---------|-----|--------|---------|
| `id` | INTEGER PRIMARY KEY | Unikátní ID studenta | 104001 |
| `jmeno` | TEXT | Křestní jméno | "Tomáš" |
| `prijmeni` | TEXT | Příjmení | "Novák" |
| `email` | TEXT | E-mailová adresa | "tomas.novak@email.cz" |
| `adresa` | TEXT | Bydliště | "Václavské nám. 1, Praha" |
| `telefon` | TEXT | Telefon/mobil | "+420 608 123 456" |
| `kontakt_osoba` | TEXT | Kontaktní osoba | "Marie Nováková" |
| `pojistovna` | TEXT | Zdravotní pojišťovna | "VZP", "OZP", "ČPZP" |
| `datum_narozeni` | TEXT | Datum narození | "2001-05-15" |
| `rodne_cislo` | TEXT | Rodné číslo | "0105151234" |
| `poznamka` | TEXT | Poznámky | "Speciální poznámka" |

---

## 🛠️ Skripty a Použití

### 1. 🎲 `generate_students.py` - Generování Dat

**Účel:** Generuje realistická studentská data do SQLite databáze.

```bash
# Interaktivní režim
python3 generate_students.py

# Neinteraktivní režim (např. 500 studentů)
echo "500" | python3 generate_students.py

# Generování velkého množství dat (10 000 studentů)
echo "10000" | python3 generate_students.py
```

**Funkce:**
- ✅ České lokalizované údaje (jména, města, telefonní čísla)
- ✅ Realistické zdravotní pojišťovny (VZP, OZP, ČPZP, VoZP, ZPMV, RBP)
- ✅ Správné formáty rodných čísel podle českých pravidel
- ✅ Přidávání do existující databáze (nepřepisuje)
- ✅ Výpis generovaných záznamů pro kontrolu

### 2. 👥 `create_users_from_db.sh` - Vytváření Systémových Účtů

**Účel:** Vytváří Linux systémové účty na základě databáze studentů.

```bash
# Vytvoření všech účtů z databáze
sudo ./create_users_from_db.sh

# Kontrola vytvořených účtů
getent passwd | grep nologin | tail -10
```

**Generování loginů:**
- Vzor: `[první_písmeno_jména][příjmení]`
- Příklad: "Tomáš Novák" → login: `tnovak`
- Automatické odstranění diakritiky: "Jiří Čech" → `jcech`

**Bezpečnostní nastavení:**
- ✅ Shell: `/usr/sbin/nologin` (nelze se přihlásit)
- ✅ Domovský adresář: `/home/[login]` s právy 700
- ✅ Kontrola duplicit (přeskakuje existující uživatele)

### 3. 🗑️ `delete_students.sh` - Kompletní Cleanup

**Účel:** Maže všechny studentské systémové účty a databázi.

```bash
# POZOR: Smaže všechny uživatele a databázi!
sudo ./delete_students.sh
```

**Proces mazání:**
1. ✅ Načte všechny studenty z databáze
2. ✅ Vygeneruje stejné loginy jako create skript
3. ✅ Smaže systémové účty včetně domovských adresářů
4. ✅ Smaže databázový soubor `studenti.db`

### 4. 🧪 Testovací Skripty

#### `test_create_users.sh` - Test Vytváření (3 účty)
```bash
sudo ./test_create_users.sh
```

#### `test_delete_users.sh` - Test Mazání (3 účty)
```bash
sudo ./test_delete_users.sh
```

---

## 🔧 Instalace a Požadavky

### Systémové Požadavky

- **Operační systém:** Ubuntu 20.04+ (testováno na Ubuntu 24.04.3 LTS)
- **Python:** 3.6+ s pip
- **Databáze:** SQLite3 (`apt install sqlite3`)
- **Shell:** Bash
- **Práva:** Root přístup pro správu uživatelů

### Instalace Závislostí

```bash
# Aktualizace systému
sudo apt update && sudo apt upgrade -y

# Instalace SQLite3
sudo apt install sqlite3 -y

# Python virtual environment
cd student_manager/scripts
python3 -m venv venv
source venv/bin/activate

# Python knihovny
pip install faker
```

### Ověření Instalace

```bash
# Kontrola verzí
python3 --version
sqlite3 --version
which useradd
which userdel

# Test Faker knihovny
python3 -c "from faker import Faker; f = Faker('cs_CZ'); print(f.name())"
```

---

## 🧪 Testování Systému

### Kompletní Test Cyklu

```bash
# 1. Generování 3 testovacích studentů
cd scripts
source venv/bin/activate
echo "3" | python3 generate_students.py

# 2. Vytvoření systémových účtů
sudo ./test_create_users.sh

# 3. Kontrola vytvořených účtů
sqlite3 -csv ../data/studenti.db "SELECT jmeno, prijmeni FROM students LIMIT 3;"
id msmid  # Příklad: Matěj Šmíd → login 'msmid'

# 4. Test mazání
sudo ./test_delete_users.sh

# 5. Ověření smazání
id msmid  # Mělo by hlásit "no such user"
```

### Kontrola Databáze

```bash
# Počet studentů
sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students;"

# Posledních 5 záznamů
sqlite3 -csv ../data/studenti.db "SELECT jmeno, prijmeni, email FROM students ORDER BY id DESC LIMIT 5;"

# Statistiky pojišťoven
sqlite3 ../data/studenti.db "SELECT pojistovna, COUNT(*) FROM students GROUP BY pojistovna;"
```

---

## ⚠️ Bezpečnostní Upozornění

### 🚨 Kritická Varování

- **`delete_students.sh`** smaže **VŠECHNY** studentské uživatele a databázi bez možnosti obnovení
- **Root práva** jsou potřebná pro správu systémových účtů
- **Záloha** databáze před velkými operacemi je doporučena

### 🔒 Bezpečnostní Funkce

- Studentské účty mají shell `/usr/sbin/nologin` - **nelze se přihlásit**
- Domovské adresáře mají práva **700** (pouze vlastník)
- Kontrola duplicit při vytváření uživatelů
- Validace dat před operacemi s databází

---

## 📝 Praktické Příklady

### Scénář 1: První Nasazení

```bash
# Vytvoření 1000 studentů pro školní systém
cd scripts
source venv/bin/activate
echo "1000" | python3 generate_students.py

# Vytvoření všech systémových účtů
sudo ./create_users_from_db.sh

# Kontrola úspěšnosti
getent passwd | grep nologin | wc -l  # Počet vytvořených účtů
```

### Scénář 2: Přidání Nových Studentů

```bash
# Přidání dalších 500 studentů (nepřepisuje stávající)
echo "500" | python3 generate_students.py

# Vytvoření pouze nových účtů (přeskakuje existující)
sudo ./create_users_from_db.sh
```

### Scénář 3: Kompletní Reset

```bash
# Smazání všech dat a účtů
sudo ./delete_students.sh

# Nové nasazení
echo "2000" | python3 generate_students.py
sudo ./create_users_from_db.sh
```

---

## 🐛 Řešení Problémů

### Časté Problémy

**Problem:** `command not found: sqlite3`
```bash
sudo apt update && sudo apt install sqlite3 -y
```

**Problem:** `ImportError: No module named 'faker'`
```bash
pip install faker
# nebo
python3 -m pip install faker
```

**Problem:** `useradd: permission denied`
```bash
# Spusťte skripty s sudo
sudo ./create_users_from_db.sh
```

**Problem:** Chyby s diakritikou v loginech
```bash
# Ověřte nainstalování iconv
which iconv
# Mělo by existovat ve většině Linux distribucí
```

### Debug Režim

```bash
# Zapnutí debug výstupu v bash skriptech
bash -x ./create_users_from_db.sh

# Test generování loginů
echo "Tomáš,Novák" | while IFS="," read jmeno prijmeni; do
  login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
  login=$(echo "$login" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]')
  echo "Login: $login"
done
```

---

## 🤝 Přispívání

Chcete přispět k vývoji? Skvělé!

1. **Fork** tohoto repozitáře
2. **Vytvořte feature branch** (`git checkout -b feature/nova-funkcionalita`)
3. **Commitněte změny** (`git commit -am 'Přidání nové funkcionality'`)
4. **Push branch** (`git push origin feature/nova-funkcionalita`)
5. **Vytvořte Pull Request**

---

## 📄 Licence

Tento projekt je šířen pod MIT licencí. Více informací v souboru `LICENSE`.

---

## 👤 Autor

**Váš Název**
- GitHub: [@your-username](https://github.com/your-username)
- Email: your-email@example.com

---

## 🙏 Poděkování

- **Faker Library** za generování realistických dat
- **SQLite** za spolehlivou databázi
- **Ubuntu/Docker** za vývojové prostředí
- **České komunity** za lokalizační podklady

---

*Vytvořeno s ❤️ pro správu studentských dat*