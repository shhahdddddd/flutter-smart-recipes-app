module.exports = {
  jwt: {
    secret: process.env.JWT_SECRET || 'your-fallback-secret-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '30d'
  },
  bcrypt: {
    saltRounds: 10
  }
};