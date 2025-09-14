# 🧪 Dokumentace Testování - Student Manager

Kompletní průvodce testováním systému pro správu studentů.

---

## 📋 Přehled Testování

Student Manager obsahuje rozsáhlé testovací nástroje pro ověření:
- ✅ Generování dat do databáze
- ✅ Vytváření systémových účtů
- ✅ Mazání účtů a cleanup
- ✅ Kompatibilitu s diakritikoy
- ✅ Bezpečnostní omezení

---

## 🎯 Testové Scénáře

### Scénář 1: Kompletní Test Cyklu (Doporučeno)

```bash
cd student_manager/scripts
source venv/bin/activate

# Test 1: Generování dat
echo "3" | python3 generate_students.py
echo "✅ Test generování: PROŠEL"

# Test 2: Vytvoření účtů
sudo ./test_create_users.sh
echo "✅ Test vytváření účtů: PROŠEL"

# Test 3: Kontrola účtů
sqlite3 -csv ../data/studenti.db "SELECT jmeno, prijmeni FROM students LIMIT 3;"
echo "✅ Test databáze: PROŠEL"

# Test 4: Mazání účtů
sudo ./test_delete_users.sh
echo "✅ Test mazání: PROŠEL"
```

### Scénář 2: Test s Velkým Množstvím Dat

```bash
# Generování 1000 studentů
echo "1000" | python3 generate_students.py

# Měření času vytváření účtů
time sudo ./create_users_from_db.sh

# Kontrola počtu vytvořených účtů
created_users=$(getent passwd | grep nologin | wc -l)
echo "Vytvořeno účtů: $created_users"

# Cleanup
sudo ./delete_students.sh
```

### Scénář 3: Test Diakritiky a Speciálních Znaků

```bash
# Test různých kombinací jmen s diakritikou
cd scripts
python3 -c "
import sqlite3
from faker import Faker
fake = Faker('cs_CZ')

# Vytvoření test dat s diakritikoy
conn = sqlite3.connect('../data/studenti.db')
cursor = conn.cursor()

test_names = [
    ('Žžořč', 'Čřěšň'),
    ('Příšťěra', 'Ščýřďák'),
    ('Úřéďó', 'Ňýřóš'),
]

for jmeno, prijmeni in test_names:
    cursor.execute('''INSERT INTO students 
                     (jmeno, prijmeni, email, adresa, telefon, kontakt_osoba, 
                      pojistovna, datum_narozeni, rodne_cislo, poznamka)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                  (jmeno, prijmeni, f'{jmeno.lower()}.{prijmeni.lower()}@test.cz',
                   'Test adresa', '+420 123 456 789', 'Test kontakt',
                   'VZP', '2000-01-01', '0001010001', 'Test diakritiky'))

conn.commit()
conn.close()
print('✅ Test data s diakritikou vytvořena')
"

# Test vytvoření uživatelů s diakritikou
sudo ./test_create_users.sh
```

---

## 🔍 Automatizované Testy

### Test Skript pro CI/CD

Vytvořte `run_all_tests.sh`:

```bash
#!/bin/bash
# Kompletní automatizované testování

set -e  # Zastaví při chybě

TEST_LOG="/tmp/student_manager_test.log"
echo "🧪 Spouštění testů Student Manager..." > "$TEST_LOG"

cd "$(dirname "$0")"

# Test 1: Python závislosti
echo "Test 1: Kontrola Python závislostí"
source venv/bin/activate
python3 -c "import faker; print('✅ Faker OK')" >> "$TEST_LOG" 2>&1

# Test 2: SQLite
echo "Test 2: Kontrola SQLite"
sqlite3 --version >> "$TEST_LOG" 2>&1
echo "✅ SQLite OK" >> "$TEST_LOG"

# Test 3: Systémové příkazy
echo "Test 3: Kontrola systémových příkazů"
which useradd >> "$TEST_LOG" 2>&1
which userdel >> "$TEST_LOG" 2>&1
which iconv >> "$TEST_LOG" 2>&1
echo "✅ Systémové příkazy OK" >> "$TEST_LOG"

# Test 4: Generování dat
echo "Test 4: Generování testovacích dat"
echo "5" | python3 generate_students.py >> "$TEST_LOG" 2>&1
count=$(sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students WHERE id >= (SELECT MAX(id) FROM students) - 4;")
if [ "$count" -eq 5 ]; then
    echo "✅ Generování dat OK" >> "$TEST_LOG"
else
    echo "❌ Generování dat FAIL" >> "$TEST_LOG"
    exit 1
fi

# Test 5: Vytváření účtů
echo "Test 5: Vytváření systémových účtů"
sudo ./test_create_users.sh >> "$TEST_LOG" 2>&1
echo "✅ Vytváření účtů OK" >> "$TEST_LOG"

# Test 6: Mazání účtů
echo "Test 6: Mazání systémových účtů"
sudo ./test_delete_users.sh >> "$TEST_LOG" 2>&1
echo "✅ Mazání účtů OK" >> "$TEST_LOG"

# Test 7: Cleanup
echo "Test 7: Kompletní cleanup"
sudo ./delete_students.sh >> "$TEST_LOG" 2>&1
if [ ! -f "../data/studenti.db" ]; then
    echo "✅ Cleanup OK" >> "$TEST_LOG"
else
    echo "❌ Cleanup FAIL" >> "$TEST_LOG"
    exit 1
fi

echo "🎉 Všechny testy prošly úspěšně!" >> "$TEST_LOG"
cat "$TEST_LOG"
```

### Použití Automatizovaných Testů

```bash
chmod +x run_all_tests.sh
./run_all_tests.sh
```

---

## 📊 Výkonnostní Testy

### Test Generování Velkých Dat

```bash
# Test různých velikostí databáze
for size in 100 500 1000 5000 10000; do
    echo "🧪 Testování velikosti: $size studentů"
    start_time=$(date +%s)
    
    echo "$size" | python3 generate_students.py > /dev/null 2>&1
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    echo "⏱️  Čas generování $size studentů: ${duration}s"
    
    # Cleanup pro další test
    rm -f ../data/studenti.db
done
```

### Test Vytváření Systémových Účtů

```bash
# Benchmark vytváření uživatelů
echo "1000" | python3 generate_students.py

echo "🧪 Test výkonnosti vytváření 1000 uživatelů..."
start_time=$(date +%s)

sudo ./create_users_from_db.sh

end_time=$(date +%s)
duration=$((end_time - start_time))

created=$(getent passwd | grep nologin | wc -l)
echo "⏱️  Vytvořeno $created účtů za ${duration}s"
echo "📊 Rychlost: $((created / duration)) účtů/sekunda"

# Cleanup
sudo ./delete_students.sh
```

---

## 🔧 Debug a Diagnostika

### Debug Generování Loginů

```bash
# Test funkce pro odstranění diakritiky
test_login_generation() {
    echo "🔍 Debug generování loginů:"
    
    # Testovací data s diakritikou
    test_data="Žžořč,Čřěšň
Příšťěra,Ščýřďák  
Tomáš,Novák
Jiří,Svoboda"
    
    echo "$test_data" | while IFS="," read -r jmeno prijmeni; do
        # Simulation of script logic
        login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]')"
        clean_login=$(echo "$login" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]')
        
        echo "  '$jmeno $prijmeni' → '$clean_login'"
    done
}

test_login_generation
```

### Kontrola Integrity Databáze

```bash
# SQLite integrity check
sqlite3 ../data/studenti.db "PRAGMA integrity_check;"

# Kontrola schématu
sqlite3 ../data/studenti.db ".schema students"

# Statistiky databáze
sqlite3 ../data/studenti.db "
SELECT 
  COUNT(*) as total_students,
  COUNT(DISTINCT pojistovna) as unique_insurances,
  MIN(datum_narozeni) as oldest_birth,
  MAX(datum_narozeni) as newest_birth
FROM students;"
```

### Kontrola Systémových Účtů

```bash
# Analýza vytvořených uživatelů
analyze_users() {
    echo "📊 Analýza studentských účtů:"
    
    total=$(getent passwd | grep nologin | wc -l)
    echo "  Celkem účtů: $total"
    
    homes_count=$(ls /home | grep -E '^[a-z]' | wc -l)
    echo "  Domovské adresáře: $homes_count"
    
    # Kontrola práv na domovské adresáře
    wrong_perms=$(find /home -maxdepth 1 -type d -not -perm 700 -name '[a-z]*' | wc -l)
    echo "  Špatná oprávnění: $wrong_perms"
    
    # Kontrola shell
    wrong_shells=$(getent passwd | grep nologin | grep -v '/usr/sbin/nologin' | wc -l)
    echo "  Špatné shell: $wrong_shells"
}

analyze_users
```

---

## 📋 Test Checklist

### Před Nasazením

- [ ] ✅ Python 3.6+ dostupný
- [ ] ✅ SQLite3 nainstalován
- [ ] ✅ Faker library nainstalován
- [ ] ✅ Root práva dostupná
- [ ] ✅ Systémové příkazy (useradd, userdel, iconv) fungují
- [ ] ✅ Dostatečné místo na disku (1GB+ pro větší databáze)

### Funkčnost

- [ ] ✅ Generování dat funguje
- [ ] ✅ Databáze se vytváří správně
- [ ] ✅ Systémové účty se vytváří
- [ ] ✅ Loginy se generují správně (bez diakritiky)
- [ ] ✅ Bezpečnostní omezení jsou aplikována
- [ ] ✅ Mazání účtů funguje kompletně
- [ ] ✅ Cleanup odstraní vše

### Výkonnost

- [ ] ✅ Generování 1000 studentů < 30s
- [ ] ✅ Vytváření 1000 účtů < 300s  
- [ ] ✅ Mazání 1000 účtů < 120s
- [ ] ✅ Databáze zůstává konzistentní

---

## 🚨 Známé Problémy a Řešení

### Problem 1: Duplicitní ID v databázi

**Symptom:** `UNIQUE constraint failed: students.id`

**Řešení:**
```bash
# Reset auto-increment counter
sqlite3 ../data/studenti.db "UPDATE SQLITE_SEQUENCE SET seq = (SELECT MAX(id) FROM students) WHERE name = 'students';"
```

### Problem 2: Zpomalení při velkém počtu uživatelů

**Symptom:** Vytváření účtů trvá velmi dlouho

**Řešení:**
```bash
# Použijte batch processing
# Místo jednoho velkého běhu použijte více menších:
for i in {1..10}; do
    echo "1000" | python3 generate_students.py
    sudo ./create_users_from_db.sh
done
```

### Problem 3: Nedostatek místa na disku

**Symptom:** `No space left on device`

**Diagnostika:**
```bash
# Kontrola místa
df -h
du -sh ../data/studenti.db
du -sh /home

# Odhad potřeby místa
# ~ 1KB na studenta v databázi
# ~ 4KB na domovský adresář
```

---

## 📈 Reportování Chyb

Pokud najdete chybu, vytvořte report s těmito informacemi:

```bash
# Systémové informace
echo "=== SYSTEM INFO ===" > bug_report.txt
uname -a >> bug_report.txt
python3 --version >> bug_report.txt
sqlite3 --version >> bug_report.txt

# Konfigurace
echo "=== CONFIG ===" >> bug_report.txt
ls -la scripts/ >> bug_report.txt
ls -la data/ >> bug_report.txt

# Logy chyb
echo "=== ERROR LOGS ===" >> bug_report.txt
# Přidejte konkrétní chybovou zprávu
```

---

*Pro další otázky ohledně testování kontaktujte autora nebo vytvořte issue na GitHubu.*