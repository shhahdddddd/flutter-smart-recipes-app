const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { upload, handleUploadError } = require('../middleware/upload');
const {
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
  getUserRecipes,
  getUserFavorites,
  addFavorite,
  removeFavorite,
  deleteUserAccount,
  uploadUserPhoto,
} = require('../controllers/user.controller');

router.post('/register', registerUser);
router.post('/login', loginUser);

router.route('/profile')
  .get(protect, getUserProfile)
  .put(protect, updateUserProfile)
  .delete(protect, deleteUserAccount);

router.post(
  '/profile/photo',
  protect,
  upload.single('photo'),
  handleUploadError,
  uploadUserPhoto,
);

router.get('/recipes', protect, getUserRecipes);
router.get('/favorites', protect, getUserFavorites);
router.post('/favorites/:id', protect, addFavorite);
router.delete('/favorites/:id', protect, removeFavorite);

module.exports = router;