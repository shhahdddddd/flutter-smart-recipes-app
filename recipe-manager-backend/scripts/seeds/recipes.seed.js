const { MongoClient, ObjectId } = require('mongodb');
const logger = require('../../utils/logger');

async function seedRecipes() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const database = client.db('recipe-manager');

    logger.info('🍳 Seeding recipes...');

    // Récupérer les IDs des utilisateurs et ingrédients existants
    const users = await database.collection('users').find({}).toArray();
    const ingredients = await database.collection('ingredients').find({}).toArray();

    if (users.length === 0 || ingredients.length === 0) {
      throw new Error('Users and ingredients must be seeded first');
    }

    const recipes = [
      {
        _id: new ObjectId("707f1f77bcf86cd799439021"),
        title: "Poulet Rôti aux Herbes",
        description: "Un poulet rôti savoureux avec des herbes de Provence",
        image: "https://example.com/recipes/poulet-roti.jpg",
        preparationTime: 20,
        cookingTime: 90,
        difficulty: "moyen",
        servings: 6,
        category: "plat principal",
        cuisine: "française",
        userId: users[0]._id,
        
        instructions: [
          { step: 1, description: "Préchauffer le four à 200°C" },
          { step: 2, description: "Nettoyer et sécher le poulet" },
          { step: 3, description: "Frotter le poulet avec l'huile d'olive, le sel et le poivre" },
          { step: 4, description: "Insérer les gousses d'ail et les oignons dans la cavité" },
          { step: 5, description: "Enfourner pour 1h30 en arrosant régulièrement" },
          { step: 6, description: "Laisser reposer 10 minutes avant de servir" }
        ],
        
        ingredients: [
          { ingredientId: ingredients.find(i => i.name === 'Poulet')._id, name: "Poulet", quantity: 1500, unit: "g" },
          { ingredientId: ingredients.find(i => i.name === 'Oignon')._id, name: "Oignon", quantity: 2, unit: "pièce" },
          { ingredientId: ingredients.find(i => i.name === 'Ail')._id, name: "Ail", quantity: 4, unit: "gousse" },
          { ingredientId: ingredients.find(i => i.name === 'Huile d\'olive')._id, name: "Huile d'olive", quantity: 30, unit: "ml" }
        ],
        
        nutrition: {
          calories: 285,
          protein: 35,
          carbs: 2,
          fat: 15,
          fiber: 1
        },
        
        tags: ["familial", "festif", "traditionnel"],
        isAIGenerated: false,
        createdAt: new Date("2024-02-10"),
        updatedAt: new Date()
      }
    ];

    // Vider la collection recipes
    await database.collection('recipes').deleteMany({});

    // Insérer les nouvelles recettes
    const result = await database.collection('recipes').insertMany(recipes);
    logger.info(`✅ ${result.insertedCount} recipes inserted`);

    return result;

  } catch (error) {
    logger.error('❌ Recipes seeding failed:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  seedRecipes()
    .then(result => {
      console.log(`Recipes seeded: ${result.insertedCount} documents`);
      process.exit(0);
    })
    .catch(error => {
      console.error('Recipes seeding failed:', error);
      process.exit(1);
    });
}

module.exports = { seedRecipes };