"use strict";
/* 
  Test HTTP API
  non-dockerized
  run, DB, then run tests.
 */

/* import libs for tests*/
var assert = require('assert');
var chai = require('chai')
  , chaiHttp = require('chai-http');

/* Import the frontend server*/
var sc = require('../../server');
var server;

/* Setup needed test functions from chai*/
chai.use(chaiHttp);
var expect = chai.expect;

describe('HTTPTests', function() {

  before(done => {
  	/* start the socketCluster before tests*/
  	server = sc.socketCluster;
    server.on('ready', function () {
      done();
    });
  });

  after(done => {
    server.killWorkers();
    done();
  });

  /*All tests here*/
  describe('Testing /ping endpoint', function() {

  	it('should return "200"', function(done) {
      chai.request('http://localhost:8000')
      .get('/ping')
      .end(function(err, res) {
        expect(res).to.have.status(200);
        done();  
      });
    });

  	it('should return text/html; charset=utf-8', function(done) {
      chai.request('http://localhost:8000')
      .get('/ping')
      .end(function(err, res) {
        expect(res).to.be.html;
        done();  
      });
    });

  	it('should return "pong"', function(done) {
      chai.request('http://localhost:8000')
      .get('/ping')
      .end(function(err, res) {
        expect(res.text).to.equal('pong\n');
        done();  
      });
    });
  });
  /*end tests*/
});
