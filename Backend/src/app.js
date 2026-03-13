const express = require("express");
const apis = require("./routes/apis.js");
const cors = require("cors");

const app = express();

// frontend: https://anonymous-chat-app-frontend-hrtx.onrender.com/
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api", apis);

module.exports = app;
