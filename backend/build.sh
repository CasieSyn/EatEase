#!/usr/bin/env bash
# Render build script for EatEase backend
set -o errexit

# Install dependencies (lightweight, no ML)
pip install -r requirements-render.txt

# Run database migrations (create tables on fresh DB)
python -c "
from app import create_app, db
from flask_migrate import upgrade

app = create_app('production')
with app.app_context():
    try:
        upgrade()
    except Exception as e:
        print(f'Migration failed ({e}), falling back to create_all...')
        db.create_all()
"

# Seed database with initial data (only if tables are empty)
python -c "
from app import create_app, db
from app.models import Ingredient

app = create_app('production')
with app.app_context():
    if Ingredient.query.count() == 0:
        print('Database is empty, seeding initial data...')
        from seed_data import seed_ingredients, seed_recipes
        seed_ingredients()
        seed_recipes()
        print('Seeding complete!')
    else:
        print('Database already has data, skipping seed.')
"
