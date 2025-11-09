# EatEase - AI-Powered Meal Planning App

Smart cooking, simplified. EatEase uses computer vision and AI to detect ingredients and generate personalized recipe suggestions.

## Project Overview

**Mission**: Provide the community in the Philippines with an easy and convenient solution for delicious and nutritious meal planning tailored to user needs and preferences.

**Vision**: Revolutionize meal planning by using artificial intelligence that provides various delicious and nutritious recipes.

## Tech Stack

### Backend
- Python 3.10+ with Flask
- PostgreSQL database
- TensorFlow & Keras for AI/ML
- YOLO (Ultralytics) for computer vision
- JWT authentication
- AWS for cloud storage

### Frontend
- Flutter (Dart) for iOS & Android
- Provider for state management
- Dio for API communication
- Camera integration for ingredient detection

### Infrastructure
- AWS (cloud storage & hosting)
- Hostinger (web hosting)
- PostgreSQL (database)

## Project Structure

```
EatEase/
├── backend/              # Flask API + AI/ML
│   ├── app/             # Application code
│   ├── migrations/      # Database migrations
│   ├── tests/           # Backend tests
│   └── requirements.txt # Python dependencies
├── frontend/            # Flutter mobile app
│   ├── lib/            # Dart source code
│   ├── assets/         # Images, fonts, icons
│   └── pubspec.yaml    # Flutter dependencies
├── _documentation/      # Project documentation
└── README.md           # This file
```

## Key Features

1. **Real-Time Ingredient Detection** - Camera-based ingredient scanning using YOLO
2. **AI Recipe Generation** - Personalized meal suggestions based on available ingredients
3. **Nutritional Insights** - Detailed nutrition information per meal
4. **Smart Shopping Lists** - Auto-generated based on meal plans
5. **Dietary Preferences** - Vegetarian, vegan, gluten-free, allergies support
6. **Meal Planning** - Weekly meal organization
7. **Freemium Model** - Free basic features with premium enhancements

## Competitive Advantage

Unlike competitors (SuperCook, Plant Jammer, ChefGPT, FoodAI), EatEase offers:
- **Computer vision-powered** real-time ingredient detection (vs manual input)
- **Filipino market focus** (General Santos City)
- **Comprehensive support** (email & chat)
- **Mobile-first** experience

## Getting Started

### Prerequisites

- Python 3.10+
- PostgreSQL 14+
- Flutter SDK 3.0+
- Node.js (optional, for tooling)

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Setup database
createdb eatease_db

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Run migrations
flask db upgrade

# Start server
python run.py
```

Backend runs at: `http://localhost:5000`

### Frontend Setup

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Run on emulator/device
flutter run
```

See individual READMEs in [backend/](backend/README.md) and [frontend/](frontend/README.md) for detailed instructions.

## Development Phases

### Phase 1: Foundation (Weeks 1-2) ✅
- [x] Backend Flask scaffolding
- [x] PostgreSQL schema design
- [x] Database models (User, Recipe, Ingredient, etc.)
- [x] Authentication API (JWT)
- [x] Basic CRUD endpoints
- [ ] Flutter project setup
- [ ] Basic UI screens

### Phase 2: Core Features (Weeks 3-6)
- [ ] Manual ingredient input (API & UI)
- [ ] Recipe database population
- [ ] Recipe matching algorithm
- [ ] User preference management
- [ ] Recipe display UI
- [ ] Search & filter functionality

### Phase 3: AI Integration (Weeks 7-10)
- [ ] YOLO model training/fine-tuning
- [ ] Camera ingredient detection
- [ ] Image preprocessing pipeline
- [ ] ML recipe ranking algorithm
- [ ] Nutritional calculation engine

### Phase 4: Advanced Features (Weeks 11-13)
- [ ] Smart shopping list generation
- [ ] User feedback system
- [ ] Recipe recommendation refinement
- [ ] Meal planning calendar
- [ ] Nutritional insights dashboard

### Phase 5: Polish & Deploy (Weeks 14-16)
- [ ] Freemium subscription logic
- [ ] Payment integration
- [ ] AWS deployment
- [ ] Testing & bug fixes
- [ ] Performance optimization
- [ ] App store submission

## API Documentation

### Base URL
```
Development: http://localhost:5000/api
Production: https://api.eatease.com/api (TBD)
```

### Endpoints

**Authentication**
- `POST /auth/register` - Register user
- `POST /auth/login` - Login user
- `GET /auth/me` - Get current user

**Recipes**
- `GET /recipes/` - List recipes (with filters)
- `GET /recipes/<id>` - Get recipe details
- `POST /recipes/search` - Search by ingredients

**Ingredients**
- `GET /ingredients/` - List ingredients
- `POST /ingredients/detect` - Detect from image

**Users**
- `GET /users/profile` - Get profile
- `PUT /users/profile` - Update profile
- `GET /users/preferences` - Get preferences
- `POST /users/preferences` - Update preferences

See [backend/README.md](backend/README.md) for full API documentation.

## Database Schema

**Core Tables**:
- `users` - User accounts & authentication
- `recipes` - Recipe information & instructions
- `ingredients` - Ingredient catalog & nutrition
- `recipe_ingredients` - Recipe-ingredient relationships
- `user_preferences` - Dietary preferences & goals
- `meal_plans` - User meal scheduling
- `shopping_lists` - Generated shopping lists

## Target Market

- **Demographics**: Ages 25-45, middle-to-high income
- **Location**: General Santos City, Philippines (initial launch)
- **Psychographics**: Health-conscious, tech-savvy, busy professionals
- **Pain Points**: Budget constraints, time management, healthy eating

## Business Model

**Freemium Pricing**:
- Free tier: Basic features, limited recipes
- Premium tier: All features, unlimited access, advanced AI
- Market penetration pricing strategy

## Contributing

This is a private project. For team members:

1. Create feature branch from `main`
2. Follow code style guidelines
3. Write tests for new features
4. Submit PR for review
5. Ensure CI/CD passes

## Testing

```bash
# Backend tests
cd backend
pytest

# Frontend tests
cd frontend
flutter test
```

## Deployment

TBD - AWS deployment strategy

## Documentation

- [Product Documentation](_documentation/EatEase.md)
- [Backend API](backend/README.md)
- [Frontend App](frontend/README.md)
- [Main Guidelines](Main.md)

## License

Proprietary - EatEase Team. All rights reserved.

## Tagline

**"Smart Cooking, Simplified"**

---

Built with ❤️ by the EatEase Team
