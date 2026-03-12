const express = require("express");
const apis = require("./routes/apis.js");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api", apis);

module.exports = app;
