package com.reactnativejarvistemplateappsdk.apis;

import android.util.Log;

import com.reactnativejarvistemplateappsdk.apis.response.ApplicationDetail;
import com.reactnativejarvistemplateappsdk.apis.response.DeviceFilter;
import com.reactnativejarvistemplateappsdk.apis.response.LocatingNotification;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

public class JarvisApi {

  private final String apiHost = "https://jarvis.viatick.com/apis";
  private final OkHttpClient httpClient = new OkHttpClient();

  private static final MediaType JSON_MEDIA_TYPE = MediaType.parse("application/json; charset=utf-8");

  private JarvisApi() {
  }

  public ApplicationDetail getApplicationDetail(String sdkKey) {
    Request request = new Request.Builder()
        .header("Access-Token", sdkKey)
        .url(apiHost + "/account/application/detail")
        .build();

    try {
      Response rp = this.httpClient.newCall(request).execute();

      if (rp.isSuccessful()) {
        String bodyResponse = rp.body().string();
        JSONObject responseObject = new JSONObject(bodyResponse);

        long id = responseObject.getLong("id");
        String name = responseObject.getString("name");
        String email = responseObject.getString("email");
        JSONObject deviceFilterJson = responseObject.getJSONObject("deviceFilter");
        JSONObject beaconFilterJson = deviceFilterJson.getJSONObject("attendance_beacon");
        String uuid = beaconFilterJson.getString("uuid");
        int major = beaconFilterJson.getInt("major");

        Map<String, DeviceFilter> deviceFilterMap = new HashMap<>();
        deviceFilterMap.put("attendance_beacon", new DeviceFilter(uuid, major));

        return new ApplicationDetail(id, name, email, deviceFilterMap);
      } else {
        Log.d("getApplicationDetail", "code" + rp.code());
      }
    } catch (IOException | JSONException e) {
      Log.e("JarvisApi", e.getLocalizedMessage());
    }

    return null;
  }

  public LocatingNotification findNotificationByDevice(String sdkKey, String uuid, int major, int minor) {
    JSONObject bodyJson = new JSONObject();
    try {
      bodyJson.put("uuid", uuid);
      bodyJson.put("major", major);
      bodyJson.put("minor", minor);
    } catch (JSONException e) {
      Log.e("JarvisApi", e.getLocalizedMessage());
    }

    RequestBody body = RequestBody.create(bodyJson.toString(), JSON_MEDIA_TYPE);
    Request request = new Request.Builder()
        .header("Access-Token", sdkKey)
        .url(apiHost + "/resource/locating-notification/find-by-device")
        .post(body)
        .build();

    try {
      Response rp = this.httpClient.newCall(request).execute();

      if (rp.isSuccessful()) {
        String bodyResponse = rp.body().string();
        JSONObject responseObject = new JSONObject(bodyResponse);

        long notificationId = responseObject.getLong("id");
        String title = responseObject.getString("title");
        String description = responseObject.getString("description");

        return new LocatingNotification(notificationId, title, description);
      } else {
        Log.d("findByDevice", "code" + rp.code());
      }
    } catch (IOException | JSONException e) {
      Log.e("JarvisApi", e.getLocalizedMessage());
    }

    return null;
  }

  public static JarvisApi getInstance() {
    return SingletonHelper.INSTANCE;
  }

  private static class SingletonHelper {
    private static final JarvisApi INSTANCE = new JarvisApi();
  }

}
