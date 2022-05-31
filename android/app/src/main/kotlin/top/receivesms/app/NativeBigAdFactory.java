// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package top.receivesms.app;

import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RatingBar;
import android.widget.TextView;

import com.google.android.gms.ads.nativead.MediaView;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;

import java.util.Map;
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory;

class NativeBigAdFactory implements NativeAdFactory {
  private final LayoutInflater layoutInflater;

  NativeBigAdFactory(LayoutInflater layoutInflater) {
    this.layoutInflater = layoutInflater;
  }

  @Override
  public NativeAdView createNativeAd(NativeAd nativeAd, Map<String, Object> customOptions) {
    final NativeAdView adView = (NativeAdView) layoutInflater.inflate(R.layout.native_big_ad, null);

    // 设置媒体视图。
    adView.setMediaView((MediaView) adView.findViewById(R.id.ad_media));

    // 设置其他广告资源。
    adView.setHeadlineView(adView.findViewById(R.id.ad_headline));  // 主要标题
    adView.setBodyView(adView.findViewById(R.id.ad_body));  // 副标题内容
    adView.setCallToActionView(adView.findViewById(R.id.ad_call_to_action));  // 打开按钮
    adView.setIconView(adView.findViewById(R.id.ad_app_icon));   // 图像
    adView.setPriceView(adView.findViewById(R.id.ad_price));   // 价格
    adView.setStarRatingView(adView.findViewById(R.id.ad_stars)); // 评星
    adView.setStoreView(adView.findViewById(R.id.ad_store));  // 来源市场
    adView.setAdvertiserView(adView.findViewById(R.id.ad_advertiser));  // 商家信息

    // 标题和 mediaContent 保证出现在每个 NativeAd 中。
    ((TextView) adView.getHeadlineView()).setText(nativeAd.getHeadline());
    adView.getMediaView().setMediaContent(nativeAd.getMediaContent());

    // 这些素材资源不能保证出现在每个 NativeAd 中，因此重要的是
    // 在尝试显示它们之前检查。
    if (nativeAd.getBody() == null) {
      adView.getBodyView().setVisibility(View.INVISIBLE);
    } else {
      adView.getBodyView().setVisibility(View.VISIBLE);
      ((TextView) adView.getBodyView()).setText(nativeAd.getBody());
    }

    if (nativeAd.getCallToAction() == null) {
      adView.getCallToActionView().setVisibility(View.INVISIBLE);
    } else {
      adView.getCallToActionView().setVisibility(View.VISIBLE);
      ((Button) adView.getCallToActionView()).setText(nativeAd.getCallToAction());
    }

    if (nativeAd.getIcon() == null) {
      //adView.getIconView().setVisibility(View.GONE);
      // 如果没有图像，则用本地图片代替
      ((ImageView) adView.getIconView()).setBackgroundResource(R.drawable.usa);
    } else {
      ((ImageView) adView.getIconView()).setImageDrawable(nativeAd.getIcon().getDrawable());
      adView.getIconView().setVisibility(View.VISIBLE);
    }

    if (nativeAd.getPrice() == null) {
      adView.getPriceView().setVisibility(View.INVISIBLE);
    } else {
      adView.getPriceView().setVisibility(View.VISIBLE);
      ((TextView) adView.getPriceView()).setText(nativeAd.getPrice());
    }

    if (nativeAd.getStore() == null) {
      adView.getStoreView().setVisibility(View.INVISIBLE);
    } else {
      adView.getStoreView().setVisibility(View.VISIBLE);
      ((TextView) adView.getStoreView()).setText(nativeAd.getStore());
    }

    if (nativeAd.getStarRating() == null) {
      adView.getStarRatingView().setVisibility(View.INVISIBLE);
    } else {
      ((RatingBar) adView.getStarRatingView()).setRating(nativeAd.getStarRating().floatValue());
      adView.getStarRatingView().setVisibility(View.VISIBLE);
    }

    if (nativeAd.getAdvertiser() == null) {
      adView.getAdvertiserView().setVisibility(View.INVISIBLE);
    } else {
      adView.getAdvertiserView().setVisibility(View.VISIBLE);
      ((TextView) adView.getAdvertiserView()).setText(nativeAd.getAdvertiser());
    }

    // 此方法告诉 Google Mobile Ads SDK 您已完成填充
    // 此原生广告的原生广告视图。
    adView.setNativeAd(nativeAd);

    return adView;
  }
}
