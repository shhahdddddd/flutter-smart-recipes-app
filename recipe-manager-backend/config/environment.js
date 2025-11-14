require('dotenv').config();

module.exports = {
  // Database
  mongodbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager',
  
  // AI Services
  openaiApiKey: process.env.OPENAI_API_KEY,
  googleApplicationCredentials: process.env.GOOGLE_APPLICATION_CREDENTIALS,
  
  // Cloud Services
  cloudinaryCloudName: process.env.CLOUDINARY_CLOUD_NAME,
  cloudinaryApiKey: process.env.CLOUDINARY_API_KEY,
  cloudinaryApiSecret: process.env.CLOUDINARY_API_SECRET,
  
  // Security
  jwtSecret: process.env.JWT_SECRET,
  nodeEnv: process.env.NODE_ENV || 'development'
};