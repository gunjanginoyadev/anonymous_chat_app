const dotenv = require("dotenv");
dotenv.config();

function getEnv(key) {
 const value = process.env[key];
 if (!value) {
   throw new Error(`Missing env key: ${key}`);
 }
 return value;
}

function getEnvOptional(key, fallback = '') {
  return process.env[key] || fallback;
}

module.exports = {
  PORT: getEnv("PORT"),
  JET_SECRET: getEnv("JET_SECRET"),
  JET_REFRESH_TOKEN_SECRET: getEnv("JET_REFRESH_TOKEN_SECRET"),
  MONGODB_URI: getEnv("MONGODB_URI"),
  FRONTEND_BASE_URL: getEnvOptional("FRONTEND_BASE_URL", "http://localhost:64919"),
  EMAIL_SMTP_HOST: getEnv("EMAIL_SMTP_HOST"),
  EMAIL_SMTP_PORT: getEnv("EMAIL_SMTP_PORT"),
  EMAIL_SMTP_USERNAME: getEnv("EMAIL_SMTP_USERNAME"),
  EMAIL_SMTP_PASSWORD: getEnv("EMAIL_SMTP_PASSWORD"),
  EMAIL_SMTP_SECURE: getEnv("EMAIL_SMTP_SECURE"),
  EMAILJS_SERVICE_ID: getEnv("EMAILJS_SERVICE_ID"),
  EMAILJS_TEMPLATE_ID: getEnv("EMAILJS_TEMPLATE_ID"),
  EMAILJS_USER_ID: getEnv("EMAILJS_USER_ID"), 
  EMAILJS_ACCESS_TOKEN: getEnv("EMAILJS_ACCESS_TOKEN"),
};