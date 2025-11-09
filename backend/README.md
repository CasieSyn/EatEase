# EatEase Backend API

AI-powered meal planning backend built with Flask, PostgreSQL, and TensorFlow.

## Tech Stack

- **Framework**: Flask 3.0
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Authentication**: JWT (Flask-JWT-Extended)
- **AI/ML**: TensorFlow, Keras, YOLO (Ultralytics)
- **Image Processing**: OpenCV, Pillow

## Project Structure

```
backend/
├── app/
│   ├── __init__.py          # Application factory
│   ├── api/                 # API endpoints
│   │   ├── auth.py         # Authentication routes
│   │   ├── recipes.py      # Recipe management
│   │   ├── ingredients.py  # Ingredient detection
│   │   └── users.py        # User profile & preferences
│   ├── models/             # Database models
│   │   ├── user.py
│   │   ├── recipe.py
│   │   ├── ingredient.py
│   │   ├── user_preference.py
│   │   ├── meal_plan.py
│   │   └── shopping_list.py
│   ├── services/           # Business logic (TODO)
│   ├── ml/                 # ML models (TODO)
│   └── utils/              # Helper functions (TODO)
├── migrations/             # Database migrations
├── tests/                  # Unit & integration tests
├── config.py              # Configuration
├── requirements.txt       # Python dependencies
└── run.py                # Application entry point
```

## Setup Instructions

### Prerequisites

- Python 3.10+
- PostgreSQL 14+
- pip or virtualenv

### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Setup Database

Create PostgreSQL database:

```sql
CREATE DATABASE eatease_db;
CREATE USER eatease_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE eatease_db TO eatease_user;
```

### 4. Configure Environment

Copy `.env.example` to `.env` and update:

```bash
cp .env.example .env
```

Edit `.env`:
```env
DATABASE_URL=postgresql://eatease_user:your_password@localhost:5432/eatease_db
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret
```

### 5. Initialize Database

```bash
flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

### 6. Run Development Server

```bash
python run.py
```

API available at: `http://localhost:5000`

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (requires JWT)
- `POST /api/auth/refresh` - Refresh access token

### Recipes

- `GET /api/recipes/` - List recipes (with filters)
- `GET /api/recipes/<id>` - Get recipe details
- `POST /api/recipes/search` - Search by ingredients
- `POST /api/recipes/` - Create recipe (requires JWT)

### Ingredients

- `GET /api/ingredients/` - List ingredients
- `GET /api/ingredients/<id>` - Get ingredient details
- `POST /api/ingredients/detect` - Detect from image (requires JWT)
- `POST /api/ingredients/` - Create ingredient (requires JWT)

### Users

- `GET /api/users/profile` - Get user profile (requires JWT)
- `PUT /api/users/profile` - Update profile (requires JWT)
- `GET /api/users/preferences` - Get preferences (requires JWT)
- `POST /api/users/preferences` - Update preferences (requires JWT)
- `GET /api/users/meal-plans` - Get meal plans (requires JWT)
- `GET /api/users/shopping-lists` - Get shopping lists (requires JWT)

### Health Check

- `GET /health` - API health status

## Development

### Database Migrations

```bash
# Create migration
flask db migrate -m "Description"

# Apply migration
flask db upgrade

# Rollback migration
flask db downgrade
```

### Testing

```bash
pytest
```

### Code Formatting

```bash
black app/
flake8 app/
```

## Next Steps

1. Implement ML services for ingredient detection (YOLO integration)
2. Add recipe recommendation algorithm
3. Implement nutritional calculation service
4. Add smart shopping list generation
5. Setup AWS S3 for image storage
6. Add comprehensive testing
7. Setup CI/CD pipeline
8. Add API documentation (Swagger/OpenAPI)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FLASK_ENV` | Environment (development/production) | development |
| `DATABASE_URL` | PostgreSQL connection string | - |
| `SECRET_KEY` | Flask secret key | - |
| `JWT_SECRET_KEY` | JWT signing key | - |
| `JWT_ACCESS_TOKEN_EXPIRES` | Token expiry (hours) | 1 |
| `YOLO_MODEL_PATH` | Path to YOLO model | models/yolov8n.pt |
| `AWS_BUCKET_NAME` | S3 bucket for images | - |

## License

Proprietary - EatEase Team
