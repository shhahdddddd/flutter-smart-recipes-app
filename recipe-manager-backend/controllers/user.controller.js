const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

const User = require('../models/User');
const Recipe = require('../models/Recipe');
const { jwt: jwtConfig } = require('../config/auth.config');

const generateToken = (id) => {
  const secret = jwtConfig.secret;

  if (!secret) {
    throw new Error('JWT secret is not configured');
  }

  return jwt.sign({ id }, secret, {
    expiresIn: '30d',
  });
};

const coerceBoolean = (value) => {
  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'string') {
    return ['true', '1', 'yes'].includes(value.toLowerCase());
  }

  if (typeof value === 'number') {
    return value === 1;
  }

  return false;
};

const isArrayLike = (value) => Array.isArray(value) || typeof value === 'string';

const normalizeSelections = (input) => {
  if (!input) {
    return [];
  }

  const values = Array.isArray(input) ? input : [input];

  return values
    .map((item) => (typeof item === 'string' ? item.trim() : String(item)))
    .filter(Boolean);
};

const validateHealthProfilePayload = (payload, { requireHasHealthIssues = false } = {}) => {
  if (payload === null || payload === undefined) {
    return requireHasHealthIssues
      ? 'Le profil de santé est requis.'
      : null;
  }

  if (typeof payload.hasHealthIssues === 'undefined' && requireHasHealthIssues) {
    return 'Le champ healthProfile.hasHealthIssues est requis.';
  }

  if (payload.conditions && !isArrayLike(payload.conditions)) {
    return 'Les conditions de santé doivent être un tableau ou une chaîne.';
  }

  const arraysToCheck = [
    'allergies',
    'intolerances',
    'chronicConditions',
    'weightManagementGoals',
    'digestiveIssues',
    'cholesterolConcerns',
    'kidneyHealthConcerns',
    'lifestylePreferences',
    'dietaryGoals',
    'optionalTags',
  ];

  for (const key of arraysToCheck) {
    if (payload[key] && !isArrayLike(payload[key])) {
      return `Le champ ${key} doit être un tableau ou une chaîne.`;
    }
  }

  const hasHealthIssues = coerceBoolean(payload.hasHealthIssues);

  if (hasHealthIssues && payload.conditions && normalizeSelections(payload.conditions).length === 0) {
    return 'Veuillez préciser au moins une condition de santé ou indiquer qu\'il n\'y en a pas.';
  }

  return null;
};

const normalizeHealthProfile = (payload = {}) => {
  const hasHealthIssues = coerceBoolean(payload.hasHealthIssues);

  const normalized = {
    hasHealthIssues,
    conditions: hasHealthIssues ? normalizeSelections(payload.conditions) : [],
    notes: typeof payload.notes === 'string' ? payload.notes.trim() : undefined,
    allergies: normalizeSelections(payload.allergies),
    intolerances: normalizeSelections(payload.intolerances),
    chronicConditions: normalizeSelections(payload.chronicConditions),
    weightManagementGoals: normalizeSelections(payload.weightManagementGoals),
    digestiveIssues: normalizeSelections(payload.digestiveIssues),
    cholesterolConcerns: normalizeSelections(payload.cholesterolConcerns),
    kidneyHealthConcerns: normalizeSelections(payload.kidneyHealthConcerns),
    lifestylePreferences: normalizeSelections(payload.lifestylePreferences),
    dietaryGoals: normalizeSelections(payload.dietaryGoals),
    optionalTags: normalizeSelections(payload.optionalTags),
    preferencesCompleted: coerceBoolean(payload.preferencesCompleted),
  };

  if (!normalized.notes) {
    delete normalized.notes;
  }

  return normalized;
};

exports.registerUser = async (req, res) => {
  try {
    const { name, email, password, healthProfile: rawHealthProfile } = req.body;

    const healthProfileError = validateHealthProfilePayload(rawHealthProfile);
    if (healthProfileError) {
      return res.status(400).json({
        error: healthProfileError
      });
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        error: 'Un utilisateur avec cet email existe déjà'
      });
    }

    const healthProfile = normalizeHealthProfile(rawHealthProfile);

    const user = await User.create({
      name,
      email,
      password,
      healthProfile,
    });

    res.status(201).json({
      success: true,
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        token: generateToken(user._id),
        healthProfile: user.healthProfile,
        favorites: user.favorites,
      },
    });
  } catch (error) {
    console.error('Erreur inscription:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'inscription'
    });
  }
};

exports.uploadUserPhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Aucune image fournie',
      });
    }

    const userId = req.user._id.toString();

    const uploadsDir = path.join(__dirname, '..', 'uploads', 'profile');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const mime = req.file.mimetype || '';
    let ext = 'jpg';
    if (mime === 'image/png') {
      ext = 'png';
    } else if (mime === 'image/jpeg' || mime === 'image/jpg') {
      ext = 'jpg';
    }

    const filename = `${userId}.${ext}`;
    const filePath = path.join(uploadsDir, filename);

    fs.writeFileSync(filePath, req.file.buffer);

    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 5000}`;
    const photoUrl = `${baseUrl}/uploads/profile/${filename}`;

    const user = await User.findByIdAndUpdate(
      userId,
      { photoUrl },
      { new: true }
    ).select('-password');

    return res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error('Erreur upload photo profil:', error);
    return res.status(500).json({
      success: false,
      error: 'Erreur lors du téléchargement de la photo de profil',
    });
  }
};

exports.getUserRecipes = async (req, res) => {
  try {
    const recipes = await Recipe.find({ createdBy: req.user._id })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: recipes,
      count: recipes.length,
    });
  } catch (error) {
    console.error('Erreur récupération recettes utilisateur:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des recettes utilisateur',
    });
  }
};

exports.getUserFavorites = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate({
        path: 'favorites',
        populate: { path: 'createdBy', select: 'name email' },
      })
      .select('favorites');

    if (!user) {
      return res.status(404).json({
        error: 'Utilisateur non trouvé',
      });
    }

    res.json({
      success: true,
      data: user.favorites || [],
      count: user.favorites?.length || 0,
    });
  } catch (error) {
    console.error('Erreur récupération favoris utilisateur:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des favoris',
    });
  }
};

exports.addFavorite = async (req, res) => {
  try {
    const recipeId = req.params.id;
    const recipe = await Recipe.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({
        success: false,
        error: 'Recette non trouvée',
      });
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $addToSet: { favorites: recipe._id } },
      { new: true }
    ).select('favorites');

    res.json({
      success: true,
      data: user.favorites,
      count: user.favorites.length,
    });
  } catch (error) {
    console.error('Erreur ajout favori:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'ajout du favori',
    });
  }
};

exports.removeFavorite = async (req, res) => {
  try {
    const recipeId = req.params.id;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $pull: { favorites: recipeId } },
      { new: true }
    ).select('favorites');

    res.json({
      success: true,
      data: user.favorites,
      count: user.favorites.length,
    });
  } catch (error) {
    console.error('Erreur suppression favori:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression du favori',
    });
  }
};

exports.loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (user && (await user.matchPassword(password))) {
      res.json({
        success: true,
        data: {
          _id: user._id,
          name: user.name,
          email: user.email,
          token: generateToken(user._id),
          healthProfile: user.healthProfile,
          favorites: user.favorites,
        },
      });
    } else {
      res.status(401).json({
        error: 'Email ou mot de passe incorrect'
      });
    }
  } catch (error) {
    console.error('Erreur connexion:', error);
    res.status(500).json({
      error: 'Erreur lors de la connexion'
    });
  }
};

exports.getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error('Erreur récupération profil:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération du profil'
    });
  }
};

exports.updateUserProfile = async (req, res) => {
  try {
    const updatePayload = { ...req.body };

    if (Object.prototype.hasOwnProperty.call(updatePayload, 'healthProfile')) {
      const healthProfileError = validateHealthProfilePayload(updatePayload.healthProfile);
      if (healthProfileError) {
        return res.status(400).json({
          error: healthProfileError
        });
      }

      updatePayload.healthProfile = normalizeHealthProfile(updatePayload.healthProfile);
    }

    if (Object.prototype.hasOwnProperty.call(updatePayload, 'password')) {
      if (!updatePayload.password) {
        delete updatePayload.password;
      } else {
        const salt = await bcrypt.genSalt(10);
        updatePayload.password = await bcrypt.hash(updatePayload.password, salt);
      }
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updatePayload,
      { new: true, runValidators: true }
    ).select('-password');

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error('Erreur mise à jour profil:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour du profil'
    });
  }
};

exports.deleteUserAccount = async (req, res) => {
  try {
    const userId = req.user._id;

    // Delete all recipes created by this user
    await Recipe.deleteMany({ createdBy: userId });

    // Delete the user document itself
    await User.findByIdAndDelete(userId);

    res.json({
      success: true,
      message: 'Compte utilisateur et recettes associées supprimés avec succès',
    });
  } catch (error) {
    console.error('Erreur suppression compte utilisateur:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression du compte utilisateur',
    });
  }
};