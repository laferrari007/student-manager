import sqlite3
import random
from faker import Faker
from datetime import datetime, timedelta
import sys

DB_FILE = "../data/studenti.db"
NUM_STUDENTS = 500

# Seznam pojišťoven (pro ukázku)
POJISTOVNY = [
    "VZP", "ČPZP", "OZP", "ZPMV", "RBP", "VoZP"
]

fake = Faker('cs_CZ')

def create_table():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY,
        jmeno TEXT,
        prijmeni TEXT,
        email TEXT,
        adresa TEXT,
        telefon TEXT,
        kontakt_osoba TEXT,
        pojistovna TEXT,
        datum_narozeni TEXT,
        rodne_cislo TEXT,
        poznamka TEXT
    )''')
    conn.commit()
    conn.close()

def random_birthdate():
    start_date = datetime(1990, 1, 1)
    end_date = datetime(2010, 12, 31)
    delta = end_date - start_date
    random_days = random.randint(0, delta.days)
    return (start_date + timedelta(days=random_days)).date()

def generate_rodne_cislo(datum_narozeni):
    # Zjednodušený generátor rodného čísla (není validní pro úřady)
    rc = datum_narozeni.strftime('%y%m%d')
    rc += str(random.randint(100, 999))
    rc += str(random.randint(0, 9))
    return rc

def generate_students(n):
    students = []
    for _ in range(n):
        jmeno = fake.first_name()
        prijmeni = fake.last_name()
        email = f"{jmeno.lower()}.{prijmeni.lower()}@{fake.free_email_domain()}"
        adresa = fake.address().replace('\n', ', ')
        telefon = fake.phone_number()
        kontakt_osoba = fake.name()
        pojistovna = random.choice(POJISTOVNY)
        datum_narozeni = random_birthdate()
        rodne_cislo = generate_rodne_cislo(datum_narozeni)
        poznamka = fake.sentence(nb_words=6)
        students.append((jmeno, prijmeni, email, adresa, telefon, kontakt_osoba, pojistovna, str(datum_narozeni), rodne_cislo, poznamka))
    return students

def insert_students(students):
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.executemany('''INSERT INTO students (jmeno, prijmeni, email, adresa, telefon, kontakt_osoba, pojistovna, datum_narozeni, rodne_cislo, poznamka)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''', students)
    conn.commit()
    conn.close()

def print_students():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('SELECT * FROM students')
    for row in c.fetchall():
        print(row)
    conn.close()

if __name__ == "__main__":
    create_table()
    try:
        n = int(input(f"Zadejte počet studentů k vygenerování [{NUM_STUDENTS}]: ") or NUM_STUDENTS)
    except ValueError:
        print("Zadejte počet studentů jako celé číslo.")
        sys.exit(1)
    students = generate_students(n)
    insert_students(students)
    print(f"Do databáze bylo vloženo {n} studentů.")
    print("Ukázka záznamů:")
    print_students()
