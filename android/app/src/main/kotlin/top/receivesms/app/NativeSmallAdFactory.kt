package top.receivesms.app

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeSmallAdFactory(val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.native_small_ad, null) as NativeAdView

        //nativeAdView.setStarRatingView(nativeAdView.findViewById<View>(R.id.ad_stars))

        with(nativeAdView) {
/*            val attributionViewSmall =
                    findViewById<TextView>(R.id.tv_list_tile_native_ad_attribution_small)*/
            val attributionViewLarge =
                findViewById<TextView>(R.id.tv_list_tile_native_ad_attribution_large)

            val iconView = findViewById<ImageView>(R.id.iv_list_tile_native_ad_icon)
            val icon = nativeAd.icon

            val startView = findViewById<View>(R.id.ad_stars)
            val advertiserView = findViewById<TextView>(R.id.ad_advertiser)

            if (nativeAd.starRating != null){
                //println(nativeAd.starRating.toFloat())
                (startView as RatingBar).rating = nativeAd.starRating.toFloat()
                startView.visibility = View.VISIBLE
            }else{
                startView.visibility = View.INVISIBLE
                // 如果没有星星，就显示ad_advertiser
                if (nativeAd.advertiser != null){
                    advertiserView.text = nativeAd.advertiser
                    advertiserView.visibility = View.VISIBLE
                }

            }

            if (icon != null) {
                attributionViewLarge.visibility = View.INVISIBLE
                iconView.setImageDrawable(icon.drawable)
            } else {
                iconView.setBackgroundResource(R.drawable.usa)
                //attributionViewLarge.visibility = View.VISIBLE
            }
            this.iconView = iconView

            val headlineView = findViewById<TextView>(R.id.tv_list_tile_native_ad_headline)
            headlineView.text = nativeAd.headline
            this.headlineView = headlineView

            val bodyView = findViewById<TextView>(R.id.tv_list_tile_native_ad_body)
            with(bodyView) {
                text = nativeAd.body
                visibility = if (nativeAd.body.isNotEmpty()) View.VISIBLE else View.INVISIBLE
            }
            this.bodyView = bodyView

            setNativeAd(nativeAd)
        }

        return nativeAdView
    }
}