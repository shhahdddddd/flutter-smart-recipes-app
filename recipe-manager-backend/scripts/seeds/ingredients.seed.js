const { MongoClient, ObjectId } = require('mongodb');
const logger = require('../../utils/logger');

async function seedIngredients() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const database = client.db('recipe-manager');

    logger.info('🥕 Seeding ingredients...');

    const ingredients = [
      {
        _id: new ObjectId("617f1f77bcf86cd799439101"),
        name: 'Tomate',
        category: 'légume',
        unit: 'pièce',
        calories: 18,
        protein: 0.9,
        carbs: 3.9,
        fat: 0.2,
        createdAt: new Date()
      },
      {
        _id: new ObjectId("617f1f77bcf86cd799439102"),
        name: 'Oignon',
        category: 'légume',
        unit: 'pièce',
        calories: 40,
        protein: 1.1,
        carbs: 9.3,
        fat: 0.1,
        createdAt: new Date()
      },
      {
        _id: new ObjectId("617f1f77bcf86cd799439103"),
        name: 'Ail',
        category: 'légume',
        unit: 'gousse',
        calories: 4,
        protein: 0.2,
        carbs: 1.0,
        fat: 0.0,
        createdAt: new Date()
      },
      {
        _id: new ObjectId("617f1f77bcf86cd799439109"),
        name: 'Poulet',
        category: 'viande',
        unit: 'g',
        calories: 165,
        protein: 31.0,
        carbs: 0.0,
        fat: 3.6,
        createdAt: new Date()
      },
      {
        _id: new ObjectId("617f1f77bcf86cd799439113"),
        name: 'Riz blanc',
        category: 'féculent',
        unit: 'g',
        calories: 130,
        protein: 2.7,
        carbs: 28.0,
        fat: 0.3,
        createdAt: new Date()
      },
      {
        _id: new ObjectId("617f1f77bcf86cd799439118"),
        name: 'Fromage râpé',
        category: 'produit-laitier',
        unit: 'g',
        calories: 402,
        protein: 25.0,
        carbs: 2.0,
        fat: 33.0,
        createdAt: new Date()
      },
      {
        _id: new ObjectId("617f1f77bcf86cd799439123"),
        name: 'Huile d\'olive',
        category: 'condiment',
        unit: 'ml',
        calories: 884,
        protein: 0,
        carbs: 0,
        fat: 100,
        createdAt: new Date()
      }
    ];

    // Vider la collection ingredients
    await database.collection('ingredients').deleteMany({});

    // Insérer les nouveaux ingrédients
    const result = await database.collection('ingredients').insertMany(ingredients);
    logger.info(`✅ ${result.insertedCount} ingredients inserted`);

    return result;

  } catch (error) {
    logger.error('❌ Ingredients seeding failed:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  seedIngredients()
    .then(result => {
      console.log(`Ingredients seeded: ${result.insertedCount} documents`);
      process.exit(0);
    })
    .catch(error => {
      console.error('Ingredients seeding failed:', error);
      process.exit(1);
    });
}

module.exports = { seedIngredients };