const { MongoClient } = require('mongodb');
const mongoose = require('mongoose');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/recipe-manager';

// Connection MongoDB native
const connectDB = async () => {
  try {
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ MongoDB connected successfully');
    return client.db('recipe-manager');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Connection Mongoose
const connectMongoose = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Mongoose connected successfully');
  } catch (error) {
    console.error('❌ Mongoose connection error:', error);
    process.exit(1);
  }
};

module.exports = {
  connectDB,
  connectMongoose,
  MONGODB_URI
};