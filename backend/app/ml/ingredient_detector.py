"""
Ingredient Detection Module
Uses YOLO model to detect ingredients from images
"""

import os
from typing import List, Dict, Optional
from ultralytics import YOLO
from .image_preprocessor import ImagePreprocessor


class IngredientDetector:
    """Handles ingredient detection using YOLO model"""

    # Mapping of YOLO COCO classes to Filipino ingredients
    # YOLO COCO dataset has 80 classes - only these food items are detectable:
    # apple, banana, orange, broccoli, carrot, hot dog, pizza, donut, cake, sandwich
    # Note: COCO doesn't have tomato, onion, garlic, meat etc. - those need a food-specific model
    YOLO_TO_INGREDIENT = {
        # Direct food mappings (keep it accurate, not guessing)
        'apple': 'Apple',  # If we have apple in DB, otherwise None
        'banana': 'Banana',  # If we have banana in DB, otherwise None
        'orange': 'Tomato',  # Round red items often detected as orange -> likely tomato
        'broccoli': 'Broccoli',  # Or map to Cabbage if no broccoli
        'carrot': 'Carrot',
        'hot dog': None,  # Skip - not a Filipino ingredient
        'pizza': None,  # Skip
        'donut': None,  # Skip
        'cake': None,  # Skip
        'sandwich': 'Bread',

        # Container items - DON'T map these to ingredients (causes wrong detections)
        'bottle': None,  # Could be anything
        'wine glass': None,
        'cup': None,  # Don't assume contents
        'bowl': None,  # Don't assume contents - THIS was causing Rice detection!

        # Kitchen items - skip
        'dining table': None,
        'fork': None,
        'knife': None,
        'spoon': None,
        'oven': None,
        'sink': None,
        'refrigerator': None,
        'microwave': None,
        'toaster': None,

        # Non-food items - skip all
        'person': None,
        'bird': None,  # Don't map bird to chicken - too inaccurate
        'dog': None,
        'cat': None,
        'potted plant': None,  # Don't guess
        'backpack': None,
        'umbrella': None,
        'handbag': None,
        'tie': None,
        'suitcase': None,
        'chair': None,
        'couch': None,
        'bed': None,
        'tv': None,
        'laptop': None,
        'mouse': None,
        'remote': None,
        'keyboard': None,
        'cell phone': None,
        'book': None,
        'clock': None,
        'vase': None,
        'scissors': None,
        'teddy bear': None,
        'hair drier': None,
        'toothbrush': None,
    }

    def __init__(self, model_path: str = 'models/yolov8n.pt', confidence_threshold: float = 0.5):
        """
        Initialize ingredient detector

        Args:
            model_path: Path to YOLO model file
            confidence_threshold: Minimum confidence score for detections
        """
        self.model_path = model_path
        self.confidence_threshold = confidence_threshold
        self.model = None
        self.preprocessor = ImagePreprocessor()

        # Load model if it exists
        if os.path.exists(model_path):
            self._load_model()

    def _load_model(self) -> bool:
        """
        Load YOLO model

        Returns:
            True if successful, False otherwise
        """
        try:
            print(f"Loading YOLO model from {self.model_path}...")
            self.model = YOLO(self.model_path)
            print("YOLO model loaded successfully")
            return True
        except Exception as e:
            print(f"Error loading YOLO model: {e}")
            self.model = None
            return False

    def download_model(self) -> bool:
        """
        Download YOLO model if not exists

        Returns:
            True if successful, False otherwise
        """
        try:
            # Create models directory if not exists
            os.makedirs('models', exist_ok=True)

            # Download YOLOv8n model (smallest, fastest)
            print("Downloading YOLOv8n model...")
            self.model = YOLO('yolov8n.pt')

            # Save to models directory
            os.rename('yolov8n.pt', self.model_path)
            print(f"Model saved to {self.model_path}")

            return True
        except Exception as e:
            print(f"Error downloading model: {e}")
            return False

    def detect_from_image_path(self, image_path: str, enhance: bool = True) -> List[Dict]:
        """
        Detect ingredients from image file

        Args:
            image_path: Path to image file
            enhance: Whether to enhance image before detection

        Returns:
            List of detected ingredients with confidence scores
            Format: [{'name': str, 'confidence': float, 'bbox': [x1, y1, x2, y2]}, ...]
        """
        if self.model is None:
            raise RuntimeError("YOLO model not loaded. Call download_model() first.")

        # Preprocess image
        processed_img = self.preprocessor.preprocess_for_yolo(image_path, enhance=enhance)
        if processed_img is None:
            raise ValueError(f"Failed to preprocess image: {image_path}")

        # Run detection
        results = self.model(processed_img, conf=self.confidence_threshold, verbose=False)

        # Parse results
        detections = self._parse_yolo_results(results)

        return detections

    def detect_from_bytes(self, image_bytes: bytes, enhance: bool = True) -> List[Dict]:
        """
        Detect ingredients from image bytes

        Args:
            image_bytes: Image data as bytes
            enhance: Whether to enhance image before detection

        Returns:
            List of detected ingredients with confidence scores
        """
        if self.model is None:
            raise RuntimeError("YOLO model not loaded. Call download_model() first.")

        # Preprocess image
        processed_img = self.preprocessor.preprocess_bytes_for_yolo(image_bytes, enhance=enhance)
        if processed_img is None:
            raise ValueError("Failed to preprocess image bytes")

        # Run detection
        results = self.model(processed_img, conf=self.confidence_threshold, verbose=False)

        # Parse results
        detections = self._parse_yolo_results(results)

        return detections

    def _parse_yolo_results(self, results) -> List[Dict]:
        """
        Parse YOLO detection results into ingredient list

        Args:
            results: YOLO detection results

        Returns:
            List of detected ingredients (includes ALL detections with mapping info)
        """
        detections = []

        # Process first result (single image)
        if len(results) > 0:
            result = results[0]

            # Get boxes, confidences, and class names
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    # Get class name
                    class_id = int(box.cls[0])
                    class_name = result.names[class_id].lower()

                    # Get confidence
                    confidence = float(box.conf[0])

                    # Get bounding box coordinates
                    bbox = box.xyxy[0].tolist()  # [x1, y1, x2, y2]

                    # Map to Filipino ingredient
                    ingredient_name = self._map_to_ingredient(class_name)

                    # Include ALL detections (even unmapped ones) for debugging
                    detections.append({
                        'name': ingredient_name,  # May be None if not mapped
                        'confidence': confidence,
                        'bbox': bbox,
                        'yolo_class': class_name
                    })

        # Remove duplicates (keep highest confidence for each ingredient)
        detections = self._remove_duplicates(detections)

        # Sort by confidence (highest first)
        detections.sort(key=lambda x: x['confidence'], reverse=True)

        return detections

    def _map_to_ingredient(self, yolo_class: str) -> Optional[str]:
        """
        Map YOLO class name to Filipino ingredient name

        Args:
            yolo_class: YOLO detected class name

        Returns:
            Filipino ingredient name or None if not found
        """
        return self.YOLO_TO_INGREDIENT.get(yolo_class)

    def _remove_duplicates(self, detections: List[Dict]) -> List[Dict]:
        """
        Remove duplicate ingredients, keeping highest confidence

        Args:
            detections: List of detections

        Returns:
            Deduplicated list
        """
        unique_detections = {}

        for det in detections:
            name = det['name']
            if name not in unique_detections:
                unique_detections[name] = det
            else:
                # Keep the one with higher confidence
                if det['confidence'] > unique_detections[name]['confidence']:
                    unique_detections[name] = det

        return list(unique_detections.values())

    def get_ingredient_names(self, detections: List[Dict]) -> List[str]:
        """
        Extract just the ingredient names from detections

        Args:
            detections: List of detection dictionaries

        Returns:
            List of ingredient names
        """
        return [det['name'] for det in detections]

    def get_high_confidence_ingredients(
        self,
        detections: List[Dict],
        min_confidence: float = 0.7
    ) -> List[str]:
        """
        Get only high-confidence ingredient detections

        Args:
            detections: List of detection dictionaries
            min_confidence: Minimum confidence threshold

        Returns:
            List of high-confidence ingredient names
        """
        return [
            det['name'] for det in detections
            if det['confidence'] >= min_confidence
        ]
