const multer = require('multer');
const { upload: uploadConfig } = require('../config/app.config');

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (uploadConfig.allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`Type de fichier non supporté. Types autorisés: ${uploadConfig.allowedMimeTypes.join(', ')}`), false);
  }
};

const upload = multer({
  storage,
  limits: {
    fileSize: uploadConfig.maxFileSize,
  },
  fileFilter,
});

// Error handling middleware for multer
const handleUploadError = (error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        error: 'Fichier trop volumineux. Taille maximale: 5MB'
      });
    }
  }
  
  if (error) {
    return res.status(400).json({
      success: false,
      error: error.message
    });
  }
  
  next();
};

module.exports = {
  upload,
  handleUploadError
};