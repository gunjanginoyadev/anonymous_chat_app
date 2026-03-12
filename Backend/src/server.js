const http = require("http");
const app = require("./app");
const connectDB = require("./config/db");
const initSocketServer = require("./socket/socket_server");
const env = require("./config/env");

async function startServer() {

  const server = http.createServer(app);

  connectDB().then(() => {
    initSocketServer(server);
    server.listen(env.PORT, () => {
      console.log(`Server running on port ${env.PORT}`);
    });
  });
}

startServer();
