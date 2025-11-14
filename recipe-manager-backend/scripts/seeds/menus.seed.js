const { MongoClient, ObjectId } = require('mongodb');
const logger = require('../../utils/logger');

async function seedMenus() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const database = client.db('recipe-manager');

    logger.info('📅 Seeding menus...');

    // Récupérer les données existantes
    const users = await database.collection('users').find({}).toArray();
    const recipes = await database.collection('recipes').find({}).toArray();

    if (users.length === 0 || recipes.length === 0) {
      throw new Error('Users and recipes must be seeded first');
    }

    const menus = [
      {
        _id: new ObjectId("807f1f77bcf86cd799439031"),
        name: 'Menu Semaine Famille',
        description: 'Menu équilibré pour toute la famille',
        userId: users[0]._id,
        startDate: new Date('2024-03-01'),
        endDate: new Date('2024-03-07'),
        
        recipes: [
          { 
            recipeId: recipes[0]._id, 
            title: recipes[0].title, 
            day: 'lundi', 
            mealType: 'dinner' 
          }
        ],
        
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ];

    // Vider la collection menus
    await database.collection('menus').deleteMany({});

    // Insérer les nouveaux menus
    const result = await database.collection('menus').insertMany(menus);
    logger.info(`✅ ${result.insertedCount} menus inserted`);

    return result;

  } catch (error) {
    logger.error('❌ Menus seeding failed:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  seedMenus()
    .then(result => {
      console.log(`Menus seeded: ${result.insertedCount} documents`);
      process.exit(0);
    })
    .catch(error => {
      console.error('Menus seeding failed:', error);
      process.exit(1);
    });
}

module.exports = { seedMenus };