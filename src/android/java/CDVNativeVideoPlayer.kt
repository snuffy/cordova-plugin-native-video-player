package jp.rabee

import android.content.Intent
import org.apache.cordova.*
import android.util.Log
import com.google.gson.GsonBuilder
import org.json.*
import java.net.URLDecoder

class CDVNativeVideoPlayer : CordovaPlugin() {

    override public fun initialize(cordova: CordovaInterface,  webView: CordovaWebView) {
        LOG.d(TAG, "hi! This is CDVKeepAwake. Now intitilaizing ...");
    }

    // js 側で関数が実行されるとこの関数がまず発火する
    override fun execute(action: String, data: JSONArray, callbackContext: CallbackContext): Boolean {
        var result = false

        //TODO:
        // PlayerUIをカスタマイズすること
        // 再生速度を変更すること
        // SeekPreviewの対応
        // 音声のタイトル表示対応
        when(action) {
            "start" -> {
                val params = data.getJSONArray(0);
                result = this.start(callbackContext, params)
            }
            else -> {
                // TODO error
            }
        }

        return result
    }

    // プレイヤーの再生スタート
    private fun start(callbackContext: CallbackContext, params: JSONArray): Boolean {
        cordova.activity.run {
            GsonBuilder().create().also { gson ->
                val items = gson.fromJson(params.toString(), Array<MediaItem>::class.java).toList()
                items.forEach {
                    Log.d(TAG, "MediaItem: ${URLDecoder.decode(it.source, "UTF-8")}")
                }

                val intent = Intent(cordova.activity.application, PlayerActivity::class.java)
                intent.putExtra(MediaItem.MEDIA_ITEMS_EXTRA, gson.toJson(items))
                startActivity(intent)

                val pluginResult = PluginResult(PluginResult.Status.OK, true);
                callbackContext.sendPluginResult(pluginResult);
            } ?: run {

                val pluginResult = PluginResult(PluginResult.Status.ERROR, false);
                callbackContext.sendPluginResult(pluginResult);

                return false;
            }
        }
        return true
    }

    companion object {
        private const val TAG = "CDVNativeVideoPlayer"
    }
}