<<<<<<< HEAD
# student-manager
This project demonstrates how to manage a student database using SQLite on Linux, running inside a Docker container based on Ubuntu.
=======
# Student Manager

Projekt pro správu studentů, generování náhodných dat a práci s databází SQLite.

## Struktura adresářů

- `scripts/` – Python/Bash skripty pro generování a správu dat
- `data/` – databáze a exportovaná data (např. studenti.db, CSV)
- `docs/` – dokumentace a návody

## Rychlý start

1. Vytvořte a aktivujte virtuální prostředí:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install faker
   ```
2. Spusťte generování studentů:
   ```bash
   python3 scripts/generate_students.py
   ```
3. Databázi najdete v `data/studenti.db`.

## Další informace
- Dokumentace v `docs/README_SQLITE.md`
>>>>>>> 35db016 (První verze projektu student_manager)
