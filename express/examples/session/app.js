'use strict';

// install redis first:
// https://redis.io/

// then:
// $ npm install redis
// $ redis-server

var express = require('express');
var session = require('express-session');

var app = express();

// Populates req.session
app.use(
  session({
    resave: false, // don't save session if unmodified
    saveUninitialized: false, // don't create session until something stored
    secret: 'keyboard cat',
  }),
);

app.get('/', function (req, res) {
  var body = '';
  if (req.session.views) {
    ++req.session.views;
  } else {
    req.session.views = 1;
    body +=
      '<p>First new time visiting? view this page in several browser :)</p>';
  }
  res.send(body + '<p>view <strong>' + req.session.views + '</strong></p>');
});

/* istanbul ignore next */
if (!module.parent) {
  app.listen(3000);
  console.log('Express started on port 3000');
}
