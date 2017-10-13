package daihere.cordova.plugin;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.json.JSONException;
import org.json.JSONObject;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode;

import java.util.HashMap;

import android.os.Build;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;

public class GaodeLocation extends CordovaPlugin {

    protected JSONObject locationInfo = new JSONObject();
    protected  boolean isStartUpdateLocation = false;
    public  Context context = null;
    private static final boolean IS_AT_LEAST_LOLLIPOP = Build.VERSION.SDK_INT >= 21;

    public void startUpdateLocation(final  CordovaArgs args, final CallbackContext callbackContext) {
        context = IS_AT_LEAST_LOLLIPOP ? cordova.getActivity().getWindow().getContext() : cordova.getActivity().getApplicationContext();
        // 初始化Client
        final AMapLocationClient locationClient = new AMapLocationClient(context);
        // 获取初始化定位参数
        final JSONObject para;
        final String appName;
        JSONObject androidPara = new JSONObject();
        try {
            para = args.getJSONObject(0);

            if (!para.isNull("appName")) {
                appName = para.getString("appName");
            } else {
                appName = "当前应用";
            }

            if (!para.isNull("android")) {
                androidPara = para.getJSONObject("android");
            }
        } catch (JSONException e) {
            callbackContext.error("参数格式错误");
            return;
        }

        AMapLocationClientOption locationClientOption = getOption(androidPara, callbackContext);
        // 设置定位参数
        locationClient.setLocationOption(locationClientOption);
        // 设置定位监听
        locationClient.setLocationListener(new AMapLocationListener() {
            @Override
            public void onLocationChanged(AMapLocation location) {
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
                            callbackContext.success("success");

                        } catch (JSONException e) {
                            callbackContext.error("参数错误，请检查参数格式");
                        }
                    } else {
                        StringBuffer sb = new StringBuffer();
                        sb.append("定位失败" + "\n");
                        sb.append("错误码" + location.getErrorCode() + "\n");
                        sb.append("错误信息" + location.getErrorInfo() + "\n");
                        sb.append("错误描述" + location.getLocationDetail() + "\n");

                        if (location.getErrorCode() == 12) {
                            echo("缺少定位权限", "定位权限被禁用，请授予应用【" + appName + "】定位权限", "确定", context);
                        } else {
                            callbackContext.error(sb.toString());
                        }
                    }
                }
            }
        });

        locationClient.startLocation();
        this.isStartUpdateLocation = true;
    }

    public void echo(String title, String message, String buttonText, Context context) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title);
        builder.setMessage(message);
        builder.setCancelable(true);
        builder.setNegativeButton(buttonText, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });
        AlertDialog dialog=builder.create();
        dialog.show();
    }

    public void getLocation(final CordovaArgs args, final CallbackContext callbackContext) {
        if (this.isStartUpdateLocation) {
            callbackContext.success(locationInfo);
        } else {
            callbackContext.error("Please invoke 'startUpdateLocation' first.");
        }
    }

    private AMapLocationClientOption getOption(JSONObject para, CallbackContext callbackContext) {
        AMapLocationClientOption mOption = new AMapLocationClientOption();

        try {
            HashMap<String, AMapLocationMode> locationModeMap = new HashMap<String, AMapLocationMode>() {
                {
                    put("1", AMapLocationMode.Hight_Accuracy);
                    put("2", AMapLocationMode.Device_Sensors);
                    put("3", AMapLocationMode.Battery_Saving);
                }
            };

            // 设置定位模式，可选的模式由高精度、仅设备、仅网络。默认为高精度模式
            AMapLocationMode locationMode = AMapLocationMode.Hight_Accuracy;
            if (!para.isNull("locationMode")) {
                locationMode = locationModeMap.get(para.getString("locationMode"));
            }
            mOption.setLocationMode(locationMode);
            // 设置是否GPS优先，值在高精度模式下有效
            mOption.setGpsFirst(para.isNull("gpsFirst") ? true : para.getBoolean("gpsFirst"));
            // 设置网络请求超时时间，仅设备模式下无效
            long httpTimeout;
            if (para.isNull("httpTimeout")) {
                httpTimeout = 10000;
            } else {
                httpTimeout = para.getLong("httpTimeout");
            }
            mOption.setHttpTimeOut(httpTimeout);
            // 设置定位间隔
            long interval;
            if (para.isNull("interval")) {
                interval = 2000;
            } else {
                interval = para.getLong("interval");
            }
            mOption.setInterval(interval);
            // 设置是否返回逆地地理信息
            mOption.setNeedAddress(para.isNull("needAddress") ? false: para.getBoolean("needAddress"));
            // 设置是否单次定位
            mOption.setOnceLocation(para.isNull("onceLocation") ? false : para.getBoolean("onceLocation"));
            // 设置是否等待wifi刷新，如果是作为true，会自动变为单次定位，持续定位时不要使用
            mOption.setOnceLocationLatest(para.isNull("onceLocationLatest") ? false : para.getBoolean("onceLocationLatest"));
            // 设置网络请求协议，可选HTTP或者HTTPS
            AMapLocationClientOption.AMapLocationProtocol locationProtocol = para.isNull("enableHtpps") ? AMapLocationClientOption.AMapLocationProtocol.HTTP : AMapLocationClientOption.AMapLocationProtocol.HTTPS;
            AMapLocationClientOption.setLocationProtocol(locationProtocol);
            // 设置是否开启wifi扫描，如果设置为false会同时停止主动刷新，停止以后完全依赖于系统刷新，定位为止可能存在误差
            mOption.setWifiScan(para.isNull("enableWifiScan") ? true : para.getBoolean("enableWifiScan"));
            // 设置是否使用缓存定位
            mOption.setLocationCacheEnable(para.isNull("enableLocationCache") ? true : para.getBoolean("enableLocationCache"));
        } catch (JSONException e) {
            callbackContext.error("参数格式错误");
        }

        return mOption;
    }

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("getLocation")) {
            getLocation(args, callbackContext);
            return true;
        } else if (action.equals("startUpdateLocation")) {
            startUpdateLocation(args, callbackContext);
            return true;
        }

        return false;
    }
}

