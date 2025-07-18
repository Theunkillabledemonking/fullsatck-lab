'use strict';

/**
 * 모듈 의존성
 */

var createError = require('http-errors');
var express = require('express');
var app = (module.exports = express());

// 임시사용자 데이터 베이스

var users = [
  { name: 'tj' },
  { name: 'tobi' },
  { name: 'loki' },
  { name: 'jane' },
  { name: 'bandit' },
];

// :to 와 :from 값을 정수로 변환

app.param(['to', 'from'], function (req, res, next, num, name) {
  req.params[name] = parseInt(num, 10);
  if (isNaN(req.params[name])) {
    next(createError(400, 'failed to parseInt ' + num));
  } else {
    next();
  }
});

// 사용자 ID로 사용자 객체 로드

app.param('user', function (req, res, next, id) {
  req.user = users[id];
  if (req.user) {
    next();
  } else {
    next(createError(404, 'failed to find user'));
  }
});

/**
 * GET index - 루트
 */

app.get('/', function (req, res) {
  res.send('Visit /user/0 or /users/0-2');
});

/**
 * GET :user.
 * 사용자 ID를 이용한 사용자 정보 조회
 */

app.get('/user/:user', function (req, res) {
  res.send('user ' + req.user.name);
});

/**
 * GET users :from - :to.
 * 여러 사용자 범위 조회
 */

app.get('/users/:from-:to', function (req, res) {
  var from = req.params.from;
  var to = req.params.to;
  var names = users.map(function (user) {
    return user.name;
  });
  res.send('users ' + names.slice(from, to + 1).join(', '));
});

/* istanbul ignore next */
if (!module.parent) {
  app.listen(3000);
  console.log('Express started on port 3000');
}
