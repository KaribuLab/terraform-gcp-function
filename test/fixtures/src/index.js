/**
 * Cloud Function de ejemplo para pruebas Terratest.
 * Entry point: helloWorld
 */
exports.helloWorld = (req, res) => {
  res.set('Content-Type', 'application/json');
  res.status(200).send(
    JSON.stringify({
      message: 'success',
      status: 'ok',
    })
  );
};
