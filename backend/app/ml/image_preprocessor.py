"""
Image Preprocessing Module
Handles image loading, resizing, normalization, and augmentation for ML models
"""
from __future__ import annotations

import os
from typing import Tuple, Optional

try:
    import cv2
    import numpy as np
    CV2_AVAILABLE = True
except ImportError:
    cv2 = None
    np = None
    CV2_AVAILABLE = False


class ImagePreprocessor:
    """Handles all image preprocessing for ingredient detection"""

    def __init__(self, target_size: Tuple[int, int] = (640, 640)):
        """
        Initialize image preprocessor

        Args:
            target_size: Target image size for YOLO model (width, height)
        """
        self.target_size = target_size

    def load_image(self, image_path: str) -> Optional[np.ndarray]:
        """
        Load image from file path

        Args:
            image_path: Path to image file

        Returns:
            Numpy array of image in RGB format, or None if error
        """
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image not found: {image_path}")

        try:
            # Load with OpenCV (BGR format)
            img = cv2.imread(image_path)
            if img is None:
                raise ValueError(f"Failed to load image: {image_path}")

            # Convert BGR to RGB
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            return img_rgb
        except Exception as e:
            print(f"Error loading image: {e}")
            return None

    def load_image_from_bytes(self, image_bytes: bytes) -> Optional[np.ndarray]:
        """
        Load image from bytes (for uploaded files)

        Args:
            image_bytes: Image data as bytes

        Returns:
            Numpy array of image in RGB format, or None if error
        """
        try:
            # Convert bytes to numpy array
            nparr = np.frombuffer(image_bytes, np.uint8)
            # Decode image
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img is None:
                raise ValueError("Failed to decode image bytes")

            # Convert BGR to RGB
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            return img_rgb
        except Exception as e:
            print(f"Error loading image from bytes: {e}")
            return None

    def resize_image(self, image: np.ndarray, maintain_aspect: bool = True) -> np.ndarray:
        """
        Resize image to target size

        Args:
            image: Input image as numpy array
            maintain_aspect: Whether to maintain aspect ratio with padding

        Returns:
            Resized image
        """
        if not maintain_aspect:
            return cv2.resize(image, self.target_size)

        # Calculate scaling factor to maintain aspect ratio
        h, w = image.shape[:2]
        target_w, target_h = self.target_size

        scale = min(target_w / w, target_h / h)
        new_w = int(w * scale)
        new_h = int(h * scale)

        # Resize image
        resized = cv2.resize(image, (new_w, new_h))

        # Create padded image
        padded = np.zeros((target_h, target_w, 3), dtype=np.uint8)

        # Calculate padding
        pad_w = (target_w - new_w) // 2
        pad_h = (target_h - new_h) // 2

        # Place resized image in center
        padded[pad_h:pad_h+new_h, pad_w:pad_w+new_w] = resized

        return padded

    def normalize_image(self, image: np.ndarray) -> np.ndarray:
        """
        Normalize image pixel values to [0, 1]

        Args:
            image: Input image

        Returns:
            Normalized image
        """
        return image.astype(np.float32) / 255.0

    def enhance_image(self, image: np.ndarray) -> np.ndarray:
        """
        Enhance image quality (brightness, contrast, sharpness)

        Args:
            image: Input image

        Returns:
            Enhanced image
        """
        # Convert to LAB color space
        lab = cv2.cvtColor(image, cv2.COLOR_RGB2LAB)

        # Apply CLAHE (Contrast Limited Adaptive Histogram Equalization) to L channel
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        lab[:, :, 0] = clahe.apply(lab[:, :, 0])

        # Convert back to RGB
        enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)

        return enhanced

    def preprocess_for_yolo(self, image_path: str, enhance: bool = True) -> Optional[np.ndarray]:
        """
        Complete preprocessing pipeline for YOLO model

        Args:
            image_path: Path to image file
            enhance: Whether to apply image enhancement

        Returns:
            Preprocessed image ready for YOLO, or None if error
        """
        # Load image
        img = self.load_image(image_path)
        if img is None:
            return None

        # Enhance if requested
        if enhance:
            img = self.enhance_image(img)

        # Resize with aspect ratio
        img = self.resize_image(img, maintain_aspect=True)

        return img

    def preprocess_bytes_for_yolo(self, image_bytes: bytes, enhance: bool = True) -> Optional[np.ndarray]:
        """
        Complete preprocessing pipeline for YOLO from bytes

        Args:
            image_bytes: Image data as bytes
            enhance: Whether to apply image enhancement

        Returns:
            Preprocessed image ready for YOLO, or None if error
        """
        # Load image from bytes
        img = self.load_image_from_bytes(image_bytes)
        if img is None:
            return None

        # Enhance if requested
        if enhance:
            img = self.enhance_image(img)

        # Resize with aspect ratio
        img = self.resize_image(img, maintain_aspect=True)

        return img

    def save_image(self, image: np.ndarray, output_path: str) -> bool:
        """
        Save preprocessed image to file

        Args:
            image: Image to save
            output_path: Output file path

        Returns:
            True if successful, False otherwise
        """
        try:
            # Convert RGB to BGR for OpenCV
            img_bgr = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
            cv2.imwrite(output_path, img_bgr)
            return True
        except Exception as e:
            print(f"Error saving image: {e}")
            return False
