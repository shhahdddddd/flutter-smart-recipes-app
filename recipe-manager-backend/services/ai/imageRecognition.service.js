const { visionClient } = require('../../config/ai.config');
const logger = require('../../utils/logger');

class ImageRecognitionService {
  constructor() {
    this.client = visionClient;
  }

  async detectIngredientsFromImage(imageBuffer) {
    try {
      logger.info('Processing image for ingredient detection');
      
      const [result] = await this.client.objectLocalization({
        image: { content: imageBuffer.toString('base64') }
      });

      const [labelResult] = await this.client.labelDetection({
        image: { content: imageBuffer.toString('base64') }
      });

      const ingredients = this.extractFoodItems(result, labelResult);
      
      logger.info(`Detected ${ingredients.length} ingredients from image`);
      return ingredients;
    } catch (error) {
      logger.error('Google Vision API error:', error);
      throw new Error('Erreur lors de la reconnaissance d\'image');
    }
  }

  extractFoodItems(objects, labels) {
    const foodItems = new Set();

    const foodKeywords = [
      'apple', 'banana', 'tomato', 'carrot', 'potato', 'onion', 'garlic',
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'egg', 'milk', 'cheese', 'yogurt',
      'bread', 'rice', 'pasta', 'flour', 'sugar', 'salt', 'pepper', 'oil', 'butter',
      'lettuce', 'cucumber', 'bell pepper', 'broccoli', 'spinach', 'mushroom',
      'orange', 'lemon', 'lime', 'strawberry', 'grape', 'peach', 'pear',
      'avocado', 'cabbage', 'cauliflower', 'celery', 'corn', 'eggplant',
      'green bean', 'pea', 'radish', 'squash', 'zucchini',
      'almond', 'peanut', 'walnut', 'hazelnut',
      'bean', 'lentil', 'chickpea',
      'cinnamon', 'ginger', 'basil', 'oregano', 'parsley', 'thyme'
    ];

    objects.localizedObjectAnnotations?.forEach(object => {
      const name = object.name.toLowerCase();
      if (foodKeywords.some(keyword => name.includes(keyword))) {
        foodItems.add(this.formatIngredientName(object.name));
      }
    });

    labels.labelAnnotations?.forEach(label => {
      const name = label.description.toLowerCase();
      if (foodKeywords.some(keyword => name.includes(keyword))) {
        foodItems.add(this.formatIngredientName(label.description));
      }
    });

    return Array.from(foodItems);
  }

  formatIngredientName(name) {
    return name.charAt(0).toUpperCase() + name.slice(1).toLowerCase();
  }
}

module.exports = new ImageRecognitionService();