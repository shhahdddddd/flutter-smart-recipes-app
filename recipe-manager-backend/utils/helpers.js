const { ObjectId } = require('mongodb');
const logger = require('./logger');

/**
 * Normalise une chaîne de caractères (supprime les accents, met en minuscule)
 */
const normalizeString = (str) => {
  if (!str || typeof str !== 'string') return '';
  
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
};

/**
 * Calcule la date d'expiration basée sur la date d'achat
 */
const calculateExpirationDate = (ingredient, purchaseDate) => {
  if (!ingredient.averageExpirationDays || !purchaseDate) return null;
  
  try {
    const expirationDate = new Date(purchaseDate);
    expirationDate.setDate(expirationDate.getDate() + ingredient.averageExpirationDays);
    return expirationDate;
  } catch (error) {
    logger.warn('Error calculating expiration date:', error);
    return null;
  }
};

/**
 * Valide un ObjectId MongoDB
 */
const isValidObjectId = (id) => {
  if (!id) return false;
  
  try {
    return ObjectId.isValid(id) && new ObjectId(id).toString() === id;
  } catch (error) {
    return false;
  }
};

/**
 * Formate une durée en minutes vers un format lisible
 */
const formatCookingTime = (minutes) => {
  if (!minutes || minutes < 1) return 'Rapide';
  
  if (minutes < 60) {
    return `${minutes} min`;
  }
  
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  
  if (remainingMinutes === 0) {
    return `${hours} h`;
  }
  
  return `${hours} h ${remainingMinutes} min`;
};

/**
 * Génère un slug à partir d'un titre
 */
const generateSlug = (title) => {
  if (!title) return '';
  
  return title
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9 -]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim();
};

/**
 * Calcule les informations nutritionnelles totales d'une recette
 */
const calculateRecipeNutrition = (ingredients) => {
  let totalCalories = 0;
  let totalProtein = 0;
  let totalCarbs = 0;
  let totalFat = 0;

  ingredients.forEach(ingredient => {
    if (ingredient.nutritionalInfo) {
      totalCalories += ingredient.nutritionalInfo.calories || 0;
      totalProtein += ingredient.nutritionalInfo.protein || 0;
      totalCarbs += ingredient.nutritionalInfo.carbs || 0;
      totalFat += ingredient.nutritionalInfo.fat || 0;
    }
  });

  return {
    calories: Math.round(totalCalories),
    protein: Math.round(totalProtein * 10) / 10,
    carbs: Math.round(totalCarbs * 10) / 10,
    fat: Math.round(totalFat * 10) / 10,
  };
};

/**
 * Pagine un tableau de résultats
 */
const paginateResults = (data, page = 1, limit = 10) => {
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  
  const results = data.slice(startIndex, endIndex);
  
  return {
    data: results,
    pagination: {
      current: page,
      limit,
      total: data.length,
      pages: Math.ceil(data.length / limit)
    }
  };
};

module.exports = {
  normalizeString,
  calculateExpirationDate,
  isValidObjectId,
  formatCookingTime,
  generateSlug,
  calculateRecipeNutrition,
  paginateResults
};