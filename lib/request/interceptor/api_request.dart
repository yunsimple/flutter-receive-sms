import 'package:get/get.dart';

class ApiRequest{
  int code;

  ApiRequest(this.code);

  RxStatus errorCode(){
    switch(code){
      case 0:{
        return RxStatus.success();
      }
      case 3000:{
        return RxStatus.empty();
      }
      default:{
        return RxStatus.error("请求失败".tr);
      }
    }
  }

}