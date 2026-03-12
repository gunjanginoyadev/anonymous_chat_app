const apiResponse = (res, statusCode, success, message, data) => {
  return res.status(statusCode).json({
    success,
    message,
    data,
  });
};

const successResponse = (res, message, data) => {
  return apiResponse(res, 200, true, message, data);
};

const createdResponse = (res, message, data) => {
  return apiResponse(res, 201, true, message, data);
};

const updatedResponse = (res, message, data) => {
  return apiResponse(res, 202, true, message, data);
};

const deletedResponse = (res, message, data) => {
  return apiResponse(res, 204, true, message, data);
};

const errorResponse = (res, message, data) => {
  return apiResponse(res, 400, false, message, data);
};

const unauthorizedResponse = (res, message, data) => {
  return apiResponse(res, 401, false, message, data);
};

const forbiddenResponse = (res, message, data) => {
  return apiResponse(res, 403, false, message, data);
};

const notFoundResponse = (res, message, data) => {
  return apiResponse(res, 404, false, message, data);
};

const serverErrorResponse = (res, message, data) => {
  return apiResponse(res, 500, false, message, data);
};

module.exports = {
  successResponse,
  createdResponse,
  updatedResponse,
  deletedResponse,
  unauthorizedResponse,
  forbiddenResponse,
  notFoundResponse,
  serverErrorResponse,
  errorResponse,
};
