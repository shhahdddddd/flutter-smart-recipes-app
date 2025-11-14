const mongoose = require('mongoose');

const ingredientSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
  },
  category: {
    type: String,
    enum: ['vegetable', 'fruit', 'meat', 'dairy', 'grain', 'spice', 'other'],
    required: true,
  },
  image: String,
  averageExpirationDays: Number,
  nutritionalInfo: {
    calories: Number,
    protein: Number,
    carbs: Number,
    fat: Number,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Ingredient', ingredientSchema);