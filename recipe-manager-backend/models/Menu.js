const mongoose = require('mongoose');

const menuSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: String,
  duration: { // in days
    type: Number,
    required: true,
  },
  startDate: {
    type: Date,
    required: true,
  },
  meals: [{
    day: Number, // 1, 2, 3, ... up to duration
    mealType: {
      type: String,
      enum: ['breakfast', 'lunch', 'dinner', 'snack'],
    },
    recipe: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Recipe',
    },
  }],
  shoppingList: [{
    ingredient: String,
    quantity: String,
    purchased: {
      type: Boolean,
      default: false,
    },
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Menu', menuSchema);