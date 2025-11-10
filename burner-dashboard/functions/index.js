const { onRequest } = require("firebase-functions/v2/https");
const next = require("next");

const app = next({
  dev: false,
  conf: { distDir: "../.next" }
});

const handle = app.getRequestHandler();

exports.nextjsFunc = onRequest(
  {
    region: "europe-west2",
    memory: "1GiB",
    timeoutSeconds: 60,
    maxInstances: 10
  },
  async (req, res) => {
    await app.prepare();
    return handle(req, res);
  }
);