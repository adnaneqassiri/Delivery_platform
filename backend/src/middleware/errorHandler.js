const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  
  // Oracle error handling
  if (err.errorNum) {
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



