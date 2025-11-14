const express = require('express');
const router = express.Router();
const { protect, optionalAuth } = require('../middleware/auth');
const { validateRecipe } = require('../middleware/validation');
const {
  getRecipes,
  getRecipe,
  createRecipe,
  updateRecipe,
  deleteRecipe,
  searchRecipes
} = require('../controllers/recipe.controller');

router.route('/')
  .get(optionalAuth, getRecipes)
  .post(protect, validateRecipe, createRecipe);

router.route('/search')
  .get(searchRecipes);

router.route('/:id')
  .get(optionalAuth, getRecipe)
  .put(protect, validateRecipe, updateRecipe)
  .delete(protect, deleteRecipe);

module.exports = router;