const logger = require('../../utils/logger');

class GenericService {
  constructor() {
    this.defaultPagination = {
      page: 1,
      limit: 10,
      maxLimit: 100
    };
  }

  validatePagination(page, limit) {
    const pageNum = Math.max(1, parseInt(page) || this.defaultPagination.page);
    const limitNum = Math.min(
      this.defaultPagination.maxLimit, 
      Math.max(1, parseInt(limit) || this.defaultPagination.limit)
    );
    
    return { page: pageNum, limit: limitNum };
  }

  calculatePaginationSkip(page, limit) {
    const { page: validPage, limit: validLimit } = this.validatePagination(page, limit);
    return (validPage - 1) * validLimit;
  }

  formatResponse(data, pagination = null) {
    const response = {
      success: true,
      data,
      timestamp: new Date().toISOString()
    };

    if (pagination) {
      response.pagination = pagination;
    }

    return response;
  }

  formatError(error, message = 'Une erreur est survenue') {
    logger.error(`Service error: ${error.message}`);
    
    return {
      success: false,
      error: message,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = new GenericService();