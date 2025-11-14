const { MongoClient, ObjectId } = require('mongodb');
const logger = require('../../utils/logger');

async function seedUsers() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const database = client.db('recipe-manager');

    logger.info('👥 Seeding users...');

    const users = [
      {
        _id: new ObjectId("507f1f77bcf86cd799439011"),
        name: 'Sophie Martin',
        email: 'sophie.martin@email.com',
        password: '$2b$10$hashed_password_123',
        profilePicture: 'https://example.com/profiles/sophie.jpg',
        dietaryPreferences: ['végétarien', 'sans-lactose'],
        allergies: ['fruits à coque'],
        height: 165,
        weight: 60,
        fitnessGoals: 'maintenance',
        createdAt: new Date('2024-01-15'),
        updatedAt: new Date()
      },
      {
        _id: new ObjectId("507f1f77bcf86cd799439012"),
        name: 'Pierre Dubois',
        email: 'pierre.dubois@email.com',
        password: '$2b$10$hashed_password_456',
        profilePicture: 'https://example.com/profiles/pierre.jpg',
        dietaryPreferences: ['sans-gluten'],
        allergies: ['crustacés'],
        height: 180,
        weight: 75,
        fitnessGoals: 'musculation',
        createdAt: new Date('2024-01-20'),
        updatedAt: new Date()
      },
      {
        _id: new ObjectId("507f1f77bcf86cd799439013"),
        name: 'Marie Lambert',
        email: 'marie.lambert@email.com',
        password: '$2b$10$hashed_password_789',
        profilePicture: 'https://example.com/profiles/marie.jpg',
        dietaryPreferences: ['végan'],
        allergies: ['soja'],
        height: 170,
        weight: 58,
        fitnessGoals: 'perte de poids',
        createdAt: new Date('2024-02-01'),
        updatedAt: new Date()
      }
    ];

    // Vider la collection users
    await database.collection('users').deleteMany({});

    // Insérer les nouveaux utilisateurs
    const result = await database.collection('users').insertMany(users);
    logger.info(`✅ ${result.insertedCount} users inserted`);

    return result;

  } catch (error) {
    logger.error('❌ Users seeding failed:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  seedUsers()
    .then(result => {
      console.log(`Users seeded: ${result.insertedCount} documents`);
      process.exit(0);
    })
    .catch(error => {
      console.error('Users seeding failed:', error);
      process.exit(1);
    });
}

module.exports = { seedUsers };