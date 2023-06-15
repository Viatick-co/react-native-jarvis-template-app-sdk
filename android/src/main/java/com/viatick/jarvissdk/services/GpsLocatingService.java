package com.viatick.jarvissdk.services;

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
import android.location.Location;
import android.os.Build;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationAvailability;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.Priority;
import com.viatick.jarvissdk.apis.JarvisApi;
import com.viatick.jarvissdk.apis.response.ApplicationDetail;
import com.viatick.jarvissdk.apis.response.DeviceFilter;
import com.viatick.jarvissdk.apis.response.DeviceReferenceDetail;
import com.viatick.jarvissdk.apis.response.JarvisDevice;
import com.viatick.jarvissdk.apis.response.LocatingNotification;
import com.viatick.jarvissdk.model.PeripheralDetail;
import com.viatick.jarvissdk.utils.BleUtils;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class GpsLocatingService extends Service {

  private final String TAG = "GpsLocatingService";

  private final static String CHANNEL_ID = "Jarvis_Rn_Sdk_Channel";
  private final static String DEVICE_CHANNEL_ID = "Jarvis_Rn_Device_Channel";

  private final static int SERVICE_NOTIFICATION_ID = 9999999;

  private ScanCallback scanCallback;

  private static GpsLocatingServiceCallback serviceDelegate;
  private static boolean running;
  private String sdkKey = "";
  private int locatingRange = 3;
  private int notificationIconResourceId = 0;
  private String serviceNotificationTitle = "Jarvis";
  private String serviceNotificationDescription = "SDK Running...";

  private FusedLocationProviderClient fusedLocationClient;

  private static long lastBleFoundDateTime = 0;
  private static double lat = 0;
  private static double lng = 0;

  private static final ConcurrentHashMap<String, PeripheralDetail> scannedBleMap = new ConcurrentHashMap<>();
  private final ScheduledThreadPoolExecutor poolExecutor = new ScheduledThreadPoolExecutor(2);

  private final LocationCallback locationCallback = new LocationCallback() {
    @Override
    public void onLocationAvailability(@NonNull LocationAvailability locationAvailability) {
      Log.d(TAG, "Location Available " + locationAvailability.isLocationAvailable());
    }

    @Override
    public void onLocationResult(@NonNull LocationResult locationResult) {
      List<Location> locations = locationResult.getLocations();
      if (!locations.isEmpty()) {
        Location location = locations.get(0);
        Log.d(TAG, "Location  " + location.getLatitude() + " - " + location.getLongitude());
        lat = location.getLatitude();
        lng = location.getLongitude();
      }
    }
  };

  public GpsLocatingService() {
  }

  @Nullable
  @Override
  public IBinder onBind(Intent intent) {
    return null;
  }

  @Override
  public void onCreate() {
    Log.d(TAG, "onCreate");
    running = true;
    super.onCreate();
  }

  @Override
  public int onStartCommand(Intent intent, int flags, int startId) {
    Log.d(TAG, "onStartCommand");
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
    Log.d(TAG, "startScan called");
    this.fusedLocationClient = LocationServices.getFusedLocationProviderClient(this);
    startLocationUpdates();

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

          Log.d(TAG, "ble start scan: " + beaconFilter.getUuid() + " " + beaconFilter.getMajor());

//          ScanFilter bleFilter = BleUtils.getScanFilter(beaconFilter.getUuid(), beaconFilter.getMajor(), 0);
//          List<ScanFilter> filters = new ArrayList<>();
//          filters.add(bleFilter);

          bluetoothLeScanner.startScan(null, scanSettings, this.scanCallback);

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

    if (this.fusedLocationClient != null) {
      this.fusedLocationClient.removeLocationUpdates(this.locationCallback);
      this.fusedLocationClient = null;
    }
    this.poolExecutor.shutdownNow();
  }

  private void onBleDiscovered(ScanResult scanResult) {
    long now = new Date().getTime();
    lastBleFoundDateTime = now;

    PeripheralDetail ble = BleUtils.getBeaconFromScanResult(scanResult);
    if (ble == null) {
      return;
    }

    double distance = ble.getDistance();
    if (distance > 0 && distance <= (double) this.locatingRange) {
      Log.d(TAG, "ble name " + ble.getName());
      String name = ble.getName();
      if (!name.startsWith("KBPro")) {
        return;
      }

      String mac = ble.getMac();
      if (!scannedBleMap.containsKey(mac)) {
        scannedBleMap.put(mac, ble);
        ble.setLastSignalTime(now);

        this.onNewBeaconDetected(ble);
      } else {
        PeripheralDetail existBle = scannedBleMap.get(mac);
        existBle.setLastSignalTime(now);
      }
    }
  }

  private void onNewBeaconDetected(final PeripheralDetail ble) {
    this.poolExecutor.execute(() -> {
      Log.d(TAG, ble.getName() + " - " + ble.getMac());

      // find linked personnel
      String mac = ble.getMac();
      String macId = mac.replaceAll(":", "").toUpperCase();

      JarvisApi jarvisApi = JarvisApi.getInstance();
      JarvisDevice foundJarvisDevice = jarvisApi.findDevice(sdkKey, macId);
      if (foundJarvisDevice != null) {
        DeviceReferenceDetail referenceDetail = foundJarvisDevice.getReferenceDetail();
        String type = foundJarvisDevice.getDeviceType();

        Log.d(TAG, "Found device " + type + " - " + referenceDetail.getId());
        if ("WEARABLE".equalsIgnoreCase(type)) {
          String id = referenceDetail.getId();
          if (id != null) {
            ble.setPersonnelId(id);

            jarvisApi.updatePersonnelGps(sdkKey, id, lat + "", lng + "");
          }
        }
      }
    });
  }

  private void checkScannedMap() {
    Calendar nowCalendar = Calendar.getInstance();
    long now = nowCalendar.getTimeInMillis();
    Log.d("BleScannerService", "checkScannedMap " + now);

    Collection<PeripheralDetail> bleList = scannedBleMap.values();
    for (PeripheralDetail ble : bleList) {
      String key = ble.getKey();
      long lastSignalTime = ble.getLastSignalTime();

      // offsite
      if (now - lastSignalTime >= 60 * 1000) {
        scannedBleMap.remove(key);
      }
    }
  }

  @Override
  public void onDestroy() {
    Log.d(TAG, "onDestroy");
    this.stopScan();
    this.stopForeground(true);
    scannedBleMap.clear();
    running = false;
    super.onDestroy();
    serviceDelegate.onDestroyed();
    serviceDelegate = null;
  }

  private void startLocationUpdates() {
//    LocationRequest locationRequest = LocationRequest.create();
//    locationRequest.setInterval(10000);
//    locationRequest.setFastestInterval(5000);
//    locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);

    LocationRequest locationRequest = new LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000)
      .setWaitForAccurateLocation(true)
      .setMinUpdateIntervalMillis(5000)
      .setMaxUpdateDelayMillis(10000)
      .build();

    if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
      // TODO: Consider calling
      //    ActivityCompat#requestPermissions
      // here to request the missing permissions, and then overriding
      //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
      //                                          int[] grantResults)
      // to handle the case where the user grants the permission. See the documentation
      // for ActivityCompat#requestPermissions for more details.
      return;
    }

    this.fusedLocationClient.requestLocationUpdates(
      locationRequest,
      this.locationCallback,
      Looper.getMainLooper()
    );
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

  public static void setDelegate(GpsLocatingServiceCallback callback) {
    serviceDelegate = callback;
  }

  public static Collection<PeripheralDetail> getListBeacons() {
    return scannedBleMap.values();
  }

  public static long getLastBleFoundDateTime() {
    return lastBleFoundDateTime;
  }

}
