/**
 * Cloud Function Gen 2 de ejemplo para pruebas Terratest.
 * Entry point: helloWorld
 * Compatible con Functions Framework
 */
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.set('Content-Type', 'application/json');
  res.status(200).send(
    JSON.stringify({
      message: 'success',
      status: 'ok',
      generation: '2nd'
    })
  );
});
