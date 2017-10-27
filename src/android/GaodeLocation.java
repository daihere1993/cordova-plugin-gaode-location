package daihere.cordova.plugin;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.provider.Settings;
import android.telecom.Call;

public class GaodeLocation extends CordovaPlugin {

    public  Context context = null;
    // AMapLocationClient类对象
    public AMapLocationClient locationClient = null;
    // 定位参数
    public AMapLocationClientOption locationOption = null;
    // JS回掉接口对象
    public static CallbackContext cb = null;
    // 权限申请码
    private static final int PERMISSION_REQUEST_CODE = 500;
    // 需要进行检测的权限数组
    protected String[] needPermissions = {
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION
    };

    @Override
    protected void pluginInitialize() {
    }

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("getLocation")) {
            getLocation(args, callbackContext);
            return true;
        } else if (action.equals("configLocationManager")) {
            if (this.isNeedCheckPermissions(needPermissions)) {
                this.checkPermissions(needPermissions);
            } else {
                configLocationClient(args, callbackContext);
            }
            return true;
        }

        return false;
    }

    /**
     * 判断是否需要检测，防止不停的弹框
     */
    private boolean isNeedCheck = true;

    /**
     * 初始化locationClient
     * @param args
     * @param callbackContext
     */
    public void configLocationClient(final  CordovaArgs args, final CallbackContext callbackContext) {

        // 获取初始化定位参数
        JSONObject params;
        String appName;
        JSONObject androidPara = new JSONObject();
        try {
            params = args.getJSONObject(0);
            appName = params.has("appName") ? params.getString("appName") : "当前应用";
            androidPara = params.getJSONObject("android");
        } catch (JSONException e) {
            callbackContext.error("参数格式错误");
            return;
        }
        // 初始化Client
        locationClient = new AMapLocationClient(this.webView.getContext());
        // 初始化定位参数
        locationOption = getOption(androidPara, callbackContext);
        // 设置定位监听函数
        locationClient.setLocationListener(locationListener);

        callbackContext.success("初始化成功");
    }

    /**
     * 获取定位
     */
    public void getLocation(final CordovaArgs args, final CallbackContext callbackContext) {
        Boolean retGeo;
        JSONObject params;
        cb = callbackContext;

        try {
            params = args.getJSONObject(0);
            retGeo = params.has("retGeo") ? params.getBoolean("retGeo") : false;

            locationOption.setNeedAddress(retGeo);
            locationClient.setLocationOption(locationOption);
            locationClient.startLocation();
        } catch (JSONException e) {
            callbackContext.error("参数格式错误");
            return;
        }
    }

    /**
     * 定位监听函数
     */
    AMapLocationListener locationListener = new AMapLocationListener() {
        @Override
        public void onLocationChanged(AMapLocation location) {
            JSONObject locationInfo = null;
            if (null != location) {
                if (location.getErrorCode() == 0) {
                    try {
                        // 纬度
                        locationInfo.put("latitude", location.getLatitude());
                        // 经度
                        locationInfo.put("longitude", location.getLongitude());
                        // 国家
                        locationInfo.put("country", location.getCountry());
                        // 省
                        locationInfo.put("province", location.getProvince());
                        // 市
                        locationInfo.put("city", location.getCity());
                        // 区
                        locationInfo.put("district", location.getDistrict());
                        // 地址
                        locationInfo.put("address", location.getAddress());

                        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, locationInfo);
                        pluginResult.setKeepCallback(true);
                        cb.sendPluginResult(pluginResult);
                    } catch (JSONException e) {
                        cb.error("参数错误，请检查参数格式");
                    }
                } else {
                    StringBuffer sb = new StringBuffer();
                    sb.append("定位失败" + "\n");
                    sb.append("错误码" + location.getErrorCode() + "\n");
                    sb.append("错误信息" + location.getErrorInfo() + "\n");
                    sb.append("错误描述" + location.getLocationDetail() + "\n");
                }
            }
        }
    };


    /**
     * 初始化clientOption
     */
    private AMapLocationClientOption getOption(JSONObject params, CallbackContext callbackContext) {
        AMapLocationClientOption mOption = new AMapLocationClientOption();

        try {
            // 定位模式，默认为高精度
            AMapLocationMode mode = null;
            int modeCode = params.has("mode") ? params.getInt("mode") : 1;
            switch (modeCode) {
                case 1: mode = AMapLocationMode.Hight_Accuracy; break;
                case 2: mode = AMapLocationMode.Device_Sensors; break;
                case 3: mode = AMapLocationMode.Battery_Saving; break;
            }
            // 超时时间，仅在设备模式下无效，初始为30秒
            long timeOut = params.has("timeOut") ? params.getLong("timeOut") : 30000;
            // 是否单次定位，目前暂时只支持单次定位
            Boolean onceLocation = true;
            // 是否等待wife刷新
            Boolean onceLocationLatest = true;

            mOption.setLocationMode(mode);
            mOption.setHttpTimeOut(timeOut);
            mOption.setOnceLocation(onceLocation);
            mOption.setOnceLocationLatest(onceLocationLatest);

        } catch (JSONException e) {
            cb.error("参数错误，请检查参数格式");
        }

        return mOption;
    }

    /**
     *  启动应用的设置
     */
    private void startAppSettings() {
        Intent intent = new Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
//        intent.setData(Uri.parse("package:" + getPackageName()));
//        startActivity(intent);
    }

    /**
     * 检查权限
     */
    private void checkPermissions(String... permissions) {
        try {
            List<String> needRequestPermissionList = findNeedPermissions(permissions);
            if (null != needRequestPermissionList && needRequestPermissionList.size() > 0) {
                String[] array = needRequestPermissionList.toArray(new String[needRequestPermissionList.size()]);
                cordova.requestPermissions(this, PERMISSION_REQUEST_CODE, array);
            }
        } catch (Throwable e) {

        }
    }

    /**
     * 判断是否需要权限校验
     */
    private boolean isNeedCheckPermissions(String... permission) {
        List<String> needRequestPermissionList = findNeedPermissions(permission);
        if (null != needRequestPermissionList && needRequestPermissionList.size() > 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * 获取需要获取权限的集合
     */
    private  List<String> findNeedPermissions(String[] permissions) {
        List<String> needRequestPermissionList = new ArrayList<String>();
        try {
            for (String perm : permissions) {
                if (!cordova.hasPermission(perm)) {
                    needRequestPermissionList.add(perm);
                }
            }
        } catch (Throwable e) {

        }
        return needRequestPermissionList;
    }

    /**
     * 权限检测回调
     */
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] paramArrayOfInt) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (!verifyPermissions(paramArrayOfInt)) {
                showMissingPermissionDialog();
                isNeedCheck = false;
            }
        }
    }

    /**
     * 显示提示信息
     */
    private void showMissingPermissionDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("提示");
        builder.setMessage("当前应用缺少必要权限。\\n\\n请点击\\\"设置\\\"-\\\"权限\\\"-打开所需权限。");

        // 拒绝, 退出应用
        builder.setNegativeButton("取消",
                new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
//                        finish();
                    }
                });

        builder.setPositiveButton("设置",
                new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        startAppSettings();
                    }
                });

        builder.setCancelable(false);

        builder.show();
    }

    /**
     * 检测是否所有的权限都已经授权
     */
    private boolean verifyPermissions(int[] grantResults) {
        for (int result : grantResults) {
            if (result != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }
}
