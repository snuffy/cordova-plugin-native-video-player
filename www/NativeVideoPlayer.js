'use strict';

var exec = require('cordova/exec');

// cordova exec
var _NativeVideoPlayer = {
  start: (onSuccess, onFail, param) => {
    return exec(onSuccess, onFail, 'NativeVideoPlayer', 'start', [param]);
  },
  stop: (onSuccess, onFail, param) => {
    return exec(onSuccess, onFail, 'NativeVideoPlayer', 'stop', [param]);
  },
};

// Promise wrapper
var NativeVideoPlayer = {
  start: (params) => {
    return new Promise((resolve, reject) => {
      _NativeVideoPlayer.start((res) => {
        resolve(res);
      }, (err) => {
        reject(err);
      }, params);
    });
  },
  stop: (params) => {
    return new Promise((resolve, reject) => {
      _NativeVideoPlayer.stop((res) => {
        resolve(res);
      }, (err) => {
        reject(err);
      }, params);
    });
  },
}

module.exports = NativeVideoPlayer;
