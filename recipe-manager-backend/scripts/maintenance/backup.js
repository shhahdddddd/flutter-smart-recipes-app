const { MongoClient } = require('mongodb');
const fs = require('fs');
const path = require('path');
const logger = require('../../utils/logger');

async function backupDatabase() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const database = client.db('recipe-manager');

    logger.info('💾 Starting database backup...');

    // Créer le dossier de backup s'il n'existe pas
    const backupDir = path.join(__dirname, '../../backups');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupFile = path.join(backupDir, `backup-${timestamp}.json`);

    const collections = [
      'users', 'ingredients', 'recipes', 'menus', 
      'favorites', 'reviews', 'nutrition_plans', 'shopping_lists'
    ];

    const backupData = {
      timestamp: new Date().toISOString(),
      database: 'recipe-manager',
      collections: {}
    };

    for (const collectionName of collections) {
      try {
        const collection = database.collection(collectionName);
        const documents = await collection.find({}).toArray();
        backupData.collections[collectionName] = documents;
        logger.info(`   ✅ ${collectionName}: ${documents.length} documents backed up`);
      } catch (error) {
        logger.warn(`   ⚠️  ${collectionName}: ${error.message}`);
      }
    }

    // Sauvegarder dans un fichier
    fs.writeFileSync(backupFile, JSON.stringify(backupData, null, 2));
    
    logger.info(`🎉 Backup completed! File: ${backupFile}`);
    return backupFile;

  } catch (error) {
    logger.error('❌ Backup failed:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  backupDatabase()
    .then(backupFile => {
      console.log(`Backup saved to: ${backupFile}`);
      process.exit(0);
    })
    .catch(error => {
      console.error('Backup failed:', error);
      process.exit(1);
    });
}

module.exports = { backupDatabase };