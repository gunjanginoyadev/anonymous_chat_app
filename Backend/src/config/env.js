const dotenv = require("dotenv");
dotenv.config();

function getEnv(key) {
 const value = process.env[key];
 if (!value) {
   throw new Error(`Missing env key: ${key}`);
 }
 return value;
}

module.exports = {
  PORT: getEnv("PORT"),
  JET_SECRET: getEnv("JET_SECRET"),
  JET_REFRESH_TOKEN_SECRET: getEnv("JET_REFRESH_TOKEN_SECRET"),
  MONGODB_URI: getEnv("MONGODB_URI"),
};