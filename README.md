# 🎓 Student Manager - Systém pro Správu Studentů

[![GitHub Badge](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/your-username/student_manager_main)
[![Docker Badge](https://img.shields.io/badge/Docker-Compatible-blue?logo=docker)](https://www.docker.com/)
[![Python Badge](https://img.shields.io/badge/Python-3.6+-green)](https://python.org)
[![SQLite Badge](https://img.shields.io/badge/SQLite-Database-orange)](https://sqlite.org/)

Kompletní systém pro správu studentů s databází SQLite, generování testovacích dat a automatickou správu Linux systémových účtů.

---

## 🚀 Rychlý Start

```bash
git clone https://github.com/your-username/student_manager_main.git
cd student_manager_main/student_manager/scripts

# Příprava prostředí
python3 -m venv venv
source venv/bin/activate
pip install faker

# Generování 100 studentů
echo "100" | python3 generate_students.py

# Vytvoření systémových účtů
sudo ./create_users_from_db.sh

# Kontrola úspěšnosti
getent passwd | grep nologin | wc -l
```

## 📋 Hlavní Funkce

- **📊 SQLite databáze** s kompletním schématem studentských dat
- **🎲 Generování realistických dat** - české jména, adresy, pojišťovny
- **👥 Automatická správa Linux účtů** - bezpečné omezené účty
- **🔒 Bezpečnostní funkce** - nologin shell, správná oprávnění
- **🧪 Testovací nástroje** - ověření funkčnosti před nasazením
- **🗑️ Kompletní cleanup** - bezpečné odstranění všech dat

## 📁 Struktura Projektu

```
student_manager/
├── scripts/                    # 🔧 Spustitelné skripty
│   ├── generate_students.py    #   📝 Generování dat
│   ├── create_users_from_db.sh #   👤 Vytváření účtů
│   ├── delete_students.sh      #   🗑️  Mazání všeho
│   └── test_*.sh              #   🧪 Testovací skripty
├── data/                      # 💾 Databázové soubory
│   └── studenti.db           #   📊 SQLite databáze
└── docs/                     # 📚 Dokumentace
    ├── README.md            #   📖 Hlavní dokumentace
    ├── TESTING.md           #   🧪 Testovací procedury
    ├── DATABASE_SCHEMA.md   #   📊 Schéma databáze
    └── EXAMPLES.md          #   📝 Praktické příklady
```

## 📚 Dokumentace

| Dokument | Popis |
|----------|--------|
| [📖 **Kompletní Dokumentace**](docs/README.md) | Úplný návod k použití |
| [🧪 **Testování**](docs/TESTING.md) | Testovací procedury a scénáře |
| [📊 **Databázové Schéma**](docs/DATABASE_SCHEMA.md) | Struktura databáze a dotazy |
| [📝 **Praktické Příklady**](docs/EXAMPLES.md) | Reálné scénáře použití |

## ⚡ Rychlé Příkazy

### Základní Operace
```bash
# Generování studentů
echo "500" | python3 generate_students.py

# Vytvoření účtů
sudo ./create_users_from_db.sh

# Kompletní smazání
sudo ./delete_students.sh
```

### Testování
```bash
# Test s 3 studenty
sudo ./test_create_users.sh
sudo ./test_delete_users.sh

# Kontrola stavu
sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students;"
getent passwd | grep nologin | wc -l
```

### Statistiky
```bash
# Databáze
sqlite3 ../data/studenti.db "SELECT pojistorna, COUNT(*) FROM students GROUP BY pojistorna;"

# Systém
ls -la /home/ | wc -l
du -sh ../data/studenti.db
```

## 🛠️ Požadavky

- **OS:** Ubuntu 20.04+ (testováno na 24.04.3 LTS)
- **Python:** 3.6+ s pip
- **SQLite:** 3.x (`apt install sqlite3`)
- **Privileges:** Root přístup pro správu uživatelů
- **Deps:** Faker library (`pip install faker`)

## 🧪 Test Systému

```bash
# Kompletní test cyklus
cd scripts
source venv/bin/activate

# 1. Generování
echo "3" | python3 generate_students.py

# 2. Vytváření účtů
sudo ./test_create_users.sh

# 3. Kontrola
sqlite3 ../data/studenti.db "SELECT jmeno, prijmeni FROM students LIMIT 3;"

# 4. Cleanup test
sudo ./test_delete_users.sh

# ✅ Všechny kroky by měly proběhnout bez chyb
```

## 📊 Příklad Dat

```sql
-- Vygenerovaný student
INSERT INTO students VALUES (
    104001,
    'Tomáš',                    -- Jméno
    'Novák',                    -- Příjmení  
    'tomas.novak@seznam.cz',    -- Email
    'Hlavní 12, 602 00 Brno',  -- Adresa
    '+420 608 123 456',         -- Telefon
    'Marie Nováková',           -- Kontakt
    'VZP',                      -- Pojišťovna
    '2001-03-15',              -- Datum narození
    '0103151234',              -- Rodné číslo
    'Student informatiky'       -- Poznámka
);

-- Vytvořený systémový účet: tnovak
-- Login: t + novak = tnovak
-- Home: /home/tnovak (práva 700)
-- Shell: /usr/sbin/nologin
```

## 🔒 Bezpečnost

### Bezpečnostní Funkce
- ✅ **Omezené účty:** `/usr/sbin/nologin` shell
- ✅ **Správná oprávnění:** Domovské adresáře 700
- ✅ **Validace:** Kontrola duplicit a chyb
- ✅ **Cleanup:** Kompletní odstranění dat

### ⚠️ Varování
- `delete_students.sh` **SMAŽE VŠECHNA DATA** bez možnosti obnovení
- Root práva jsou **POVINNÁ** pro správu uživatelů  
- Před nasazením **VŽDY TESTUJTE** na menším vzorku

## 🐛 Troubleshooting

| Problém | Řešení |
|---------|--------|
| `command not found: sqlite3` | `sudo apt install sqlite3` |
| `ImportError: No module named 'faker'` | `pip install faker` |
| `useradd: permission denied` | Spusťte s `sudo` |
| `database is locked` | Zavřete všechna připojení k DB |

## 📈 Výkonnost

### Benchmarky (testováno na Ubuntu 24.04)
- **Generování:** ~1000 studentů/minuta
- **Vytváření účtů:** ~200 účtů/minuta  
- **Databáze:** ~1KB na studenta
- **Testováno:** Až 100,000+ studentů

### Optimalizace
- Pro 10,000+ studentů používejte batch processing
- Pravidelné `VACUUM` databáze
- Monitoring místa na disku

## 🤝 Přispívání

1. **Fork** repozitáře
2. **Vytvořte feature branch** (`git checkout -b feature/nova-funkcnost`)
3. **Commitněte změny** (`git commit -am 'Přidání funkce'`)
4. **Push branch** (`git push origin feature/nova-funkcnost`)
5. **Vytvořte Pull Request**

## 📄 Licence

Tento projekt je licencován pod MIT licencí - viz [LICENSE](LICENSE) soubor.

## 👤 Autor

- **GitHub:** [@your-username](https://github.com/your-username)
- **Email:** your-email@example.com

---

## 🎯 Praktické Použití

### Pro Školy
- Správa studentských účtů pro laboratoře
- Hromadné vytváření účtů pro nový školní rok
- Testování před nasazením do produkce

### Pro IT Administrátory  
- Automatizace správy uživatelů
- Generování testovacích dat pro vývoj
- Backup a disaster recovery procedury

### Pro Vývojáře
- Příklad práce s SQLite v Pythonu
- Bash scripting pro správu systému
- Integration testing příklady

---

**📞 Potřebujete pomoc?** Vytvořte [Issue](https://github.com/your-username/student_manager_main/issues) nebo se podívejte do [dokumentace](docs/).

*Vytvořeno s ❤️ pro efektivní správu studentských dat.*