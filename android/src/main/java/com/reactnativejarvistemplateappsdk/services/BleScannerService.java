package com.reactnativejarvistemplateappsdk.services;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.reactnativejarvistemplateappsdk.apis.JarvisApi;
import com.reactnativejarvistemplateappsdk.apis.response.ApplicationDetail;
import com.reactnativejarvistemplateappsdk.apis.response.DeviceFilter;
import com.reactnativejarvistemplateappsdk.apis.response.LocatingNotification;
import com.reactnativejarvistemplateappsdk.model.PeripheralDetail;
import com.reactnativejarvistemplateappsdk.utils.BleUtils;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class BleScannerService extends Service {

  private final static String CHANNEL_ID = "Jarvis_Rn_Sdk_Channel";
  private final static String DEVICE_CHANNEL_ID = "Jarvis_Rn_Device_Channel";

  private final static int SERVICE_NOTIFICATION_ID = 9999999;

  private ScanCallback scanCallback;

  private static BleScannerServiceCallback serviceDelegate;
  private static boolean running;
  private String sdkKey = "";
  private int locatingRange = 3;
  private int notificationIconResourceId = 0;
  private String serviceNotificationTitle = "Jarvis";
  private String serviceNotificationDescription = "SDK Running...";

  private final ConcurrentHashMap<String, PeripheralDetail> scannedBleMap = new ConcurrentHashMap<>();
  private final ScheduledThreadPoolExecutor poolExecutor = new ScheduledThreadPoolExecutor(2);

  public BleScannerService() {
  }

  @Nullable
  @Override
  public IBinder onBind(Intent intent) {
    return null;
  }

  @Override
  public void onCreate() {
    Log.d("BleScannerService", "onCreate");
    running = true;
    super.onCreate();
  }

  @Override
  public int onStartCommand(Intent intent, int flags, int startId) {
    Log.d("BleScannerService", "onStartCommand");
    this.sdkKey = intent.getStringExtra("sdkKey");
    this.locatingRange = intent.getIntExtra("locatingRange", 3);
    this.notificationIconResourceId = intent.getIntExtra("notificationIconResourceId", 1);
    this.serviceNotificationTitle = intent.getStringExtra("notificationTitle");
    this.serviceNotificationDescription = intent.getStringExtra("notificationDescription");

    this.createNotificationChannel();

    // If the notification supports a direct reply action, use
    // PendingIntent.FLAG_MUTABLE instead.
    Intent notificationIntent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
    PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);

    Notification notification;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      notification = new Notification.Builder(this, CHANNEL_ID).setContentTitle(this.serviceNotificationTitle)
          .setContentText(this.serviceNotificationDescription)
          .setSmallIcon(this.notificationIconResourceId)
          .setContentIntent(pendingIntent)
          .build();

    } else {
      notification = new NotificationCompat.Builder(this, CHANNEL_ID).setContentTitle(this.serviceNotificationTitle)
          .setContentText(this.serviceNotificationDescription)
          .setSmallIcon(this.notificationIconResourceId)
          .setContentIntent(pendingIntent)
          .build();
    }

    startForeground(SERVICE_NOTIFICATION_ID, notification);

    this.startScan();

    return START_STICKY;
  }

  private void startScan() {
    Log.d("BleScannerService", "startScan called");

    ScanSettings scanSettings = new ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .setMatchMode(ScanSettings.MATCH_MODE_AGGRESSIVE)
        .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
        .setNumOfMatches(ScanSettings.MATCH_NUM_MAX_ADVERTISEMENT)
        .setReportDelay(0)
        .build();

    boolean bluetoothScan = true;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      bluetoothScan = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED;
    }

    if (bluetoothScan) {
      this.scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
          onBleDiscovered(result);
        }
      };
      BluetoothLeScanner bluetoothLeScanner = ((BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE)).getAdapter().getBluetoothLeScanner();

      this.poolExecutor.execute(() -> {
        JarvisApi jarvisApi = JarvisApi.getInstance();
        ApplicationDetail applicationDetail = jarvisApi.getApplicationDetail(sdkKey);
        if (applicationDetail != null) {
          Map<String, DeviceFilter> deviceFilterMap = applicationDetail.getDeviceFilterMap();
          DeviceFilter beaconFilter = deviceFilterMap.get("attendance_beacon");

          ScanFilter bleFilter = BleUtils.getScanFilter(beaconFilter.getUuid(), beaconFilter.getMajor(), 0);
          List<ScanFilter> filters = new ArrayList<>();
          filters.add(bleFilter);

          Log.d("BleScannerService", "ble start scan");
          bluetoothLeScanner.startScan(filters, scanSettings, this.scanCallback);

          Calendar rightNow = Calendar.getInstance();
          int currentSeconds = rightNow.get(Calendar.SECOND);
          long delay = (60 - currentSeconds) * 1000 - rightNow.get(Calendar.MILLISECOND);
          this.poolExecutor.scheduleAtFixedRate(this::checkScannedMap, delay, 60000, TimeUnit.MILLISECONDS);

          serviceDelegate.onStarted(true);
        } else {
          serviceDelegate.onStarted(false);
          this.stopSelf();
        }
      });
    }
  }

  private void stopScan() {
    if (this.scanCallback != null) {
      boolean bluetoothScan = true;
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        bluetoothScan = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED;
      }

      if (bluetoothScan) {
        BluetoothLeScanner bluetoothLeScanner = ((BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE)).getAdapter().getBluetoothLeScanner();
        bluetoothLeScanner.stopScan(this.scanCallback);
      }
    }

    this.poolExecutor.shutdownNow();
  }

  private void onBleDiscovered(ScanResult scanResult) {
    long now = new Date().getTime();
    PeripheralDetail ble = BleUtils.getBeaconFromScanResult(scanResult);
    if (ble != null && ble.getDistance() <= (double) this.locatingRange) {

      String key = ble.getKey();

      if (!this.scannedBleMap.containsKey(key)) {
        this.scannedBleMap.put(key, ble);
        ble.setLastSignalTime(now);

        this.onNewBeaconDetected(ble);
      } else {
        PeripheralDetail existBle = this.scannedBleMap.get(key);
        existBle.setLastSignalTime(now);
      }
    }
  }

  private void onNewBeaconDetected(final PeripheralDetail ble) {
    this.poolExecutor.execute(() -> {
      String uuid = ble.getUuid().replaceAll("-", "");
      int major = ble.getMajor();
      int minor = ble.getMinor();
      Log.d("onNewBeaconDetected", uuid + "-" + major + "-" + minor);

      JarvisApi jarvisApi = JarvisApi.getInstance();
      LocatingNotification notification = jarvisApi.findNotificationByDevice(
          this.sdkKey,
          uuid,
          major,
          minor
      );

      if (notification != null) {
        long now = new Date().getTime();
        WritableMap eventBody = Arguments.createMap();

        eventBody.putString("uuid", uuid);
        eventBody.putInt("major", major);
        eventBody.putInt("minor", minor);
        eventBody.putString("title", notification.getTitle());
        eventBody.putString("description", notification.getDescription());
        eventBody.putDouble("time", now);

        serviceDelegate.onProximityPush(eventBody);
        pushFoundNotification(minor, notification.getTitle(), notification.getDescription());
        Log.d("BleScannerService", notification.getTitle() + "-" + notification.getDescription());
      } else {
        Log.d("BleScannerService", "onNewBeaconDetected notification not found");
      }
    });
  }

  private void pushFoundNotification(int id, String title, String description) {
    Notification notification;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      notification = new Notification.Builder(this, DEVICE_CHANNEL_ID).setContentTitle(title)
          .setContentText(description)
          .setSmallIcon(this.notificationIconResourceId)
          .build();

    } else {
      notification = new NotificationCompat.Builder(this, DEVICE_CHANNEL_ID).setContentTitle(title)
          .setContentText(description)
          .setSmallIcon(this.notificationIconResourceId)
          .build();
    }

    NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);

    // notificationId is a unique int for each notification that you must define
    notificationManager.notify(id, notification);
  }

  private void checkScannedMap() {
    Calendar nowCalendar = Calendar.getInstance();
    long now = nowCalendar.getTimeInMillis();
    Log.d("BleScannerService", "checkScannedMap " + now);

    Collection<PeripheralDetail> bleList = this.scannedBleMap.values();
    for (PeripheralDetail ble : bleList) {
      String key = ble.getKey();
      long lastSignalTime = ble.getLastSignalTime();

      // offsite
      if (now - lastSignalTime >= 60 * 1000) {
        this.scannedBleMap.remove(key);
      }
    }
  }

  @Override
  public void onDestroy() {
    Log.d("BleScannerService", "onDestroy");
    this.stopScan();
    this.stopForeground(true);
    this.scannedBleMap.clear();
    running = false;
    super.onDestroy();
  }

  private void createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      NotificationChannel serviceChannel = new NotificationChannel(
          CHANNEL_ID,
          "Jarvis Sdk Service Channel",
          NotificationManager.IMPORTANCE_DEFAULT
      );
      getSystemService(NotificationManager.class).createNotificationChannel(serviceChannel);

      NotificationChannel deviceChannel = new NotificationChannel(
          DEVICE_CHANNEL_ID,
          "Jarvis Sdk Service Channel",
          NotificationManager.IMPORTANCE_HIGH
      );
      getSystemService(NotificationManager.class).createNotificationChannel(deviceChannel);
    }
  }

  public static boolean isRunning() {
    return running;
  }

  public static void setDelegate(BleScannerServiceCallback callback) {
    serviceDelegate = callback;
  }
}
