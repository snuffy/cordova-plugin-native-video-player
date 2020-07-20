'use strict';

var exec = require('cordova/exec'); // cordova exec


var _NativeVideoPlayer = {
  start: function start(onSuccess, onFail, param) {
    return exec(onSuccess, onFail, 'NativeVideoPlayer', 'start', [param]);
  },
  stop: function stop(onSuccess, onFail, param) {
    return exec(onSuccess, onFail, 'NativeVideoPlayer', 'stop', [param]);
  }
}; // Promise wrapper

var NativeVideoPlayer = {
  start: function start(params) {
    return new Promise(function (resolve, reject) {
      _NativeVideoPlayer.start(function (res) {
        resolve(res);
      }, function (err) {
        reject(err);
      }, params);
    });
  },
  stop: function stop(params) {
    return new Promise(function (resolve, reject) {
      _NativeVideoPlayer.stop(function (res) {
        resolve(res);
      }, function (err) {
        reject(err);
      }, params);
    });
  }
};
module.exports = NativeVideoPlayer;