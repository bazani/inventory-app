/* Test HTTP API for Dealers
   These tests are meant to run against a deployment of the app
   which means to run docker-compose up and then run the tests
   and then docker-compose stop/rm
*/

/* import libs for tests*/
r = require('rethinkdb');
var assert = require('assert');
var request = require('request');
var db = require('./dbutils');
var dbConnect = db.connect();

var apihost = process.env.FRONTEND_HOST || 'localhost'
var apiport = process.env.FRONTEND_PORT || 8000;

describe('HTTPTests for Dealerships', function() {

  /*All tests here*/
  describe('Testing /dealerships endpoint', function() {

    it('/dealerships should return "200"', function(done) {
      request.get('http://' + apihost + ':'+ apiport +'/dealerships', function (err, res, body){
        if (err) throw (err);
        assert.strictEqual(res.statusCode, 200);
        done();
      });
    });

    it('/dealerships should return the right amount of dealers in the db', function(done) {
      request.get('http://' + apihost + ':'+ apiport +'/dealerships', function (err, res, body){
        if (err) throw (err);
        var dealers = JSON.parse(res.body);
        dbConnect.then(function(conn) {
          r.table('Dealership').count().run(conn, function(err, results){
            assert.strictEqual(dealers.length, results, "same results from DB and HTTP response");
            conn.close();
            done();
          });
        }).error(function(error) {
          throw (error);
        });
      });
    });

  });
  /*end tests*/
});
