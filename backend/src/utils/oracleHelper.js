const { executeProcedure, executeQuery } = require('../config/database');

// Helper to format procedure parameters for Oracle
const formatProcedureParams = (params) => {
  const formatted = {};
  Object.keys(params).forEach(key => {
    if (params[key] !== undefined && params[key] !== null) {
      formatted[key] = params[key];
    }
  });
  return formatted;
};

// Helper to handle procedure calls with OUT parameters
// outParams: { paramName: 'NUMBER' | 'VARCHAR2' | 'CURSOR' }
const callProcedure = async (procedureName, inParams = {}, outParams = {}) => {
  const result = await executeProcedure(procedureName, inParams, outParams);
  return result;
};

module.exports = {
  formatProcedureParams,
  callProcedure,
  executeQuery
};

