/*
 * @Author: 玖叁(N.T) 
 * @Date: 2017-10-25 17:12:55 
 * @Last Modified by: 玖叁(N.T)
 * @Last Modified time: 2017-10-29 13:24:06
 */
var exec = require('cordova/exec');

function isFunction(fn) {
    return Object.prototype.toString.call(fn)=== '[object Function]';
}

module.exports = {
    configLocation: function (param, success) {
        param = param || { };
        param.android = param.android || { };
        param.ios = param.ios || { };

        exec(success, null, "GaodeLocation", "configLocationManager", [param]);
    },
    getLocation: function(param, success, error) {
        if (isFunction(param)) {
            success = param;
            error = success;
            param = null;
        }
        param = param || { retGeo: false };
        exec(success, error, "GaodeLocation", "getLocation", [param]);
    }
};
