const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  console.error('Error details:', {
    message: err.message,
    errorNum: err.errorNum,
    code: err.code,
    statusCode: err.statusCode
  });
  
  // Oracle error handling
  if (err.errorNum || err.code) {
    // Check for Oracle application errors (RAISE_APPLICATION_ERROR)
    if (err.errorNum && err.errorNum >= 20000 && err.errorNum <= 20999) {
      return res.status(400).json({
        success: false,
        message: err.message || 'Database error occurred',
        error: err.message
      });
    }
    
    return res.status(400).json({
      success: false,
      message: err.message || 'Database error occurred',
      error: err.message
    });
  }
  
  // Application error
  if (err.statusCode) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message || 'An error occurred',
      error: err.message
    });
  }
  
  // Default error
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
};

module.exports = errorHandler;



