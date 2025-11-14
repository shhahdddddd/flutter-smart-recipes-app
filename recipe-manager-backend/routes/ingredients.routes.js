const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getIngredients,
  createIngredient,
  getIngredient,
  updateIngredient,
  deleteIngredient
} = require('../controllers/ingredient.controller');

router.route('/')
  .get(getIngredients)
  .post(protect, createIngredient);

router.route('/:id')
  .get(getIngredient)
  .put(protect, updateIngredient)
  .delete(protect, deleteIngredient);

module.exports = router;