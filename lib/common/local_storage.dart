import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 本地存储
class LocalStorage {
  LocalStorage._internal();
  static final LocalStorage _instance = LocalStorage._internal();

  factory LocalStorage() {
    return _instance;
  }

  SharedPreferences? prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<bool> setJSON(String key, dynamic jsonVal) {
    String jsonString = jsonEncode(jsonVal);
    return prefs!.setString(key, jsonString);
  }

  Future<bool> setString(String key, String value) {
    return prefs!.setString(key, value);
  }

  String? getString(String key) {
    return prefs!.getString(key);
  }

  Future<bool> setInt(String key, int value) {
    return prefs!.setInt(key, value);
  }

  // inc累加
  Future<bool> setIncr(String key, {int value = 1}) {
    int? number = getInt(key);
    if(number == null){
      number = value;
    }else{
      number = number + value;
    }
    return prefs!.setInt(key, number);
  }

  int? getInt(String key) {
    return prefs!.getInt(key);
  }

  dynamic getJSON(String key) {
    String? jsonString = prefs?.getString(key);
    return jsonString == null ? null : jsonDecode(jsonString);
  }

  Future<bool> setBool(String key, bool val) {
    return prefs!.setBool(key, val);
  }

  bool? getBool(String key) {
    return prefs!.getBool(key);
  }

  Future<bool> remove(String key) {
    return prefs!.remove(key);
  }
}
