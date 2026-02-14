"""
Google Vision API Ingredient Detector
Uses Google Cloud Vision for accurate food/ingredient detection
Includes machine learning from user corrections
"""

import logging
import os
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)
try:
    from google.cloud import vision
    VISION_AVAILABLE = True
except ImportError:
    VISION_AVAILABLE = False


class GoogleVisionDetector:
    """Handles ingredient detection using Google Cloud Vision API"""

    # Mapping of Google Vision labels to database ingredients
    # Comprehensive Filipino ingredient mapping
    VISION_TO_INGREDIENT = {
        # =====================
        # VEGETABLES
        # =====================
        # Leafy Greens
        'kangkong': 'Kangkong',
        'water spinach': 'Kangkong',
        'swamp cabbage': 'Kangkong',
        'pechay': 'Pechay',
        'bok choy': 'Pechay',
        'pak choi': 'Pechay',
        'chinese cabbage': 'Pechay',
        'mustard greens': 'Mustasa',
        'mustasa': 'Mustasa',
        'spinach': 'Spinach',
        'malunggay': 'Malunggay',
        'moringa': 'Malunggay',
        'drumstick leaves': 'Malunggay',
        'talbos ng kamote': 'Talbos ng Kamote',
        'sweet potato leaves': 'Talbos ng Kamote',
        'camote tops': 'Talbos ng Kamote',
        'alugbati': 'Alugbati',
        'malabar spinach': 'Alugbati',
        'saluyot': 'Saluyot',
        'jute leaves': 'Saluyot',
        'lettuce': 'Lettuce',

        # Root Vegetables
        'carrot': 'Carrot',
        'carrots': 'Carrot',
        'potato': 'Potato',
        'potatoes': 'Potato',
        'kamote': 'Kamote',
        'sweet potato': 'Kamote',
        'gabi': 'Gabi',
        'taro': 'Gabi',
        'taro root': 'Gabi',
        'ube': 'Ube',
        'purple yam': 'Ube',
        'singkamas': 'Singkamas',
        'jicama': 'Singkamas',
        'turnip': 'Singkamas',
        'radish': 'Labanos',
        'labanos': 'Labanos',
        'daikon': 'Labanos',

        # Gourds & Squash
        'kalabasa': 'Kalabasa',
        'squash': 'Kalabasa',
        'pumpkin': 'Kalabasa',
        'butternut squash': 'Kalabasa',
        'upo': 'Upo',
        'bottle gourd': 'Upo',
        'patola': 'Patola',
        'sponge gourd': 'Patola',
        'luffa': 'Patola',
        'ampalaya': 'Ampalaya',
        'bitter melon': 'Ampalaya',
        'bitter gourd': 'Ampalaya',
        'sayote': 'Sayote',
        'chayote': 'Sayote',

        # Beans & Pods
        'sitaw': 'Sitaw',
        'string beans': 'Sitaw',
        'yard long beans': 'Sitaw',
        'long beans': 'Sitaw',
        'green beans': 'Green Beans',
        'bataw': 'Bataw',
        'hyacinth bean': 'Bataw',
        'okra': 'Okra',
        'lady finger': 'Okra',
        'talong': 'Talong',
        'eggplant': 'Talong',
        'aubergine': 'Talong',

        # Peppers
        'bell pepper': 'Bell Pepper',
        'capsicum': 'Bell Pepper',
        'sili': 'Siling Labuyo',
        'chili': 'Siling Labuyo',
        'chili pepper': 'Siling Labuyo',
        'siling labuyo': 'Siling Labuyo',
        'bird eye chili': 'Siling Labuyo',
        'siling haba': 'Siling Haba',
        'long pepper': 'Siling Haba',
        'finger chili': 'Siling Haba',

        # Alliums
        'onion': 'Onion',
        'onions': 'Onion',
        'sibuyas': 'Onion',
        'red onion': 'Red Onion',
        'shallot': 'Shallots',
        'shallots': 'Shallots',
        'spring onion': 'Spring Onion',
        'green onion': 'Spring Onion',
        'scallion': 'Spring Onion',
        'leeks': 'Leeks',
        'leek': 'Leeks',
        'garlic': 'Garlic',
        'bawang': 'Garlic',

        # Other Vegetables
        'tomato': 'Tomato',
        'tomatoes': 'Tomato',
        'kamatis': 'Tomato',
        'cabbage': 'Cabbage',
        'repolyo': 'Cabbage',
        'cucumber': 'Cucumber',
        'pipino': 'Cucumber',
        'corn': 'Corn',
        'mais': 'Corn',
        'baby corn': 'Baby Corn',
        'bamboo shoots': 'Bamboo Shoots',
        'labong': 'Bamboo Shoots',
        'mushroom': 'Button Mushrooms',
        'mushrooms': 'Button Mushrooms',
        'button mushroom': 'Button Mushrooms',
        'shiitake': 'Shiitake Mushrooms',
        'oyster mushroom': 'Oyster Mushrooms',
        'bean sprouts': 'Togue',
        'togue': 'Togue',
        'mung bean sprouts': 'Togue',
        'ginger': 'Ginger',
        'luya': 'Ginger',

        # =====================
        # PROTEINS - MEAT
        # =====================
        # Chicken
        'chicken': 'Chicken',
        'chicken breast': 'Chicken Breast',
        'chicken thigh': 'Chicken Thigh',
        'chicken leg': 'Chicken Leg',
        'chicken drumstick': 'Chicken Drumstick',
        'chicken wing': 'Chicken Wings',
        'chicken wings': 'Chicken Wings',
        'chicken liver': 'Chicken Liver',
        'chicken gizzard': 'Chicken Gizzard',

        # Pork
        'pork': 'Pork',
        'pork belly': 'Pork Belly',
        'liempo': 'Pork Belly',
        'pork shoulder': 'Pork Shoulder',
        'kasim': 'Pork Shoulder',
        'pork loin': 'Pork Loin',
        'pork chop': 'Pork Chops',
        'pork chops': 'Pork Chops',
        'pork ribs': 'Pork Ribs',
        'spare ribs': 'Pork Ribs',
        'ground pork': 'Ground Pork',
        'pork liver': 'Pork Liver',
        'pigs blood': 'Pork Blood',
        'pork blood': 'Pork Blood',
        'dinuguan': 'Pork Blood',
        'pork hock': 'Pork Hock',
        'pata': 'Pork Hock',
        'pork knuckle': 'Pork Hock',
        'pork ear': 'Pork Ears',
        'pork ears': 'Pork Ears',
        'pork intestine': 'Pork Intestines',
        'isaw baboy': 'Pork Intestines',
        'chicharon': 'Chicharon',
        'pork crackling': 'Chicharon',
        'pork rinds': 'Chicharon',

        # Beef
        'beef': 'Beef',
        'beef brisket': 'Beef Brisket',
        'beef shank': 'Beef Shank',
        'bulalo': 'Beef Shank',
        'beef sirloin': 'Beef Sirloin',
        'beef tenderloin': 'Beef Tenderloin',
        'ground beef': 'Ground Beef',
        'beef liver': 'Beef Liver',
        'beef tripe': 'Beef Tripe',
        'goto': 'Beef Tripe',
        'oxtail': 'Oxtail',
        'ox tail': 'Oxtail',

        # Other Meats
        'longganisa': 'Longganisa',
        'longaniza': 'Longganisa',
        'sausage': 'Longganisa',
        'tocino': 'Tocino',
        'tapa': 'Tapa',
        'dried beef': 'Tapa',
        'chorizo': 'Chorizo de Bilbao',
        'ham': 'Ham',

        # =====================
        # PROTEINS - SEAFOOD
        # =====================
        # Fish
        'fish': 'Tilapia',
        'tilapia': 'Tilapia',
        'bangus': 'Bangus',
        'milkfish': 'Bangus',
        'galunggong': 'Galunggong',
        'round scad': 'Galunggong',
        'tulingan': 'Tulingan',
        'tuna': 'Tuna',
        'skipjack': 'Tulingan',
        'tanigue': 'Tanigue',
        'spanish mackerel': 'Tanigue',
        'salmon': 'Salmon',
        'dilis': 'Dilis',
        'anchovies': 'Dilis',
        'anchovy': 'Dilis',
        'dried fish': 'Tuyo',
        'tuyo': 'Tuyo',
        'tinapa': 'Tinapa',
        'smoked fish': 'Tinapa',
        'daing': 'Daing',
        'salted fish': 'Daing',

        # Shellfish & Crustaceans
        'shrimp': 'Shrimp',
        'hipon': 'Shrimp',
        'prawn': 'Shrimp',
        'prawns': 'Shrimp',
        'crab': 'Crab',
        'alimango': 'Crab',
        'mud crab': 'Crab',
        'lobster': 'Lobster',
        'squid': 'Squid',
        'pusit': 'Squid',
        'calamari': 'Squid',
        'mussel': 'Mussels',
        'mussels': 'Mussels',
        'tahong': 'Mussels',
        'clam': 'Clams',
        'clams': 'Clams',
        'halaan': 'Clams',
        'oyster': 'Oysters',
        'oysters': 'Oysters',
        'talaba': 'Oysters',

        # =====================
        # EGGS & DAIRY
        # =====================
        'egg': 'Eggs',
        'eggs': 'Eggs',
        'itlog': 'Eggs',
        'chicken egg': 'Eggs',
        'salted egg': 'Salted Egg',
        'itlog na maalat': 'Salted Egg',
        'century egg': 'Century Egg',
        'balut': 'Balut',
        'duck egg': 'Balut',
        'quail egg': 'Quail Eggs',
        'quail eggs': 'Quail Eggs',
        'milk': 'Fresh Milk',
        'fresh milk': 'Fresh Milk',
        'evaporated milk': 'Evaporated Milk',
        'condensed milk': 'Condensed Milk',
        'coconut milk': 'Coconut Milk',
        'gata': 'Coconut Milk',
        'coconut cream': 'Coconut Cream',
        'cheese': 'Cheese',
        'kesong puti': 'Kesong Puti',
        'white cheese': 'Kesong Puti',
        'butter': 'Butter',
        'margarine': 'Margarine',

        # =====================
        # GRAINS & STARCHES
        # =====================
        'rice': 'Rice',
        'bigas': 'Rice',
        'jasmine rice': 'Jasmine Rice',
        'glutinous rice': 'Glutinous Rice',
        'malagkit': 'Glutinous Rice',
        'sticky rice': 'Glutinous Rice',
        'brown rice': 'Brown Rice',
        'flour': 'All-Purpose Flour',
        'all purpose flour': 'All-Purpose Flour',
        'bread flour': 'Bread Flour',
        'rice flour': 'Rice Flour',
        'cornstarch': 'Cornstarch',
        'corn starch': 'Cornstarch',
        'tapioca': 'Tapioca Pearls',
        'sago': 'Sago',
        'bread': 'Pandesal',
        'pandesal': 'Pandesal',
        'bread roll': 'Pandesal',
        'noodles': 'Pancit Canton',
        'pancit': 'Pancit Canton',
        'canton noodles': 'Pancit Canton',
        'bihon': 'Bihon',
        'rice noodles': 'Bihon',
        'vermicelli': 'Bihon',
        'sotanghon': 'Sotanghon',
        'glass noodles': 'Sotanghon',
        'cellophane noodles': 'Sotanghon',
        'miki': 'Fresh Miki',
        'fresh noodles': 'Fresh Miki',
        'pasta': 'Spaghetti',
        'spaghetti': 'Spaghetti',

        # =====================
        # LEGUMES
        # =====================
        'mung beans': 'Mung Beans',
        'monggo': 'Mung Beans',
        'munggo': 'Mung Beans',
        'green gram': 'Mung Beans',
        'kidney beans': 'Red Kidney Beans',
        'red beans': 'Red Kidney Beans',
        'white beans': 'White Beans',
        'black beans': 'Black Beans',
        'chickpeas': 'Chickpeas',
        'garbanzo': 'Chickpeas',
        'peanuts': 'Peanuts',
        'mani': 'Peanuts',
        'peanut': 'Peanuts',
        'cashew': 'Cashews',
        'cashews': 'Cashews',
        'kasoy': 'Cashews',
        'tofu': 'Tofu',
        'tokwa': 'Tofu',
        'bean curd': 'Tofu',

        # =====================
        # CONDIMENTS & SAUCES
        # =====================
        'soy sauce': 'Soy Sauce',
        'toyo': 'Soy Sauce',
        'vinegar': 'Cane Vinegar',
        'suka': 'Cane Vinegar',
        'fish sauce': 'Fish Sauce',
        'patis': 'Fish Sauce',
        'bagoong': 'Bagoong',
        'shrimp paste': 'Bagoong',
        'bagoong alamang': 'Bagoong Alamang',
        'oyster sauce': 'Oyster Sauce',
        'ketchup': 'Banana Ketchup',
        'banana ketchup': 'Banana Ketchup',
        'tomato sauce': 'Tomato Sauce',
        'tomato paste': 'Tomato Paste',
        'calamansi': 'Calamansi',
        'calamondin': 'Calamansi',
        'philippine lime': 'Calamansi',
        'lemon': 'Lemon',
        'lime': 'Lime',
        'tamarind': 'Tamarind',
        'sampalok': 'Tamarind',
        'annatto': 'Annatto Seeds',
        'atsuete': 'Annatto Seeds',
        'achuete': 'Annatto Seeds',
        'mayonnaise': 'Mayonnaise',
        'mustard': 'Mustard',

        # =====================
        # SPICES & HERBS
        # =====================
        'bay leaf': 'Bay Leaves',
        'bay leaves': 'Bay Leaves',
        'laurel': 'Bay Leaves',
        'black pepper': 'Black Pepper',
        'pepper': 'Black Pepper',
        'peppercorn': 'Whole Peppercorns',
        'peppercorns': 'Whole Peppercorns',
        'salt': 'Salt',
        'sugar': 'White Sugar',
        'white sugar': 'White Sugar',
        'brown sugar': 'Brown Sugar',
        'muscovado': 'Muscovado Sugar',
        'palm sugar': 'Coconut Sugar',
        'coconut sugar': 'Coconut Sugar',
        'paprika': 'Paprika',
        'cumin': 'Cumin',
        'turmeric': 'Turmeric',
        'luyang dilaw': 'Turmeric',
        'cinnamon': 'Cinnamon',
        'star anise': 'Star Anise',
        'cloves': 'Cloves',
        'nutmeg': 'Nutmeg',
        'oregano': 'Oregano',
        'basil': 'Basil',
        'cilantro': 'Cilantro',
        'coriander': 'Cilantro',
        'wansoy': 'Cilantro',
        'parsley': 'Parsley',
        'lemongrass': 'Lemongrass',
        'tanglad': 'Lemongrass',
        'pandan': 'Pandan Leaves',
        'pandan leaves': 'Pandan Leaves',
        'screwpine': 'Pandan Leaves',

        # =====================
        # FRUITS
        # =====================
        'banana': 'Saba Banana',
        'saba': 'Saba Banana',
        'plantain': 'Saba Banana',
        'lakatan': 'Lakatan Banana',
        'latundan': 'Latundan Banana',
        'mango': 'Mango',
        'mangga': 'Mango',
        'green mango': 'Green Mango',
        'unripe mango': 'Green Mango',
        'papaya': 'Papaya',
        'green papaya': 'Green Papaya',
        'pineapple': 'Pineapple',
        'pinya': 'Pineapple',
        'coconut': 'Coconut',
        'niyog': 'Coconut',
        'young coconut': 'Buko',
        'buko': 'Buko',
        'dayap': 'Dayap',
        'key lime': 'Dayap',
        'suha': 'Pomelo',
        'pomelo': 'Pomelo',
        'atis': 'Atis',
        'sugar apple': 'Atis',
        'guyabano': 'Guyabano',
        'soursop': 'Guyabano',
        'langka': 'Langka',
        'jackfruit': 'Langka',
        'rambutan': 'Rambutan',
        'lanzones': 'Lanzones',
        'durian': 'Durian',
        'santol': 'Santol',
        'guava': 'Guava',
        'bayabas': 'Guava',
        'watermelon': 'Watermelon',
        'pakwan': 'Watermelon',
        'melon': 'Melon',
        'apple': 'Apple',
        'orange': 'Orange',
        'grapes': 'Grapes',
        'grape': 'Grapes',

        # =====================
        # CANNED GOODS
        # =====================
        'corned beef': 'Corned Beef',
        'spam': 'Luncheon Meat',
        'luncheon meat': 'Luncheon Meat',
        'sardines': 'Sardines',
        'sardine': 'Sardines',
        'canned tuna': 'Canned Tuna',
        'tuna flakes': 'Canned Tuna',
        'canned coconut cream': 'Canned Coconut Cream',

        # =====================
        # COOKING OILS & FATS
        # =====================
        'cooking oil': 'Cooking Oil',
        'vegetable oil': 'Cooking Oil',
        'coconut oil': 'Coconut Oil',
        'olive oil': 'Olive Oil',
        'sesame oil': 'Sesame Oil',
        'lard': 'Lard',
        'mantika': 'Lard',

        # =====================
        # GENERAL TERMS (excluded)
        # =====================
        'vegetable': None,  # Too generic
        'food': None,
        'ingredient': None,
        'produce': None,
        'meat': None,
        'dish': None,
        'meal': None,
        'cuisine': None,
    }

    # Cache for learned mappings from database
    _learned_mappings_cache = {}
    _cache_timestamp = None

    def __init__(self, credentials_path: Optional[str] = None):
        """
        Initialize Google Vision detector

        Args:
            credentials_path: Path to Google Cloud credentials JSON file
        """
        self.client = None
        self.available = VISION_AVAILABLE

        if not VISION_AVAILABLE:
            logger.warning("Google Cloud Vision not available. Install with: pip install google-cloud-vision")
            return

        # Try to initialize client
        try:
            # Priority 1: Base64-encoded credentials from env var (for cloud deployments like Render)
            credentials_json_b64 = os.environ.get('GOOGLE_VISION_CREDENTIALS_JSON')
            if credentials_json_b64:
                import base64
                import tempfile
                credentials_data = base64.b64decode(credentials_json_b64)
                tmp = tempfile.NamedTemporaryFile(mode='wb', suffix='.json', delete=False)
                tmp.write(credentials_data)
                tmp.close()
                os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = tmp.name
                logger.info("Using Google Vision credentials from GOOGLE_VISION_CREDENTIALS_JSON env var")

            # Priority 2: File path credentials (for local development)
            elif credentials_path and os.path.exists(credentials_path):
                os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path
                logger.info(f"Using Google Vision credentials from file: {credentials_path}")

            self.client = vision.ImageAnnotatorClient()
            logger.info("Google Vision API initialized successfully")
        except Exception as e:
            logger.warning(f"Could not initialize Google Vision API: {e}. Detector will work in fallback mode.")
            self.available = False

    def _get_learned_mappings(self) -> Dict[str, str]:
        """
        Get learned mappings from database (with caching).
        Learned mappings take priority over static mappings.
        """
        from datetime import datetime, timedelta

        # Refresh cache every 5 minutes
        now = datetime.utcnow()
        if (GoogleVisionDetector._cache_timestamp is None or
                now - GoogleVisionDetector._cache_timestamp > timedelta(minutes=5)):
            try:
                from app.models import DetectionFeedback
                # Get all learned mappings with at least 1 correction
                learned = DetectionFeedback.get_all_learned_mappings(min_corrections=1)
                GoogleVisionDetector._learned_mappings_cache = {
                    label: data['ingredient']
                    for label, data in learned.items()
                }
                GoogleVisionDetector._cache_timestamp = now
                cache_size = len(GoogleVisionDetector._learned_mappings_cache)
                logger.debug(f"Refreshed learned mappings cache: {cache_size} entries")
            except Exception as e:
                logger.warning(f"Could not load learned mappings: {e}")
                GoogleVisionDetector._learned_mappings_cache = {}

        return GoogleVisionDetector._learned_mappings_cache

    def detect_from_bytes(self, image_bytes: bytes) -> List[Dict]:
        """
        Detect ingredients from image bytes using Google Vision

        Args:
            image_bytes: Image data as bytes

        Returns:
            List of detected ingredients with confidence scores
        """
        if not self.available or self.client is None:
            return []

        try:
            # Create Vision API image object
            image = vision.Image(content=image_bytes)

            # Perform label detection + object localization in a single API call
            features = [
                vision.Feature(type_=vision.Feature.Type.LABEL_DETECTION),
                vision.Feature(type_=vision.Feature.Type.OBJECT_LOCALIZATION),
            ]
            request = vision.AnnotateImageRequest(image=image, features=features)
            response = self.client.annotate_image(request=request)
            labels = response.label_annotations
            objects = response.localized_object_annotations

            detections = []

            # Process labels
            for label in labels:
                label_name = label.description.lower()
                confidence = label.score

                # Map to ingredient
                ingredient_name = self._map_to_ingredient(label_name)
                if ingredient_name:
                    detections.append({
                        'name': ingredient_name,
                        'confidence': confidence,
                        'bbox': [],  # Labels don't have bounding boxes
                        'google_label': label.description,
                        'source': 'label'
                    })

            # Process objects (they have locations)
            for obj in objects:
                obj_name = obj.name.lower()
                confidence = obj.score

                # Map to ingredient
                ingredient_name = self._map_to_ingredient(obj_name)
                if ingredient_name:
                    # Get bounding box
                    vertices = obj.bounding_poly.normalized_vertices
                    bbox = [
                        vertices[0].x, vertices[0].y,
                        vertices[2].x, vertices[2].y
                    ] if len(vertices) >= 3 else []

                    detections.append({
                        'name': ingredient_name,
                        'confidence': confidence,
                        'bbox': bbox,
                        'google_label': obj.name,
                        'source': 'object'
                    })

            # Remove duplicates (keep highest confidence)
            detections = self._remove_duplicates(detections)

            # Also include raw labels for debugging (not mapped to ingredients)
            # These help users understand what Vision API detected
            if not detections:
                # If no mapped ingredients found, include top raw labels for feedback
                for label in labels[:5]:  # Top 5 labels
                    detections.append({
                        'name': None,  # Not a known ingredient
                        'confidence': label.score,
                        'bbox': [],
                        'google_label': label.description,
                        'source': 'label_raw'
                    })

            return detections

        except Exception as e:
            logger.error(f"Error in Google Vision detection: {e}")
            return []

    @staticmethod
    def _is_valid_partial_match(key: str, label: str) -> bool:
        """
        Check if a partial match between key and label is valid.
        Requires both strings to be at least 4 chars and the shorter
        string to be at least 70% the length of the longer string,
        OR the shorter string appears as a whole word in the longer string.
        """
        if len(key) < 4 or len(label) < 4:
            return False

        shorter, longer = (key, label) if len(key) <= len(label) else (label, key)

        # Check whole-word boundary: shorter appears as a complete word in longer
        import re
        if re.search(r'\b' + re.escape(shorter) + r'\b', longer):
            return True

        # Length ratio check: avoid tiny substrings matching long keys
        if len(shorter) / len(longer) >= 0.7:
            return True

        return False

    def _map_to_ingredient(self, label: str) -> Optional[str]:
        """
        Map Google Vision label to ingredient name.
        Priority: Learned mappings > Static mappings

        Args:
            label: Label from Google Vision

        Returns:
            Ingredient name or None
        """
        label = label.lower().strip()

        # First, check learned mappings (user corrections take priority)
        learned_mappings = self._get_learned_mappings()
        if label in learned_mappings:
            logger.debug(f"Using learned mapping: {label} -> {learned_mappings[label]}")
            return learned_mappings[label]

        # Check partial matches in learned mappings (with guards)
        for key, value in learned_mappings.items():
            if (key in label or label in key) and self._is_valid_partial_match(key, label):
                logger.debug(f"Using learned partial mapping: {label} -> {value}")
                return value

        # Then check static mappings - Direct match
        if label in self.VISION_TO_INGREDIENT:
            return self.VISION_TO_INGREDIENT[label]

        # Partial match with guards (e.g., "fresh carrot" -> "carrot")
        for key, value in self.VISION_TO_INGREDIENT.items():
            if value is None:
                continue
            if (key in label or label in key) and self._is_valid_partial_match(key, label):
                return value

        return None

    def _remove_duplicates(self, detections: List[Dict]) -> List[Dict]:
        """
        Remove duplicate detections, keeping highest confidence for each ingredient

        Args:
            detections: List of detections

        Returns:
            Filtered list without duplicates
        """
        seen = {}
        unmapped = []
        for detection in detections:
            name = detection['name']
            if name is None:
                # Keep all unmapped detections — don't merge them
                unmapped.append(detection)
            elif name not in seen or detection['confidence'] > seen[name]['confidence']:
                seen[name] = detection

        return list(seen.values()) + unmapped

    def get_ingredient_names(self, detections: List[Dict]) -> List[str]:
        """
        Extract ingredient names from detections

        Args:
            detections: List of detection dictionaries

        Returns:
            List of unique ingredient names
        """
        return list(set(d['name'] for d in detections if d['name']))

    def get_high_confidence_ingredients(
        self,
        detections: List[Dict],
        min_confidence: float = 0.7
    ) -> List[str]:
        """
        Get ingredients with high confidence

        Args:
            detections: List of detections
            min_confidence: Minimum confidence threshold

        Returns:
            List of high-confidence ingredient names
        """
        return [
            d['name']
            for d in detections
            if d['name'] and d['confidence'] >= min_confidence
        ]
