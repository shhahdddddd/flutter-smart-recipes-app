const { MongoClient } = require('mongodb');
const logger = require('../../utils/logger');

async function resetDatabase() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const database = client.db('recipe-manager');

    logger.info('🗑️  Resetting database...');

    const collections = [
      'users', 'ingredients', 'recipes', 'menus', 
      'favorites', 'reviews', 'nutrition_plans', 'shopping_lists'
    ];

    let totalDeleted = 0;

    for (const collectionName of collections) {
      try {
        const collection = database.collection(collectionName);
        const result = await collection.deleteMany({});
        totalDeleted += result.deletedCount;
        logger.info(`   ✅ ${collectionName}: ${result.deletedCount} documents deleted`);
      } catch (error) {
        logger.warn(`   ⚠️  ${collectionName}: ${error.message}`);
      }
    }

    logger.info(`🎉 Database reset completed! ${totalDeleted} total documents deleted`);

  } catch (error) {
    logger.error('❌ Database reset failed:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  resetDatabase()
    .then(() => {
      console.log('Database reset successfully!');
      process.exit(0);
    })
    .catch(error => {
      console.error('Reset failed:', error);
      process.exit(1);
    });
}

module.exports = { resetDatabase };