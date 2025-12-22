const oracledb = require('oracledb');
require('dotenv').config();

// Oracle connection pool configuration
let pool;

const initPool = async () => {
  try {
    // Build connection string - Oracle XE format
    // For Oracle XE in Docker, use: host:port/service_name
    let connectString = process.env.DB_CONNECT_STRING;
    
    if (!connectString) {
      // Build from components
      const host = process.env.DB_HOST || 'localhost';
      const port = process.env.DB_PORT || '1521';
      const service = process.env.DB_SERVICE || 'XE';
      connectString = `${host}:${port}/${service}`;
    }
    
    console.log('Connecting to Oracle database...');
    console.log('User:', process.env.DB_USER);
    console.log('Connect String:', connectString);
    console.log('Service:', process.env.DB_SERVICE);
    
    if (!process.env.DB_USER || !process.env.DB_PASSWORD) {
      throw new Error('DB_USER and DB_PASSWORD must be set in .env file');
    }
    
    // Try creating pool with explicit connection string format
    pool = await oracledb.createPool({
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      connectString: connectString,
      poolMin: 1,
      poolMax: 5,
      poolIncrement: 1,
      poolTimeout: 60,
      // Additional options for Oracle XE
      poolAlias: 'logitrack-pool'
    });
    console.log('Oracle connection pool created successfully');
  } catch (err) {
    console.error('Error creating Oracle connection pool:', err);
    throw err;
  }
};

const getPool = () => {
  if (!pool) {
    throw new Error('Connection pool not initialized. Call initPool() first.');
  }
  return pool;
};

// Helper function to execute Oracle procedures
// params: { inParams: {...}, outParams: {...} }
// outParams should specify type: 'NUMBER' | 'VARCHAR2' | 'CURSOR'
const executeProcedure = async (procedureName, inParams = {}, outParams = {}) => {
  const pool = getPool();
  let connection;
  
  try {
    connection = await pool.getConnection();
    
    // Build bind variables
    const binds = {};
    const paramList = [];
    
    // Add IN parameters
    Object.keys(inParams).forEach(key => {
      binds[key] = inParams[key];
      paramList.push(`:${key}`);
    });
    
    // Add OUT parameters
    Object.keys(outParams).forEach(key => {
      const outType = outParams[key];
      if (outType === 'CURSOR') {
        binds[key] = { dir: oracledb.BIND_OUT, type: oracledb.CURSOR };
      } else if (outType === 'VARCHAR2') {
        binds[key] = { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 32767 };
      } else {
        binds[key] = { dir: oracledb.BIND_OUT, type: oracledb.NUMBER };
      }
      paramList.push(`:${key}`);
    });
    
    // Build procedure call
    const sql = `BEGIN ${procedureName}(${paramList.join(', ')}); END;`;
    
    // Execute procedure
    const executeResult = await connection.execute(sql, binds, {
      autoCommit: true  // Auto-commit DML statements
    });
    
    // Extract OUT parameters
    // In oracledb, OUT parameters are returned in result.outBinds
    const result = {};
    if (executeResult.outBinds) {
      // OUT parameters are in outBinds object
      for (const key of Object.keys(outParams)) {
        if (outParams[key] === 'CURSOR') {
          const resultSet = executeResult.outBinds[key];
          result[key] = await resultSet.getRows();
        } else {
          result[key] = executeResult.outBinds[key];
        }
      }
    } else if (Object.keys(outParams).length > 0) {
      // Fallback: try to get from binds object (older oracledb versions)
      for (const key of Object.keys(outParams)) {
        if (outParams[key] === 'CURSOR') {
          const resultSet = binds[key];
          result[key] = await resultSet.getRows();
        } else {
          result[key] = binds[key];
        }
      }
    }
    
    // Debug logging
    if (Object.keys(outParams).length > 0) {
      console.log(`Procedure ${procedureName} OUT params:`, result);
    }
    
    return result;
  } catch (err) {
    console.error('Error executing procedure:', procedureName);
    console.error('Error details:', err.message);
    console.error('Error code:', err.errorNum || err.code);
    console.error('Parameters:', { inParams, outParams });
    throw err;
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

// Helper function to execute queries
const executeQuery = async (query, binds = {}, options = {}) => {
  const pool = getPool();
  let connection;
  
  try {
    connection = await pool.getConnection();
    const result = await connection.execute(query, binds, {
      outFormat: oracledb.OUT_FORMAT_OBJECT,
      autoCommit: options.autoCommit !== false  // Default to auto-commit
    });
    return result.rows;
  } catch (err) {
    console.error('Error executing query:', err);
    throw err;
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

// Close pool gracefully
const closePool = async () => {
  try {
    if (pool) {
      await pool.close();
      console.log('Oracle connection pool closed');
    }
  } catch (err) {
    console.error('Error closing pool:', err);
  }
};

module.exports = {
  initPool,
  getPool,
  executeProcedure,
  executeQuery,
  closePool
};

