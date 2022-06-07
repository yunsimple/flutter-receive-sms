import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../common/remote_config.dart';
import '../common/secure_storage.dart';
import '../request/token_http.dart';
import '../utils/api.dart';
import '../utils/config.dart';
import '../common/local_storage.dart';
import '../utils/tools.dart';
import 'package:get/get.dart';
import 'package:encrypt/encrypt.dart';
import '../pages/home/home_controller.dart';

class Auth{
  static Auth? _instance;
  static late User? firebaseUserInfo;
  FirebaseAuth auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();

  User? get currentUser => auth.currentUser;

  factory Auth(){
    _instance ??= Auth._init();
    return _instance!;
  }

  Auth._init(){
    auth.userChanges().listen((User? user) {
      if (user == null) {
        //log('Firebase账户已经退出');
        firebaseUserInfo = null;
      } else {
        //log('Firebase账户登陆成功 = $user}');
        firebaseUserInfo = user;
      }
    });
  }

/*  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(auth.currentUser);
    _user.bindStream(auth.userChanges());
    print("✅✅✅✅ firebase user = $_user");
  }*/

  Future<dynamic> googleLogin() async {
    try{
      HomeController.appSwitch = 'dialog';
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn()
          .timeout(const Duration(seconds: FIREBASE_TIMEOUT)).catchError((err){
            log('googleLogin catchError = $err');
      });
      if(googleUser == null) return false;
      // 从请求中获取身份验证详细信息
      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication.timeout(const Duration(seconds: FIREBASE_TIMEOUT));
      // 创建新凭据
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      // 登录后，返回用户凭据
      await auth.signInWithCredential(credential).timeout(const Duration(seconds: FIREBASE_TIMEOUT));
      // 重新获取有用户记录的token
      await getToken();
      return true;
    } on FirebaseAuthException catch(e){
      return e.message;
    } on TimeoutException catch (e){
      log('googleLogin TimeoutException 登陆失败 = $e');
      return 'Timed out, unable to connect to google server';
    } catch (e){
      log('googleLogin catch 登陆失败 = $e');
      return false;
    }
  }


  Future<dynamic> register(String email, password) async{
    try{
       await auth.createUserWithEmailAndPassword(email: email, password: password).timeout(const Duration(seconds: FIREBASE_TIMEOUT));
       firebaseUserInfo = auth.currentUser;
       //Get.back(result: 'LoginSuccess');
       // 重新获取有用户记录的token
       await getToken();
       return true;
    } on FirebaseAuthException catch(e){
      Tools.toast(e.message ?? 'fail', type: 'error');
      return false;
    } catch (e){
      Tools.toast('请求失败'.tr, type: 'error');
      return false;
    }
  }


  /// 第一种，启动软件后，首先判断SecureStorage里面是否存在access_token 和refresh_token
  /// 如果不存在，就需要进行请求login进行登陆
  /// 1.auth.currentUser 查看当前是否有存在登陆过的账号，如果存在，获取当前getIdToken，请求api，获取token
  /// 2.如果当前账号不存在记录，则用firebase 匿名登陆，成功后获取getIdToken，请求api再获取token
  ///
  /// 第二种情况，直接输入邮箱密码进行登陆
  /// 登陆成功后，获取到uid，通过uid，请求api，获取token
  /// 如果登陆成功，需要更换新的access_token 和 refresh_token
  ///
  /// 总结
  /// 1.获取getIdToken
  /// 2.通过jwt token 获取access_token and refresh_token，获取成功后，保存进SecureStorage里面
  Future<dynamic> login(String email, password) async {
    try{
      //log('开始邮箱登陆');
      await auth.signInWithEmailAndPassword(email: email, password: password).timeout(const Duration(seconds: FIREBASE_TIMEOUT));
      firebaseUserInfo = auth.currentUser;
      // 重新获取有用户记录的token
      await getToken();
      return true;
    } on FirebaseAuthException catch(e){
      return e.message;
    } on TimeoutException catch (e){
      log('login TimeoutException 登陆失败 = $e');
      return 'Timed out, unable to connect to google server';
    } catch (e){
      log('login catch 登陆失败 = $e');
      return false;
    }
  }

  ///匿名登陆
  Future<bool> anonymousLogin() async {
    try{
      await auth.signInAnonymously().timeout(const Duration(seconds: FIREBASE_TIMEOUT));
      return true;
    } on FirebaseAuthException catch (e){
      //log('auth.signInAnonymously 异常 = $e');
      return false;
    } catch (e){
      return false;
    }
  }

  ///获取JWT token
  Future<String?> getIdToken() async{
    try{
      String? jwt = await auth.currentUser?.getIdToken().timeout(const Duration(seconds: FIREBASE_TIMEOUT));
      return jwt;
    } on FirebaseAuthException catch (e){
      return null;
    } catch (e){
      return null;
    }
  }

  /// 忘记密码发送邮件认证
  bool sendEmail(String email) {
    if(sendFrequency(email)){
      try{
        auth.sendPasswordResetEmail(email: email).timeout(const Duration(seconds: FIREBASE_TIMEOUT));
        return true;
      }on FirebaseAuthException catch (e){
        //log('发送邮件出错 = $e');
        return false;
      } catch (e){
        return false;
      }
    }else{
      return false;
    }
  }

  /// 限制邮件发送频率
  bool sendFrequency(String email) {
    String keyMinute = 'send_' + email + '_' + Tools.getYmd(ymd: 'ymdhm');
    int? minute = LocalStorage().getInt(keyMinute);
    //log('minute = $minute');
    if(minute != null && minute > 0){
      return false;
    }
    LocalStorage().setIncr(keyMinute);
    return true;
  }

  ///通过jwt token，获取到请求数据的access_token 和 refresh_token
  Future<bool> getToken() async{
    log('Begin getToken');
    String? jwt = await getIdToken();
    if(jwt == null){
      bool anonymous = await anonymousLogin();
      if(anonymous){
        jwt = await getIdToken();
        if(jwt == null){
          return false;
        }
      }else{
        return false;
      }
    }
    /// 对jwt Aes 加密
    String key = await SecureStorage().read('ys');
    String iv = await SecureStorage().read('ysv');
    final encrypt = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    final jwtAES = encrypt.encrypt(jwt,iv: IV.fromUtf8(iv));

    /// http request token，由于目前不存在加密
    try{
      Map<String, dynamic> result = await TokenHttp().post(Api.login, {'token': jwtAES.base64}).catchError((e){
        //log('token catchError 异常 = $e');
      });
      if(result['error_code'] == 0){
        final accessToken = encrypt.decrypt(Encrypted.fromBase64(result['data']['access_token']), iv: IV.fromUtf8(iv));
        final refreshToken = encrypt.decrypt(Encrypted.fromBase64(result['data']['refresh_token']), iv: IV.fromUtf8(iv));
        await SecureStorage().write('accessToken', accessToken);
        await SecureStorage().write('refreshToken', refreshToken);
        int nowTime = DateTime.now().millisecondsSinceEpoch;
        LocalStorage().setInt('accessTokenExpire', (result['data']['access_token_expire']*1000 + nowTime));
        LocalStorage().setInt('refreshTokenExpire', (result['data']['access_token_expire']*1000 + nowTime));
        return true;
      }else{
        //log('token 更新失败');
        return false;
      }
    }on DioError catch (e){
      //log('token DioError 异常 = $e');
      return false;
    }catch(e){
      //log('token 异常 = $e');
      return false;
    }
  }

  /// api返回3001后，需要重新获取accessToken情况
  /// 分两种情况，
  /// 存在refreshToken，直接获取accessToken即可
  /// 如果refreshToken不存在，则需要先 getToken
  Future<String?> getAccessToken() async{
    //log('Begin getAccessToken');
    String? refreshToken = await SecureStorage().read('refreshToken');
    if(refreshToken == null){
      //log('refreshToken不存在，重新请求获取getToken');
      bool token = await getToken();
      if(!token){
        return null;
      }
      refreshToken = await SecureStorage().read('refreshToken');
      //log('refreshToken = $refreshToken');
      if(refreshToken == null){
        return null;
      }
    }
    /// 对refreshToken Aes 加密
    String key = await SecureStorage().read('ys');
    String iv = await SecureStorage().read('ysv');
    //log('安全存储 ys = $key ysv = $iv');
    final encrypt = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    final refreshTokenAES = encrypt.encrypt(refreshToken,iv: IV.fromUtf8(iv));
    /// http request token，由于目前不存在加密
    /// 不能使用通用的dio进行请求，否则会很麻烦，必须重新new一个dio请求
    /// 避免同时请求
    int nowTime = DateTime.now().millisecondsSinceEpoch;
    try{
      return await TokenHttp().post(Api.access, {'token': refreshTokenAES.base64}).then((result) async{
        /// todo 上线前删除这些logo
        //log("TokenHttp请求成功 = $result");
        if(result['error_code'] == 0){
          final accessToken = result['data']['accessToken'];
          await SecureStorage().write('accessToken', accessToken);
          LocalStorage().setInt('accessTokenExpire', result['data']['accessTokenExpire']*1000 + nowTime);
          //log('续期成功 ${result['data']['accessTokenExpire']*1000 + DateTime.now().millisecondsSinceEpoch}');
          return result['data']['accessToken'];
        }else if(result['error_code'] == 4004){
          //SecureStorage().read('accessToken').then((value) => log('accessToken = $value'));
          SecureStorage().del(deleteAll: true).then((value) {
            Tools.toast('出现异常请重新启动APP'.tr, type: 'error', time: 300);
            /// todo需要正式包验证一下
            //SecureStorage().read('accessToken').then((value) => log('accessToken = $value'));
            //Restart.restartApp();
          });
        }
        return null;
      }).catchError((e){
        //log('access catchError 异常 = $e');
        return null;
      });
    }on DioError catch (e){
      //log('access DioError 异常 = $e');
      return null;
    } catch (e){
      //log('access 异常 = $e');
      return null;
    }
  }

  Future<bool> getSalt() async{
    //log('Begin getSalt');
    /// key 本地salt 
    String key = Tools.generateMd5(PRIMARYCOLOR.toString());
    /// iv remote config rk salt
    String iv = RemoteConfigApi().getString('rk');
    if(iv == ''){
      return false;
    }
    //log('远程rk = $iv');
    iv = iv.replaceAll(" ", "");
    int ivLen = iv.length;
    if(ivLen < IV_LENGTH){
      String add = Tools.generateMd5(key).substring(0, IV_LENGTH - ivLen);
      iv += add;
    }else{
      iv = iv.substring(0,IV_LENGTH);
    }
    /// 把key iv保存到SecureStorage里面
    var writeYS = await SecureStorage().write('ys', key);
    var writeYSV = await SecureStorage().write('ysv', iv);

    if(writeYS && writeYSV){
      //log('密钥存储成功');
      /// 如果本地不存在 access_token refresh_token,或者有效期快到了，就去请求
      String? accessToken = await SecureStorage().read('accessToken');
      String? refreshToken = await SecureStorage().read('refreshToken');
      //log("$accessToken ----- $refreshToken");
      if(accessToken == null || refreshToken == null){
        //log('accessToken 或 refreshToken不存在，请求getToken');
        await getToken();
      }
    }
    return false;
  }

  Future<String?> getAuthorization() async{
    String? salt = await SecureStorage().read('ys');
    if(salt == null){
      return null;
    }
    String randomStr = Tools.generateRandom(length: 10);
    String authorization = Tools.generateMd5(salt + randomStr) + randomStr;
    return authorization;
  }

  Future<bool> loginOut() async {
    try{
      await auth.signOut().timeout(const Duration(seconds: FIREBASE_TIMEOUT));
      await getToken();
      return true;
    } on FirebaseAuthException catch (e){
      return false;
    } catch (e) {
      return false;
    }
  }

}