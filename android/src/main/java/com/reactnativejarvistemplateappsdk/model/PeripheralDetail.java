package com.reactnativejarvistemplateappsdk.model;

public class PeripheralDetail {

  private String uuid;
  private int major;
  private int minor;
  private double distance;
  private long lastSignalTime;

  public PeripheralDetail() {}

  public PeripheralDetail(String uuid, int major, int minor, double distance) {
    this.uuid = uuid;
    this.major = major;
    this.minor = minor;
    this.distance = distance;
  }

  public String getUuid() {
    return uuid;
  }

  public void setUuid(String uuid) {
    this.uuid = uuid;
  }

  public int getMajor() {
    return major;
  }

  public void setMajor(int major) {
    this.major = major;
  }

  public int getMinor() {
    return minor;
  }

  public void setMinor(int minor) {
    this.minor = minor;
  }

  public double getDistance() {
    return distance;
  }

  public void setDistance(double distance) {
    this.distance = distance;
  }

  public long getLastSignalTime() {
    return lastSignalTime;
  }

  public void setLastSignalTime(long lastSignalTime) {
    this.lastSignalTime = lastSignalTime;
  }

  public String  getKey() {
    return this.uuid.toLowerCase().replaceAll("-", "") + "-" + this.major + "-" + this.minor;
  }

}
