var exec = require('cordova/exec');

module.exports = {
    startUpdateLocation: function (para, success, error) {
        if (Object.prototype.toString.call(para)=== '[object Function]') {
            successFn = para;
            errorFn = success;
            para = {};
        } else {
            successFn = success;
            errorFn = error;
        }
        // 将iOS时间相关的属性改成秒为单位
        var keys = ['locationTimeout', 'reGeocodeTimeout'];
        for (var i = 0; i < keys.length; i++) {
            for(var key in para) {
                if (key === keys[i]) {
                    para[key] = para[key]/1000;
                    break;
                }
            }
        }
        exec(successFn, errorFn, "GaodeLocation", "startUpdateLocation", [para]);
    },
    getLocation: function(success, error) {
        exec(success, error, "GaodeLocation", "getLocation", []);
    }
};
