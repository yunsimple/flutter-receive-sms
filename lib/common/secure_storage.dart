import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage{
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  SecureStorage._internal();
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage(){
    return _instance;
  }

  Future<bool> write(String key, String value) async{
    bool result;
    try{
      await storage.write(key: key, value: value);
      result = true;
    }catch (e){
      result = false;
    }
    return result;
  }

  Future<dynamic> read(String key) async{
    String? result = await storage.read(key: key);
    return result;
  }

  Future<bool> del({String key = '', bool deleteAll = false}) async{
    try{
      if(deleteAll == true){
        await storage.deleteAll();
      }else{
        await storage.delete(key: key);
      }
    } catch (e){
      return false;
    }
    return true;
  }
}