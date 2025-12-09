"""
Google Custom Search API Service for fetching food images
"""
import requests
from flask import current_app
import logging

logger = logging.getLogger(__name__)


class ImageSearchService:
    """Service for searching food images using Google Custom Search API"""

    BASE_URL = "https://www.googleapis.com/customsearch/v1"

    def __init__(self):
        self.api_key = None
        self.search_engine_id = None

    def _get_credentials(self):
        """Get API credentials from config"""
        if not self.api_key:
            self.api_key = current_app.config.get('GOOGLE_API_KEY', '')
        if not self.search_engine_id:
            self.search_engine_id = current_app.config.get('GOOGLE_SEARCH_ENGINE_ID', '')
        return bool(self.api_key and self.search_engine_id)

    def search_food_image(self, food_name: str, cuisine_type: str = None) -> str | None:
        """
        Search for a food image using Google Custom Search API

        Args:
            food_name: Name of the food/recipe
            cuisine_type: Optional cuisine type to improve search results

        Returns:
            URL of the image or None if not found
        """
        if not self._get_credentials():
            logger.warning("Google Custom Search API credentials not configured")
            return None

        try:
            # Build search query
            query = f"{food_name} food"
            if cuisine_type:
                query = f"{cuisine_type} {query}"

            params = {
                'key': self.api_key,
                'cx': self.search_engine_id,
                'q': query,
                'searchType': 'image',
                'imgType': 'photo',
                'imgSize': 'large',
                'safe': 'active',
                'num': 1,  # Get only the first result
            }

            response = requests.get(self.BASE_URL, params=params, timeout=10)
            response.raise_for_status()

            data = response.json()

            if 'items' in data and len(data['items']) > 0:
                image_url = data['items'][0].get('link')
                logger.info(f"Found image for '{food_name}': {image_url}")
                return image_url

            logger.info(f"No image found for '{food_name}'")
            return None

        except requests.exceptions.RequestException as e:
            logger.error(f"Error searching for image: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error in image search: {e}")
            return None

    def search_multiple_food_images(self, food_names: list, cuisine_type: str = None) -> dict:
        """
        Search for multiple food images

        Args:
            food_names: List of food/recipe names
            cuisine_type: Optional cuisine type

        Returns:
            Dictionary mapping food names to image URLs
        """
        results = {}
        for name in food_names:
            image_url = self.search_food_image(name, cuisine_type)
            if image_url:
                results[name] = image_url
        return results


# Singleton instance
image_search_service = ImageSearchService()
