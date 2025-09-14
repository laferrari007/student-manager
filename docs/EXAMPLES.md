# 📚 Praktické Příklady - Student Manager

Kolekce praktických příkladů použití Student Manager systému.

---

## 🎯 Scénáře Použití

### Scénář 1: První Nasazení do Školy

**Situace:** Nová škola chce vytvořit 500 studentských účtů

```bash
# 1. Příprava prostředí
cd student_manager/scripts
python3 -m venv venv
source venv/bin/activate
pip install faker

# 2. Generování 500 studentů
echo "500" | python3 generate_students.py

# 3. Kontrola vygenerovaných dat
sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students;"
sqlite3 ../data/studenti.db "SELECT jmeno, prijmeni, email FROM students LIMIT 5;"

# 4. Vytvoření všech systémových účtů
sudo ./create_users_from_db.sh

# 5. Ověření úspěšnosti
created_accounts=$(getent passwd | grep nologin | wc -l)
echo "✅ Vytvořeno $created_accounts studentských účtů"

# 6. Kontrola práv na domovské adresáře
ls -la /home/ | head -10
```

**Očekávaný výstup:**
```
✅ Vytvořeno 500 studentských účtů
drwx------ 2 anovak     anovak     4096 Sep 14 12:00 anovak
drwx------ 2 jdvorak    jdvorak    4096 Sep 14 12:01 jdvorak
...
```

---

### Scénář 2: Rozšíření o Nové Studenty

**Situace:** Škola během roku přijímá dalších 100 studentů

```bash
# 1. Přidání nových studentů (nepřepisuje stávající)
echo "100" | python3 generate_students.py

# 2. Kontrola celkového počtu
total=$(sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students;")
echo "Celkem studentů v databázi: $total"

# 3. Vytvoření pouze nových účtů (přeskakuje existující)
sudo ./create_users_from_db.sh

# 4. Kontrola nově přidaných
echo "Posledních 10 vytvořených účtů:"
getent passwd | grep nologin | tail -10
```

---

### Scénář 3: Testování Před Nasazením

**Situace:** IT administrátor chce otestovat funkčnost na malém vzorku

```bash
# 1. Testovací generování (jen 3 studenti)
echo "3" | python3 generate_students.py

# 2. Zobrazení testovacích dat
sqlite3 -header -column ../data/studenti.db "
SELECT jmeno, prijmeni, email, pojistorna 
FROM students 
ORDER BY id DESC 
LIMIT 3;"

# 3. Test vytvoření účtů
sudo ./test_create_users.sh

# 4. Manuální kontrola vytvořených uživatelů
for student in $(sqlite3 -csv ../data/studenti.db "SELECT jmeno, prijmeni FROM students ORDER BY id DESC LIMIT 3;"); do
    jmeno=$(echo $student | cut -d',' -f1 | tr -d '"')
    prijmeni=$(echo $student | cut -d',' -f2 | tr -d '"')
    login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]' | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]')"
    
    echo "Student: $jmeno $prijmeni"
    echo "Login: $login"
    echo "Status: $(id $login 2>/dev/null && echo 'EXISTS' || echo 'NOT FOUND')"
    echo "Home: $(ls -ld /home/$login 2>/dev/null || echo 'Directory not found')"
    echo "---"
done

# 5. Test kompletního smazání
sudo ./test_delete_users.sh

# 6. Ověření cleanup
echo "Kontrola smazání:"
for student in $(sqlite3 -csv ../data/studenti.db "SELECT jmeno, prijmeni FROM students ORDER BY id DESC LIMIT 3;" 2>/dev/null || echo ""); do
    if [ -n "$student" ]; then
        jmeno=$(echo $student | cut -d',' -f1 | tr -d '"')
        prijmeni=$(echo $student | cut -d',' -f2 | tr -d '"')
        login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]' | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]')"
        
        if id $login &>/dev/null; then
            echo "❌ $login stále existuje!"
        else
            echo "✅ $login byl smazán"
        fi
    fi
done
```

---

### Scénář 4: Migrace ze Starého Systému

**Situace:** Škola má existující seznam studentů v CSV a chce migrovat do nového systému

```bash
# 1. Příprava - předpokládáme existing_students.csv s formátem:
# Jméno,Příjmení,Email,Telefon,Adresa

# 2. Vytvoření migračního skriptu
cat > migrate_existing.py << 'EOF'
#!/usr/bin/env python3
import sqlite3
import csv
from faker import Faker

fake = Faker('cs_CZ')

# Připojení k databázi
conn = sqlite3.connect('../data/studenti.db')
cursor = conn.cursor()

# Vytvoření tabulky pokud neexistuje
cursor.execute('''CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    jmeno TEXT NOT NULL,
    prijmeni TEXT NOT NULL,
    email TEXT UNIQUE,
    adresa TEXT,
    telefon TEXT,
    kontakt_osoba TEXT,
    pojistorna TEXT,
    datum_narozeni TEXT,
    rodne_cislo TEXT,
    poznamka TEXT
)''')

# Čtení existujících dat
with open('existing_students.csv', 'r', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    for row in reader:
        # Doplnění chybějících údajů pomocí Faker
        cursor.execute('''INSERT OR IGNORE INTO students 
                         (jmeno, prijmeni, email, adresa, telefon, kontakt_osoba, 
                          pojistorna, datum_narozeni, rodne_cislo, poznamka)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                      (row['Jméno'], 
                       row['Příjmení'],
                       row['Email'],
                       row['Adresa'] or fake.address().replace('\n', ', '),
                       row['Telefon'] or fake.phone_number(),
                       fake.name(),  # kontaktní osoba
                       fake.random_element(['VZP', 'OZP', 'ČPZP', 'VoZP', 'ZPMV', 'RBP']),
                       fake.date_of_birth(minimum_age=18, maximum_age=25).strftime('%Y-%m-%d'),
                       fake.random_number(digits=10, fix_len=True),
                       'Migrováno ze starého systému'))

conn.commit()
print(f"✅ Migrace dokončena. Celkem studentů: {cursor.execute('SELECT COUNT(*) FROM students').fetchone()[0]}")
conn.close()
EOF

chmod +x migrate_existing.py

# 3. Spuštění migrace
python3 migrate_existing.py

# 4. Vytvoření účtů pro migrované studenty
sudo ./create_users_from_db.sh
```

---

### Scénář 5: Hromadné Operace s Účty

**Situace:** Potřeba změnit nastavení všech studentských účtů

```bash
# 1. Najít všechny studentské účty
student_accounts=$(getent passwd | grep nologin | cut -d: -f1)

# 2. Hromadná změna kvót (příklad)
for account in $student_accounts; do
    echo "Nastavuji kvóty pro $account..."
    # setquota -u $account 100000 110000 1000 1100 /home
done

# 3. Hromadné vytvoření společných adresářů
for account in $student_accounts; do
    sudo -u $account mkdir -p /home/$account/{Documents,Downloads,Projects}
    sudo -u $account chmod 755 /home/$account/{Documents,Downloads,Projects}
done

# 4. Kontrola výsledků
echo "Kontrola vytvořených adresářů:"
ls -la /home/*/Documents | head -5
```

---

### Scénář 6: Backup a Disaster Recovery

**Situace:** Pravidelné zálohování a obnovení systému

```bash
# === BACKUP STRATEGIE ===

# 1. Denní záloha databáze
backup_daily() {
    backup_date=$(date +%Y%m%d)
    backup_dir="/backup/student_manager"
    
    mkdir -p $backup_dir
    
    # Záloha databáze
    cp data/studenti.db "$backup_dir/studenti_$backup_date.db"
    
    # Export do CSV (pro redundanci)
    sqlite3 data/studenti.db <<EOF
.mode csv
.output $backup_dir/students_export_$backup_date.csv
SELECT * FROM students;
.quit
EOF
    
    # Záloha účtů (seznam uživatelů)
    getent passwd | grep nologin > "$backup_dir/student_accounts_$backup_date.txt"
    
    echo "✅ Záloha dokončena: $backup_dir"
}

# 2. Týdenní kompletní záloha
backup_weekly() {
    backup_date=$(date +%Y%m%d)
    backup_dir="/backup/student_manager"
    
    # Kompletní dump databáze
    sqlite3 data/studenti.db ".dump" > "$backup_dir/studenti_dump_$backup_date.sql"
    
    # Záloha domovských adresářů (pouze struktura)
    tar -czf "$backup_dir/home_structure_$backup_date.tar.gz" \
        --exclude="*.tmp" \
        --exclude="*.log" \
        /home/*/
        
    echo "✅ Týdenní záloha dokončena"
}

# === RECOVERY PROCEDURY ===

# 1. Obnovení databáze
restore_database() {
    restore_file=$1
    
    if [ -f "$restore_file" ]; then
        echo "Obnovuji databázi z $restore_file"
        cp "$restore_file" data/studenti.db
        
        # Kontrola integrity
        sqlite3 data/studenti.db "PRAGMA integrity_check;"
        echo "✅ Databáze obnovena"
    else
        echo "❌ Záložní soubor nenalezen: $restore_file"
    fi
}

# 2. Kompletní obnova systému
disaster_recovery() {
    echo "🚨 Spouštím disaster recovery..."
    
    # 1. Obnova databáze z posledního backup
    latest_backup=$(ls -t /backup/student_manager/studenti_*.db | head -1)
    restore_database "$latest_backup"
    
    # 2. Smazání všech existujících studentských účtů
    sudo ./delete_students.sh
    
    # 3. Recreate všech účtů z obnovené databáze
    sudo ./create_users_from_db.sh
    
    # 4. Kontrola
    db_count=$(sqlite3 data/studenti.db "SELECT COUNT(*) FROM students;")
    system_count=$(getent passwd | grep nologin | wc -l)
    
    echo "📊 Recovery statistiky:"
    echo "  Studenti v databázi: $db_count"
    echo "  Systémové účty: $system_count"
    
    if [ "$db_count" -eq "$system_count" ]; then
        echo "✅ Disaster recovery úspěšné!"
    else
        echo "⚠️  Nesoulad mezi databází a systémovými účty"
    fi
}

# Spuštění backup operací
backup_daily
backup_weekly
```

---

### Scénář 7: Monitoring a Reporting

**Situace:** Pravidelné sledování stavu systému

```bash
# 1. Vytvoření monitoring skriptu
cat > monitor_system.sh << 'EOF'
#!/bin/bash

echo "📊 STUDENT MANAGER - SYSTEM REPORT"
echo "=================================="
echo "Datum: $(date)"
echo

# Databázové statistiky
echo "📋 DATABÁZE:"
if [ -f "../data/studenti.db" ]; then
    db_count=$(sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students;")
    db_size=$(du -h ../data/studenti.db | cut -f1)
    echo "  Celkem studentů: $db_count"
    echo "  Velikost DB: $db_size"
    
    echo "  Pojišťovny:"
    sqlite3 ../data/studenti.db "SELECT pojistorna, COUNT(*) FROM students GROUP BY pojistorna;" | while IFS="|" read pojistorna count; do
        echo "    $pojistorna: $count"
    done
else
    echo "  ❌ Databáze neexistuje"
fi

echo

# Systémové účty
echo "👥 SYSTÉMOVÉ ÚČTY:"
system_count=$(getent passwd | grep nologin | wc -l)
echo "  Studentských účtů: $system_count"

# Kontrola domovských adresářů
home_count=$(ls -1 /home | wc -l)
echo "  Domovských adresářů: $home_count"

# Kontrola práv
wrong_perms=$(find /home -maxdepth 1 -type d -not -perm 700 2>/dev/null | wc -l)
if [ $wrong_perms -gt 1 ]; then  # -gt 1 kvůli /home samotné
    echo "  ⚠️  Špatná oprávnění: $((wrong_perms-1)) adresářů"
else
    echo "  ✅ Všechna oprávnění v pořádku"
fi

echo

# Místo na disku
echo "💾 MÍSTO NA DISKU:"
df -h / | tail -1 | while read filesystem size used available percent mountpoint; do
    echo "  Použito: $used z $size ($percent)"
done

echo "  /home:"
du -sh /home 2>/dev/null | cut -f1 | while read size; do
    echo "    Velikost: $size"
done

echo

# Poslední aktivity
echo "📝 POSLEDNÍ AKTIVITY:"
echo "  Databáze změněna: $(stat -c %y ../data/studenti.db 2>/dev/null || echo 'neexistuje')"

# Nejnovější domovské adresáře (posledních 5)
echo "  Nejnovější účty:"
ls -lt /home | head -6 | tail -5 | while read perms links owner group size date time name; do
    echo "    $name ($date $time)"
done

echo
echo "=================================="
EOF

chmod +x monitor_system.sh

# 2. Spuštění monitoring reportu
./monitor_system.sh

# 3. Nastavení pravidelného reportingu (crontab)
cat > setup_cron.sh << 'EOF'
#!/bin/bash

# Přidání do crontabu pro denní reporty o 8:00
(crontab -l 2>/dev/null; echo "0 8 * * * cd /path/to/student_manager/scripts && ./monitor_system.sh > /tmp/student_report_$(date +\%Y\%m\%d).log") | crontab -

echo "✅ Cron job nastavený pro denní reporty"
EOF

chmod +x setup_cron.sh
```

---

### Scénář 8: Integration s LDAP/Active Directory

**Situace:** Export studentských dat do LDAP systému

```bash
# 1. Export do LDIF formátu
cat > export_to_ldap.py << 'EOF'
#!/usr/bin/env python3
import sqlite3

def export_to_ldif():
    conn = sqlite3.connect('../data/studenti.db')
    cursor = conn.cursor()
    
    print("# Student Manager LDAP Export")
    print("# Generated:", cursor.execute("SELECT datetime('now')").fetchone()[0])
    print()
    
    cursor.execute("SELECT * FROM students ORDER BY id")
    
    for row in cursor.fetchall():
        id, jmeno, prijmeni, email, adresa, telefon, kontakt_osoba, pojistorna, datum_narozeni, rodne_cislo, poznamka = row
        
        # Generování loginu (stejná logika jako v bash)
        login = (jmeno[0] + prijmeni).lower()
        # Zjednodušené odstranění diakritiky pro demo
        login = login.replace('á','a').replace('č','c').replace('ď','d').replace('é','e').replace('ě','e').replace('í','i').replace('ň','n').replace('ó','o').replace('ř','r').replace('š','s').replace('ť','t').replace('ú','u').replace('ů','u').replace('ý','y').replace('ž','z')
        
        print(f"dn: uid={login},ou=students,dc=school,dc=cz")
        print(f"objectClass: inetOrgPerson")
        print(f"objectClass: posixAccount")
        print(f"uid: {login}")
        print(f"cn: {jmeno} {prijmeni}")
        print(f"sn: {prijmeni}")
        print(f"givenName: {jmeno}")
        if email:
            print(f"mail: {email}")
        if telefon:
            print(f"telephoneNumber: {telefon}")
        print(f"uidNumber: {id + 2000}")  # offset pro UID
        print(f"gidNumber: 1000")  # students group
        print(f"homeDirectory: /home/{login}")
        print(f"loginShell: /usr/sbin/nologin")
        if poznamka:
            print(f"description: {poznamka}")
        print()
    
    conn.close()

if __name__ == "__main__":
    export_to_ldif()
EOF

chmod +x export_to_ldap.py

# 2. Spuštění exportu
python3 export_to_ldap.py > students.ldif

# 3. Import do LDAP (příklad)
# ldapadd -x -D "cn=admin,dc=school,dc=cz" -W -f students.ldif
```

---

### Scénář 9: Výkonnostní Optimalizace

**Situace:** Optimalizace pro velké množství studentů (10,000+)

```bash
# 1. Benchmark test
cat > benchmark.sh << 'EOF'
#!/bin/bash

echo "🚀 PERFORMANCE BENCHMARK"
echo "======================="

# Test různých velikostí
for size in 1000 5000 10000; do
    echo "📊 Testování velikosti: $size studentů"
    
    # Cleanup před testem
    rm -f ../data/studenti.db
    
    # Test generování
    start_time=$(date +%s)
    echo "$size" | python3 generate_students.py >/dev/null 2>&1
    gen_time=$(($(date +%s) - start_time))
    
    # Kontrola velikosti databáze
    db_size=$(du -k ../data/studenti.db | cut -f1)
    
    echo "  ⏱️  Generování: ${gen_time}s"
    echo "  💾 Velikost DB: ${db_size}KB"
    echo "  📈 Rychlost: $((size / gen_time)) studentů/s"
    
    # Test vytváření účtů (jen pro menší velikosti)
    if [ $size -le 1000 ]; then
        start_time=$(date +%s)
        sudo ./create_users_from_db.sh >/dev/null 2>&1
        create_time=$(($(date +%s) - start_time))
        
        account_count=$(getent passwd | grep nologin | wc -l)
        
        echo "  👥 Vytváření účtů: ${create_time}s"
        echo "  ✅ Vytvořeno: $account_count účtů"
        
        # Test mazání
        start_time=$(date +%s)
        sudo ./delete_students.sh >/dev/null 2>&1
        delete_time=$(($(date +%s) - start_time))
        
        echo "  🗑️  Mazání: ${delete_time}s"
    fi
    
    echo
done
EOF

chmod +x benchmark.sh
./benchmark.sh

# 2. Optimalizace databáze
sqlite3 ../data/studenti.db <<EOF
-- Přidání indexů pro rychlejší vyhledávání
CREATE INDEX IF NOT EXISTS idx_email ON students(email);
CREATE INDEX IF NOT EXISTS idx_name ON students(jmeno, prijmeni);
CREATE INDEX IF NOT EXISTS idx_pojistorna ON students(pojistorna);

-- Analýza pro optimalizaci query planneru
ANALYZE;

-- Vacuum pro defragmentaci
VACUUM;
EOF

# 3. Batch processing skript pro velké množství
cat > batch_create_users.sh << 'EOF'
#!/bin/bash
# Batch vytváření uživatelů po menších dávkách

BATCH_SIZE=100
TOTAL=$(sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students;")
BATCHES=$(((TOTAL + BATCH_SIZE - 1) / BATCH_SIZE))

echo "📦 Batch vytváření účtů"
echo "Celkem studentů: $TOTAL"
echo "Velikost dávky: $BATCH_SIZE"
echo "Počet dávek: $BATCHES"
echo

for i in $(seq 0 $((BATCHES - 1))); do
    offset=$((i * BATCH_SIZE))
    echo "Dávka $((i + 1))/$BATCHES (studenti $((offset + 1))-$((offset + BATCH_SIZE)))"
    
    sqlite3 -csv ../data/studenti.db "
    SELECT jmeno, prijmeni 
    FROM students 
    LIMIT $BATCH_SIZE OFFSET $offset;
    " | while IFS="," read -r jmeno prijmeni; do
        [ -z "$jmeno" ] && continue
        login="$(echo "${jmeno:0:1}$prijmeni" | tr '[:upper:]' '[:lower:]' | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:]')"
        
        if ! id "$login" &>/dev/null; then
            useradd -m -s /usr/sbin/nologin "$login"
            chmod 700 "/home/$login"
        fi
    done
    
    echo "  ✅ Dávka $((i + 1)) dokončena"
    sleep 1  # krátká pauza mezi dávkami
done

echo "🎉 Všechny dávky dokončeny!"
EOF

chmod +x batch_create_users.sh
```

---

## 🛠️ Užitečné Utility Skripty

### Quick Stats Script

```bash
cat > quick_stats.sh << 'EOF'
#!/bin/bash
echo "📊 QUICK STATS"
echo "Database: $(sqlite3 ../data/studenti.db "SELECT COUNT(*) FROM students;" 2>/dev/null || echo "0") students"
echo "Accounts: $(getent passwd | grep nologin | wc -l) system users"  
echo "Disk: $(du -sh ../data/ 2>/dev/null | cut -f1 || echo "0B") database size"
EOF

chmod +x quick_stats.sh
```

### Cleanup Script

```bash
cat > cleanup_all.sh << 'EOF'
#!/bin/bash
echo "🧹 KOMPLETNÍ CLEANUP"
sudo ./delete_students.sh
rm -f ../data/studenti.db
rm -f /tmp/student_*.log
echo "✅ Vše vyčištěno"
EOF

chmod +x cleanup_all.sh
```

---

Tyto příklady pokrývají většinu reálných scénářů použití Student Manager systému. Každý příklad je navržen tak, aby byl snadno adaptovatelný pro konkrétní potřeby vaší organizace.

*Pro více příkladů a nejnovější aktualizace navštivte GitHub repozitář.*