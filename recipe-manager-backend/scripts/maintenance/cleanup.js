const { MongoClient } = require('mongodb');
const logger = require('../../utils/logger');

async function cleanupDatabase() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const database = client.db('recipe-manager');

    logger.info('🧹 Starting database cleanup...');

    const cleanupTasks = [
      // Supprimer les recettes AI générées il y a plus de 30 jours
      {
        collection: 'recipes',
        filter: { 
          isAIGenerated: true, 
          createdAt: { $lt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } 
        },
        description: 'Old AI-generated recipes'
      },
      // Supprimer les menus expirés
      {
        collection: 'menus',
        filter: { 
          endDate: { $lt: new Date() } 
        },
        description: 'Expired menus'
      },
      // Supprimer les avis sans contenu
      {
        collection: 'reviews',
        filter: { 
          $or: [
            { comment: { $exists: false } },
            { comment: '' },
            { comment: { $regex: /^\s*$/ } }
          ]
        },
        description: 'Empty reviews'
      }
    ];

    let totalCleaned = 0;

    for (const task of cleanupTasks) {
      try {
        const collection = database.collection(task.collection);
        const result = await collection.deleteMany(task.filter);
        totalCleaned += result.deletedCount;
        logger.info(`   ✅ ${task.description}: ${result.deletedCount} documents deleted`);
      } catch (error) {
        logger.warn(`   ⚠️  ${task.collection}: ${error.message}`);
      }
    }

    logger.info(`🎉 Cleanup completed! ${totalCleaned} total documents cleaned`);

  } catch (error) {
    logger.error('❌ Cleanup failed:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  cleanupDatabase()
    .then(() => {
      console.log('Cleanup completed successfully!');
      process.exit(0);
    })
    .catch(error => {
      console.error('Cleanup failed:', error);
      process.exit(1);
    });
}

module.exports = { cleanupDatabase };