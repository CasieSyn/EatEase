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
- Flutter 3.0+ (Dart) for iOS, Android & Web
- Provider for state management
- HTTP package for API communication
- Material Design 3 UI components
- Image Picker for photo uploads
- Intl for date formatting

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

### ✅ Implemented
1. **Recipe Browsing** - Search and filter Filipino recipes by name, category, difficulty
2. **Ingredient Management** - Browse ingredients with category filtering and nutritional info
3. **Meal Planning** - Weekly calendar view with breakfast, lunch, dinner, snack organization
4. **Smart Shopping Lists** - Auto-generated from meal plans with purchase tracking
5. **User Profiles** - Editable profile with photo upload support
6. **Recipe Ratings** - Rate and review recipes
7. **Authentication** - Secure JWT-based login with token refresh
8. **AI Ingredient Detection** - Camera/gallery image ingredient detection using Google Vision + YOLOv8n fallback
9. **Recipe Search by Detection** - Find recipes based on detected ingredients
10. **AI Recipe Recommendations** - Personalized suggestions, quick recipes, and cuisine-based recommendations
11. **Pantry Management** - Track ingredients on hand with quantity, unit, and expiry date
12. **Detection Feedback** - User corrections improve AI ingredient detection accuracy over time
13. **PWA Support** - Progressive Web App enhancements for mobile-width web experience

### 🚧 In Development
14. **Nutritional Dashboard** - Detailed nutrition tracking per meal

### 📋 Planned
15. **Dietary Preferences** - Vegetarian, vegan, gluten-free, allergies support
16. **Freemium Model** - Premium features with subscription

## Competitive Advantage

Unlike competitors (SuperCook, Plant Jammer, ChefGPT, FoodAI), EatEase offers:
- **Computer vision-powered** real-time ingredient detection via Google Vision + YOLO (vs manual input)
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

### Phase 1: Foundation ✅ COMPLETED
- [x] Backend Flask scaffolding
- [x] PostgreSQL schema design
- [x] Database models (User, Recipe, Ingredient, MealPlan, ShoppingList)
- [x] Authentication API (JWT with token refresh)
- [x] Basic CRUD endpoints for all resources
- [x] Database migrations setup (Flask-Migrate)
- [x] API error handling and validation

### Phase 2: Core Backend Features ✅ COMPLETED
- [x] Recipe management API (CRUD operations)
- [x] Recipe database population with Filipino recipes
- [x] Ingredient management API
- [x] Recipe-ingredient relationship management
- [x] User preferences API
- [x] Meal planning API (create, update, complete)
- [x] Shopping list generation from meal plans
- [x] Recipe search and filtering
- [x] Recipe rating system
- [x] User profile management with photo upload

### Phase 3: Flutter Frontend - Core Features ✅ COMPLETED
- [x] Flutter project setup with Material Design 3
- [x] Provider state management implementation
- [x] Authentication screens (Login, Register)
- [x] JWT token management with auto-refresh
- [x] Home screen with bottom navigation (5 tabs)
- [x] Recipe browsing with search and filters
- [x] Recipe detail view with ratings
- [x] Pull-to-refresh on all screens
- [x] Error handling and loading states
- [x] Network configuration for dev/prod environments

### Phase 4: Advanced Frontend Features ✅ COMPLETED
- [x] Ingredients Tab with search and category filtering
- [x] Meal Plans Tab with weekly calendar view
- [x] Profile Tab with editable user information
- [x] Profile photo upload (mobile only)
- [x] Real-time state management across screens
- [x] Shopping Lists Tab with generation from meal plans
- [x] Shopping list item categorization
- [x] Purchase tracking with checkboxes
- [x] Progress indicators and completion status
- [x] Date range selection for meal planning
- [x] JWT token validation on all protected routes

### Phase 5: Code Quality & Deployment Prep ✅ COMPLETED
- [x] Flutter analyzer checks (all issues resolved)
- [x] BuildContext async gap fixes
- [x] Removed unnecessary type declarations
- [x] Code documentation and comments
- [x] Git repository setup with meaningful commits
- [x] Development log maintenance
- [x] API endpoint testing and validation

### Phase 6: AI Integration ✅ COMPLETED
- [x] YOLO model download and setup (YOLOv8n)
- [x] Google Vision + YOLO fallback detection pipeline
- [x] Camera ingredient detection integration
- [x] Image preprocessing pipeline (backend)
- [x] Ingredient detection service (Flutter)
- [x] Detection screen UI with camera/gallery
- [x] Recipe search integration with detected ingredients
- [x] Confidence-based filtering and display
- [x] AI-powered recipe recommendations (personalized, quick, cuisine-based)
- [x] Detection feedback system (user corrections improve accuracy)
- [x] Pantry management system (track ingredients on hand)
- [x] PWA enhancements for mobile web experience
- [ ] ML recipe ranking algorithm (future enhancement)
- [ ] Nutritional calculation engine (future enhancement)

### Phase 7: Polish & Production (Upcoming)
- [ ] Freemium subscription logic
- [ ] Payment integration (Stripe/PayPal)
- [ ] AWS deployment configuration
- [ ] Production database migration
- [ ] Performance optimization and caching
- [ ] End-to-end testing
- [ ] App store submission (iOS & Android)
- [ ] Marketing website

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
- `GET /recipes/` - List recipes (with search, category, difficulty filters)
- `POST /recipes/` - Create a new recipe
- `GET /recipes/<id>` - Get recipe details
- `PUT /recipes/<id>` - Update a recipe
- `DELETE /recipes/<id>` - Delete a recipe
- `POST /recipes/search` - Search by ingredients
- `POST /recipes/recommend` - Get personalized AI recommendations
- `GET /recipes/recommend/quick` - Get quick recipes (by max cook time)
- `GET /recipes/recommend/cuisine/<type>` - Get recommendations by cuisine
- `POST /recipes/<id>/rate` - Rate a recipe
- `GET /recipes/<id>/image` - Get recipe image
- `POST /recipes/fetch-images` - Batch fetch recipe images

**Ingredients**
- `GET /ingredients/` - List ingredients (with category filter)
- `GET /ingredients/<id>` - Get ingredient details
- `POST /ingredients/` - Create an ingredient
- `POST /ingredients/detect` - Detect from image (AI)
- `POST /ingredients/detect/feedback` - Submit detection corrections
- `GET /ingredients/detect/learned-mappings` - Get learned detection mappings

**Users**
- `GET /users/profile` - Get user profile
- `PUT /users/profile` - Update profile
- `POST /users/profile/photo` - Upload profile photo
- `GET /users/profile/photo/<user_id>` - Get profile photo
- `GET /users/preferences` - Get dietary preferences
- `PUT /users/preferences` - Update preferences

**Pantry**
- `GET /users/pantry` - Get pantry items
- `POST /users/pantry` - Add ingredient(s) to pantry
- `PUT /users/pantry/<id>` - Update a pantry item
- `DELETE /users/pantry/<id>` - Remove a pantry item
- `DELETE /users/pantry/ingredient/<ingredient_id>` - Remove by ingredient
- `DELETE /users/pantry/bulk` - Remove multiple ingredients
- `DELETE /users/pantry/clear` - Clear entire pantry

**Meal Plans**
- `GET /users/meal-plans` - Get meal plans (with date range)
- `POST /users/meal-plans` - Create meal plan
- `PUT /users/meal-plans/<id>` - Update meal plan (including mark as completed via `is_completed`)
- `DELETE /users/meal-plans/<id>` - Delete meal plan

**Shopping Lists**
- `GET /users/shopping-lists` - Get shopping lists
- `POST /users/shopping-lists/generate` - Generate from meal plans
- `PUT /users/shopping-lists/<id>` - Update list items
- `DELETE /users/shopping-lists/<id>` - Delete shopping list

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
- `user_pantry` - User ingredient inventory with quantity & expiry tracking
- `detection_feedback` - AI detection corrections & learned mappings

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
- [Main Guidelines](_documentation/Main.md)

## License

Proprietary - EatEase Team. All rights reserved.

## Tagline

**"Smart Cooking, Simplified"**

---

Built with ❤️ by the EatEase Team
