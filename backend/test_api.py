"""
API Testing Script
Run: python test_api.py
"""
import requests
import json

BASE_URL = "http://localhost:5000/api"


def test_search_recipes():
    """Test recipe search by ingredients"""
    print("\n=== Testing Recipe Search ===")

    # Test 1: Search with chicken and garlic
    payload = {
        "ingredients": ["Chicken Breast", "Garlic", "Soy Sauce"],
        "dietary_preferences": {}
    }

    response = requests.post(f"{BASE_URL}/recipes/search", json=payload)
    print(f"\nSearch with: {payload['ingredients']}")
    print(f"Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print(f"Found {len(data['recipes'])} recipes:")
        for recipe in data['recipes']:
            print(f"  - {recipe['name']} ({recipe['match_percentage']}% match)")
            print(f"    Matching: {recipe['matching_ingredients']}/{recipe['total_ingredients']} ingredients")


def test_get_all_recipes():
    """Test getting all recipes"""
    print("\n=== Testing Get All Recipes ===")

    response = requests.get(f"{BASE_URL}/recipes/")
    print(f"Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print(f"Total recipes: {data['total']}")
        for recipe in data['recipes']:
            print(f"  - {recipe['name']} ({recipe['cuisine_type']}, {recipe['difficulty_level']})")


def test_get_ingredients():
    """Test getting all ingredients"""
    print("\n=== Testing Get Ingredients ===")

    response = requests.get(f"{BASE_URL}/ingredients/")
    print(f"Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print(f"Total ingredients: {data['total']}")
        print(f"First 10 ingredients:")
        for ing in data['ingredients'][:10]:
            print(f"  - {ing['name']} ({ing['category']})")


def test_register_and_login():
    """Test user registration and login"""
    print("\n=== Testing User Registration & Login ===")

    # Register
    user_data = {
        "email": "test@eatease.com",
        "username": "testuser",
        "password": "test123",
        "first_name": "Test",
        "last_name": "User"
    }

    response = requests.post(f"{BASE_URL}/auth/register", json=user_data)
    print(f"\nRegister Status: {response.status_code}")

    if response.status_code == 201:
        data = response.json()
        token = data['access_token']
        print(f"User created: {data['user']['username']}")
        print(f"Token received: {token[:20]}...")

        # Test authenticated endpoint
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
        print(f"\nGet Current User Status: {response.status_code}")
        if response.status_code == 200:
            user = response.json()['user']
            print(f"Logged in as: {user['username']} ({user['email']})")

    elif response.status_code == 400:
        print(f"User already exists (expected on re-run)")

        # Try login instead
        login_data = {"email": user_data["email"], "password": user_data["password"]}
        response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        print(f"Login Status: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print(f"Login successful: {data['user']['username']}")


def main():
    """Run all tests"""
    print("=" * 50)
    print("  EatEase API Testing")
    print("=" * 50)

    try:
        # Check if server is running
        response = requests.get("http://localhost:5000/health")
        if response.status_code != 200:
            print("\nError: Backend server not running!")
            print("Start server: python run.py")
            return

        print("\nBackend server is running!\n")

        # Run tests
        test_get_all_recipes()
        test_get_ingredients()
        test_search_recipes()
        test_register_and_login()

        print("\n" + "=" * 50)
        print("  All tests completed!")
        print("=" * 50 + "\n")

    except requests.ConnectionError:
        print("\nError: Cannot connect to backend server!")
        print("Make sure the server is running on http://localhost:5000")


if __name__ == "__main__":
    main()
