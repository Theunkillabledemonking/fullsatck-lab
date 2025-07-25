'use strict';

var express = require('express');

var app = (module.exports = express());

app.use('/api/v1', require('./controllers/api_v1.js'));
app.use('/api/v2', require('./controllers/api_v2.js'));

app.get('/', function (req, res) {
  res.send('Hello from root route');
});

/* istanbul ignore next */
if (!module.parent) {
  app.listen(3000);
  console.log('Express started on port 3000');
}
