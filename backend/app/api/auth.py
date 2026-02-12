from flask import request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from datetime import datetime
from app import db
from app.models import User
from app.api import auth_bp


@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user"""
    data = request.get_json()

    # Validate required fields
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email and password are required'}), 400

    # Check if user already exists
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already registered'}), 400

    # Auto-generate username from email if not provided
    username = data.get('username')
    if not username:
        username = data['email'].split('@')[0]
        # Ensure uniqueness
        counter = 1
        base_username = username
        while User.query.filter_by(username=username).first():
            username = f"{base_username}{counter}"
            counter += 1
    else:
        # Check if custom username is taken
        if User.query.filter_by(username=username).first():
            return jsonify({'error': 'Username already taken'}), 400

    # Parse full_name into first_name and last_name if provided
    full_name = data.get('full_name', '')
    first_name = None
    last_name = None
    if full_name:
        name_parts = full_name.strip().split(maxsplit=1)
        first_name = name_parts[0] if len(name_parts) > 0 else None
        last_name = name_parts[1] if len(name_parts) > 1 else None

    # Create new user
    user = User(
        email=data['email'],
        username=username,
        first_name=first_name,
        last_name=last_name,
        phone=data.get('phone')
    )
    user.set_password(data['password'])

    db.session.add(user)
    db.session.commit()

    # Generate tokens (identity must be a string)
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_access_token(identity=str(user.id))

    return jsonify({
        'message': 'User registered successfully',
        'user': user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token
    }), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    """Login user"""
    data = request.get_json()

    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email and password are required'}), 400

    user = User.query.filter_by(email=data['email']).first()

    if not user:
        print(f"DEBUG: User not found for email: {data['email']}")
        return jsonify({'error': 'Invalid email or password'}), 401

    print(f"DEBUG: User found: {user.email}, checking password...")
    print(f"DEBUG: Password hash: {user.password_hash}")
    print(f"DEBUG: Password provided: {data['password']}")

    password_check = user.check_password(data['password'])
    print(f"DEBUG: Password check result: {password_check}")

    if not password_check:
        return jsonify({'error': 'Invalid email or password'}), 401

    # Update last login
    user.last_login = datetime.utcnow()
    db.session.commit()

    # Generate tokens (identity must be a string)
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_access_token(identity=str(user.id))

    return jsonify({
        'message': 'Login successful',
        'user': user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token
    }), 200


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Get current authenticated user"""
    user_id = int(get_jwt_identity())  # Convert string to int
    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    return jsonify({'user': user.to_dict()}), 200


@auth_bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """Change user password"""
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()

    if not data or not data.get('current_password') or not data.get('new_password'):
        return jsonify({'error': 'Current password and new password are required'}), 400

    # Verify current password
    if not user.check_password(data['current_password']):
        return jsonify({'error': 'Current password is incorrect'}), 401

    new_password = data['new_password']

    # Validate new password length
    if len(new_password) < 6:
        return jsonify({'error': 'New password must be at least 6 characters'}), 400

    # Ensure new password is different
    if user.check_password(new_password):
        return jsonify({'error': 'New password must be different from current password'}), 400

    user.set_password(new_password)
    db.session.commit()

    return jsonify({'message': 'Password changed successfully'}), 200


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required()
def refresh_token():
    """Refresh access token"""
    user_id = get_jwt_identity()  # This will be a string now
    access_token = create_access_token(identity=user_id)  # Already a string

    return jsonify({'access_token': access_token}), 200
