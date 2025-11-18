const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: String,
  ingredients: [{
    name: String,
    quantity: String, // e.g., "1 cup", "2 tablespoons"
    note: String, // e.g., "chopped", "optional"
  }],
  instructions: [{
    step: Number,
    description: String,
  }],
  cookingTime: { // in minutes
    type: Number,
    required: true,
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'medium',
  },
  category: {
    type: String,
    enum: ['breakfast', 'lunch', 'dinner', 'dessert', 'snack'],
  },
  calories: Number,
  image: {
    type: String,
    default: process.env.DEFAULT_RECIPE_IMAGE_URL || 'https://images.unsplash.com/photo-1478144592103-25e218a04891?auto=format&fit=crop&w=800&q=80',
  },
  tags: [String],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  isAIGenerated: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Recipe', recipeSchema);