package top.receivesms.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // COMPLETE: Register the ListTileNativeAdFactory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, "nativeSmallAd", NativeSmallAdFactory(context)
        )

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, "nativeBigAd",
            NativeBigAdFactory(layoutInflater)
        )

        /*val factory: NativeAdFactory = NativeBigAdFactory(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "nativeBigAd", factory)*/
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)

        // COMPLETE: Unregister the ListTileNativeAdFactory
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "nativeSmallAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "nativeBigAd")
    }
}