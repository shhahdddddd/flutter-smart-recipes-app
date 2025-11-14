const { seedUsers } = require('../seeds/users.seed');
const { seedIngredients } = require('../seeds/ingredients.seed');
const { seedRecipes } = require('../seeds/recipes.seed');
const { seedMenus } = require('../seeds/menus.seed');
const logger = require('../../utils/logger');

async function seedDatabase() {
  try {
    logger.info('🚀 Starting complete database seeding...');

    // Exécuter les seeds dans l'ordre
    await seedUsers();
    await seedIngredients();
    await seedRecipes();
    await seedMenus();

    logger.info('✅ All seeds completed successfully!');

  } catch (error) {
    logger.error('❌ Database seeding failed:', error);
    throw error;
  }
}

// Exécuter seulement si appelé directement
if (require.main === module) {
  seedDatabase()
    .then(() => {
      console.log('Database seeded successfully!');
      process.exit(0);
    })
    .catch(error => {
      console.error('Seeding failed:', error);
      process.exit(1);
    });
}

module.exports = { seedDatabase };