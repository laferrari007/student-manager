# 📊 Databázové Schéma - Student Manager

Kompletní dokumentace databázového schématu pro Student Manager.

---

## 🗄️ Přehled Databáze

Student Manager používá **SQLite3** databázi s názvem `studenti.db` uloženou v adresáři `data/`.

### Základní Informace

- **Databázový engine:** SQLite 3.x
- **Soubor:** `data/studenti.db`
- **Kódování:** UTF-8
- **Velikost:** ~1KB na studenta
- **Kapacita:** Testováno až 100,000+ záznamů

---

## 📋 Schéma Tabulek

### Tabulka `students`

Hlavní tabulka obsahující všechna studentská data.

```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    jmeno TEXT NOT NULL,
    prijmeni TEXT NOT NULL,
    email TEXT UNIQUE,
    adresa TEXT,
    telefon TEXT,
    kontakt_osoba TEXT,
    pojistovna TEXT,
    datum_narozeni TEXT,
    rodne_cislo TEXT,
    poznamka TEXT
);
```

### Detailní Popis Sloupců

| Sloupec | Typ | Povinné | Jedinečné | Popis |
|---------|-----|---------|-----------|--------|
| `id` | `INTEGER` | ✅ | ✅ | **Primární klíč**, automaticky inkrementovaný |
| `jmeno` | `TEXT` | ✅ | ❌ | **Křestní jméno** studenta |
| `prijmeni` | `TEXT` | ✅ | ❌ | **Příjmení** studenta |
| `email` | `TEXT` | ❌ | ✅ | **E-mail** - jedinečný pro každého studenta |
| `adresa` | `TEXT` | ❌ | ❌ | **Bydliště** (ulice, město, PSČ) |
| `telefon` | `TEXT` | ❌ | ❌ | **Telefonní číslo** (mobil/pevná linka) |
| `kontakt_osoba` | `TEXT` | ❌ | ❌ | **Kontaktní osoba** (rodič/opatrovník) |
| `pojistovna` | `TEXT` | ❌ | ❌ | **Zdravotní pojišťovna** |
| `datum_narozeni` | `TEXT` | ❌ | ❌ | **Datum narození** ve formátu YYYY-MM-DD |
| `rodne_cislo` | `TEXT` | ❌ | ❌ | **Rodné číslo** ve formátu YYMMDDSSSS |
| `poznamka` | `TEXT` | ❌ | ❌ | **Volný text** pro poznámky |

---

## 📖 Příklady Dat

### Ukázkový Záznam

```sql
INSERT INTO students VALUES (
    104001,                           -- id
    'Tomáš',                          -- jmeno  
    'Novák',                          -- prijmeni
    'tomas.novak@seznam.cz',          -- email
    'Václavské náměstí 1, 110 00 Praha 1',  -- adresa
    '+420 608 123 456',               -- telefon
    'Marie Nováková',                 -- kontakt_osoba
    'VZP',                            -- pojistovna
    '2001-03-15',                     -- datum_narozeni
    '0103151234',                     -- rodne_cislo
    'Vynikající student matematiky'   -- poznamka
);
```

### Více Příkladů

```sql
-- Student s diakritikou
INSERT INTO students VALUES (
    104002, 'Jiří', 'Černý', 'jiri.cerny@email.cz', 
    'Hlavní 23, 602 00 Brno', '00420 721 987 654', 
    'Věra Černá', 'OZP', '2000-12-08', '0012084567', 
    'Sportovec - fotbal'
);

-- Studentka se složeným jménem
INSERT INTO students VALUES (
    104003, 'Marie-Anna', 'Svobodová', 'marie.svobodova@gmail.com',
    'Nádražní 45, 400 01 Ústí nad Labem', '+420 603 456 789',
    'Ing. Pavel Svoboda Ph.D.', 'ČPZP', '1999-07-22', '9907224891',
    'Studium v zahraničí - Erasmus'
);
```

---

## 🎯 Datové Formáty a Validace

### Formát E-mailů

```
Vzor: [jmeno].[prijmeni]@[provider]
Příklady poskytovatelů: seznam.cz, gmail.com, email.cz, post.cz, centrum.cz, volny.cz, chello.cz
```

### Formát Telefonních Čísel

```
České formáty:
+420 XXX XXX XXX    (mezinárodní)
00420 XXX XXX XXX   (mezinárodní alternativa)

Příklady:
+420 608 123 456
00420 721 987 654
```

### Formát Adres

```
Vzor: [Ulice číslo], [PSČ] [Město]
Příklady:
"Václavské náměstí 1, 110 00 Praha 1"
"Hlavní 23, 602 00 Brno"  
"Nádražní 45, 400 01 Ústí nad Labem"
```

### Zdravotní Pojišťovny

```sql
-- České zdravotní pojišťovny
'VZP'   -- Všeobecná zdravotní pojišťovna (111)
'OZP'   -- Oborová zdravotní pojišťovna (207) 
'ČPZP'  -- Česká průmyslová zdravotní pojišťovna (205)
'VoZP'  -- Vojenská zdravotní pojišťovna (201)
'ZPMV'  -- Zdravotní pojišťovna ministerstva vnitra (211)
'RBP'   -- Revírní bratrská pokladna (213)
```

### Formát Rodných Čísel

```
České rodné číslo: YYMMDD/SSSS nebo YYMMDDSSSS
YY   = rok narození (poslední 2 cifry)
MM   = měsíc narození (ženy +50)
DD   = den narození  
SSSS = pořadové číslo + kontrolní číslice

Příklady:
0103151234  (muž, 15.3.2001)
9950084567  (žena, 8.10.1999, měsíc 10+50=60, ale zkráceno na 50)
```

---

## 🔍 SQL Dotazy a Analýzy

### Základní Statistiky

```sql
-- Celkový počet studentů
SELECT COUNT(*) as total_students FROM students;

-- Počet podle pojišťoven
SELECT pojistorna, COUNT(*) as count 
FROM students 
GROUP BY pojistorna 
ORDER BY count DESC;

-- Věkové rozložení
SELECT 
    CASE 
        WHEN substr(datum_narozeni, 1, 4) >= '2005' THEN '18-19 let'
        WHEN substr(datum_narozeni, 1, 4) >= '2000' THEN '20-24 let'  
        WHEN substr(datum_narozeni, 1, 4) >= '1995' THEN '25-29 let'
        ELSE '30+ let'
    END as age_group,
    COUNT(*) as count
FROM students
GROUP BY age_group;
```

### Pokročilé Dotazy

```sql
-- Studenti s duplicitními e-maily (pro debug)
SELECT email, COUNT(*) as count
FROM students 
GROUP BY email 
HAVING count > 1;

-- Top 10 nejčastějších jmen
SELECT jmeno, COUNT(*) as frequency
FROM students
GROUP BY jmeno
ORDER BY frequency DESC
LIMIT 10;

-- Studenti podle měst
SELECT 
    substr(adresa, instr(adresa, ', ') + 7) as city,
    COUNT(*) as students_count
FROM students
WHERE adresa LIKE '%, %'
GROUP BY city
ORDER BY students_count DESC
LIMIT 20;
```

### Export a Import

```sql
-- Export do CSV
.mode csv
.output students_export.csv
SELECT * FROM students;
.output

-- Import z CSV  
.mode csv
.import students_import.csv students
```

---

## ⚡ Optimalizace Výkonu

### Indexy

```sql
-- Index pro rychlé vyhledávání podle e-mailu
CREATE INDEX idx_email ON students(email);

-- Index pro vyhledávání podle jména a příjmení  
CREATE INDEX idx_name ON students(jmeno, prijmeni);

-- Index pro filtrování podle pojišťovny
CREATE INDEX idx_pojistorna ON students(pojistorna);

-- Kontrola indexů
.indices students
```

### Velikost Databáze

```sql
-- Analýza velikosti
SELECT 
    COUNT(*) as records,
    page_count * page_size as size_bytes,
    (page_count * page_size) / 1024 / 1024 as size_mb
FROM pragma_page_count(), pragma_page_size();

-- Vacuum pro optimalizaci
VACUUM;

-- Analyze pro statistiky
ANALYZE;
```

---

## 🔧 Údržba Databáze

### Pravidelné Kontroly

```sql
-- Kontrola integrity
PRAGMA integrity_check;

-- Kontrola cizích klíčů (pokud jsou použity)  
PRAGMA foreign_key_check;

-- Statistiky tabulky
PRAGMA table_info(students);
```

### Záloha a Obnovení

```bash
# Záloha databáze
cp data/studenti.db data/studenti_backup_$(date +%Y%m%d).db

# Nebo pomocí SQLite
sqlite3 data/studenti.db ".backup data/studenti_backup.db"

# Obnovení ze zálohy
sqlite3 data/studenti.db ".restore data/studenti_backup.db"
```

### Cleanup Operace

```sql
-- Smazání duplicitních záznamů (ponechá nejnovější)
DELETE FROM students 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM students 
    GROUP BY email
);

-- Smazání starých testovacích dat
DELETE FROM students 
WHERE poznamka LIKE '%test%' 
  AND datum_narozeni < '1990-01-01';
```

---

## 📊 Reporty a Analýzy

### Demografické Reporty

```sql
-- Report podle věku a pohlaví (odhadováno z rodného čísla)
SELECT 
    CASE WHEN cast(substr(rodne_cislo, 3, 2) as integer) > 50 
         THEN 'Žena' ELSE 'Muž' END as pohlavi,
    COUNT(*) as pocet
FROM students 
WHERE length(rodne_cislo) = 10
GROUP BY pohlavi;

-- Měsíční distribuce narození
SELECT 
    substr(datum_narozeni, 6, 2) as mesic,
    COUNT(*) as narozeni
FROM students
GROUP BY mesic
ORDER BY mesic;
```

### Geografické Reporty

```sql
-- Top města podle počtu studentů
SELECT 
    trim(substr(adresa, instr(adresa, ', ') + 7)) as mesto,
    COUNT(*) as pocet_studentu
FROM students  
WHERE adresa LIKE '%, %'
GROUP BY mesto
HAVING pocet_studentu > 10
ORDER BY pocet_studentu DESC;
```

---

## 🛠️ Migrace a Upgrades

### Přidání Nového Sloupce

```sql
-- Přidání sloupce pro studijní obor
ALTER TABLE students ADD COLUMN studijni_obor TEXT;

-- Naplnění výchozími hodnotami
UPDATE students SET studijni_obor = 'Neurčeno' WHERE studijni_obor IS NULL;
```

### Změna Struktury

```sql
-- Vytvoření nové verze tabulky
CREATE TABLE students_v2 (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    jmeno TEXT NOT NULL,
    prijmeni TEXT NOT NULL,  
    email TEXT UNIQUE,
    -- nové sloupce
    telefon_mobil TEXT,
    telefon_pevny TEXT,
    -- zbytek jako předtím
    adresa TEXT,
    kontakt_osoba TEXT,
    pojistovna TEXT,  
    datum_narozeni TEXT,
    rodne_cislo TEXT,
    poznamka TEXT
);

-- Migrace dat
INSERT INTO students_v2 (id, jmeno, prijmeni, email, telefon_mobil, adresa, kontakt_osoba, pojistorna, datum_narozeni, rodne_cislo, poznamka)
SELECT id, jmeno, prijmeni, email, telefon, adresa, kontakt_osoba, pojistorna, datum_narozeni, rodne_cislo, poznamka
FROM students;

-- Přejmenování tabulek
ALTER TABLE students RENAME TO students_old;
ALTER TABLE students_v2 RENAME TO students;
```

---

## 🔍 Troubleshooting

### Časté Problémy

**Problem:** `database is locked`
```sql
-- Kontrola aktivních připojení
.databases
-- Ukončení všech připojení a restart
```

**Problem:** `UNIQUE constraint failed`
```sql
-- Nalezení duplicitních záznamů
SELECT email, COUNT(*) FROM students GROUP BY email HAVING COUNT(*) > 1;
-- Smazání duplicitů
DELETE FROM students WHERE id NOT IN (SELECT MIN(id) FROM students GROUP BY email);
```

**Problem:** Pomalé dotazy
```sql
-- Analýza výkonu
.timer on
EXPLAIN QUERY PLAN SELECT * FROM students WHERE email = 'test@email.cz';
-- Přidání indexu
CREATE INDEX idx_email ON students(email);
```

---

*Tato dokumentace je pravidelně aktualizována. Pro nejnovější informace kontrolujte GitHub repozitář.*