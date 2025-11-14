const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { upload, handleUploadError } = require('../middleware/upload');
const { 
  validateRecipeGeneration, 
  validateMenuGeneration 
} = require('../middleware/validation');
const {
  generateRecipes,
  generateMenu,
  generateSmartSuggestions,
  detectIngredients,
} = require('../controllers/ai.controller');

router.post('/generate-recipes', 
  protect, 
  validateRecipeGeneration, 
  generateRecipes
);

router.post('/generate-menu', 
  protect, 
  validateMenuGeneration, 
  generateMenu
);

router.post('/smart-suggestions',
  protect,
  validateMenuGeneration,
  generateSmartSuggestions
);

router.post('/detect-ingredients', 
  upload.single('image'), 
  handleUploadError,
  detectIngredients
);

module.exports = router;