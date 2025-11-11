from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import config

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()


def create_app(config_name='development'):
    """Application factory pattern"""
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app)
    jwt.init_app(app)

    # JWT error handlers
    @jwt.invalid_token_loader
    def invalid_token_callback(error_string):
        print(f"DEBUG: Invalid token - {error_string}")
        import traceback
        traceback.print_exc()
        return {'error': 'Invalid token', 'message': str(error_string)}, 422

    @jwt.unauthorized_loader
    def unauthorized_callback(error_string):
        print(f"DEBUG: Unauthorized - {error_string}")
        return {'error': 'Missing Authorization Header', 'message': str(error_string)}, 401

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        print(f"DEBUG: Expired token - Header: {jwt_header}, Payload: {jwt_payload}")
        return {'error': 'Token has expired'}, 401

    @jwt.revoked_token_loader
    def revoked_token_callback(jwt_header, jwt_payload):
        print(f"DEBUG: Revoked token - Header: {jwt_header}, Payload: {jwt_payload}")
        return {'error': 'Token has been revoked'}, 401

    # Register blueprints
    from app.api import auth_bp, recipes_bp, ingredients_bp, users_bp
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(recipes_bp, url_prefix='/api/recipes')
    app.register_blueprint(ingredients_bp, url_prefix='/api/ingredients')
    app.register_blueprint(users_bp, url_prefix='/api/users')

    # Health check route
    @app.route('/health')
    def health():
        return {'status': 'healthy', 'service': 'EatEase API'}, 200

    return app
