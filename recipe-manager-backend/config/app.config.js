module.exports = {
  app: {
    name: 'Recipe Manager API',
    version: '1.0.0',
    port: process.env.PORT || 3000,
    environment: process.env.NODE_ENV || 'development'
  },
  upload: {
    maxFileSize: 5 * 1024 * 1024, // 5MB
    allowedMimeTypes: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
  },
  ai: {
    maxIngredients: 20,
    maxRecipes: 5
  }
};