'use strict';

var express = require('express');

var apiv1 = express.Router();

apiv1.get('/', function (req, res) {
  res.send('Hello from APIv1 root route.');
  1;
});

apiv1.get('/users', function (req, res) {
  res.send('List of APIv1 users');
});

module.exports = apiv1;
