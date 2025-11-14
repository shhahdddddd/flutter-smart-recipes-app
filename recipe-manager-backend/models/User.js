const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  photoUrl: {
    type: String,
  },
  preferences: {
    diet: String,
    allergies: [String],
    excludedIngredients: [String],
    cookingTimePreference: String, // 'quick', 'medium', 'any'
    difficultyLevel: String, // 'easy', 'medium', 'hard'
  },
  healthProfile: {
    hasHealthIssues: {
      type: Boolean,
      default: false,
      required: true,
    },
    conditions: {
      type: [String],
      default: [],
      validate: {
        validator: function (value) {
          return Array.isArray(value);
        },
        message: 'Les conditions médicales doivent être un tableau',
      },
    },
    notes: {
      type: String,
      trim: true,
    },
    allergies: {
      type: [String],
      default: [],
    },
    intolerances: {
      type: [String],
      default: [],
    },
    weightManagementGoals: {
      type: [String],
      default: [],
    },
    digestiveIssues: {
      type: [String],
      default: [],
    },
    cholesterolConcerns: {
      type: [String],
      default: [],
    },
    kidneyHealthConcerns: {
      type: [String],
      default: [],
    },
    lifestylePreferences: {
      type: [String],
      default: [],
    },
    dietaryGoals: {
      type: [String],
      default: [],
    },
    optionalTags: {
      type: [String],
      default: [],
    },
    preferencesCompleted: {
      type: Boolean,
      default: false,
    },
  },
  history: [{
    recipe: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Recipe',
    },
    date: {
      type: Date,
      default: Date.now,
    },
  }],
  favorites: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Recipe',
  }]
}, {
  timestamps: true,
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);