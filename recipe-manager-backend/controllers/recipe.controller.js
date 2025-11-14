const Recipe = require('../models/Recipe');

exports.getRecipes = async (req, res) => {
  try {
    const recipes = await Recipe.find().populate('createdBy', 'name email');
    res.json({
      success: true,
      data: recipes,
      count: recipes.length,
    });
  } catch (error) {
    console.error('Erreur récupération recettes:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des recettes'
    });
  }
};

exports.getRecipe = async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id).populate('createdBy', 'name email');
    
    if (!recipe) {
      return res.status(404).json({
        error: 'Recette non trouvée'
      });
    }

    res.json({
      success: true,
      data: recipe,
    });
  } catch (error) {
    console.error('Erreur récupération recette:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération de la recette'
    });
  }
};

exports.createRecipe = async (req, res) => {
  try {
    const recipe = new Recipe({
      ...req.body,
      createdBy: req.user._id,
    });

    const savedRecipe = await recipe.save();
    res.status(201).json({
      success: true,
      data: savedRecipe,
    });
  } catch (error) {
    console.error('Erreur création recette:', error);
    res.status(500).json({
      error: 'Erreur lors de la création de la recette'
    });
  }
};

exports.searchRecipes = async (req, res) => {
  try {
    const {
      q,
      ingredients,
      category,
      difficulty,
      maxCookingTime,
      isAIGenerated,
    } = req.query;

    const filter = {};

    if (q) {
      const regex = new RegExp(q.trim(), 'i');
      filter.$or = [
        { title: regex },
        { description: regex },
        { tags: regex },
      ];
    }

    if (ingredients) {
      const list = Array.isArray(ingredients)
        ? ingredients
        : ingredients.split(',').map(item => item.trim()).filter(Boolean);
      if (list.length > 0) {
        filter['ingredients.name'] = { $in: list.map(item => new RegExp(item, 'i')) };
      }
    }

    if (category) {
      filter.category = category;
    }

    if (difficulty) {
      filter.difficulty = difficulty;
    }

    if (maxCookingTime) {
      const parsed = parseInt(maxCookingTime, 10);
      if (!Number.isNaN(parsed)) {
        filter.cookingTime = { $lte: parsed };
      }
    }

    if (typeof isAIGenerated !== 'undefined') {
      filter.isAIGenerated = ['true', '1', 'yes'].includes(String(isAIGenerated).toLowerCase());
    }

    const recipes = await Recipe.find(filter)
      .sort({ createdAt: -1 })
      .populate('createdBy', 'name email');

    res.json({
      success: true,
      data: recipes,
      count: recipes.length,
    });
  } catch (error) {
    console.error('Erreur recherche recettes:', error);
    res.status(500).json({
      error: 'Erreur lors de la recherche de recettes',
    });
  }
};

exports.updateRecipe = async (req, res) => {
  try {
    const recipe = await Recipe.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!recipe) {
      return res.status(404).json({
        error: 'Recette non trouvée'
      });
    }

    res.json({
      success: true,
      data: recipe,
    });
  } catch (error) {
    console.error('Erreur mise à jour recette:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour de la recette'
    });
  }
};

exports.deleteRecipe = async (req, res) => {
  try {
    const recipe = await Recipe.findByIdAndDelete(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        error: 'Recette non trouvée'
      });
    }

    res.json({
      success: true,
      message: 'Recette supprimée avec succès',
    });
  } catch (error) {
    console.error('Erreur suppression recette:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression de la recette'
    });
  }
};