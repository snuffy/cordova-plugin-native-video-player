package jp.rabee

import android.content.res.AssetFileDescriptor
import android.media.MediaPlayer
import org.apache.cordova.*
import org.json.JSONException
import android.util.Log
import android.view.WindowManager
import org.json.*


class CDVNativeVideoPlayer : CordovaPlugin() {

    lateinit var mediaPlayer: MediaPlayer
    // アプリ起動時に呼ばれる
    override public fun initialize(cordova: CordovaInterface,  webView: CordovaWebView) {
        LOG.d(TAG, "hi! This is CDVKeepAwake. Now intitilaizing ...");
    }


    // js 側で関数が実行されるとこの関数がまず発火する
    override fun execute(action: String, data: JSONArray, callbackContext: CallbackContext): Boolean {
         var result = false
        // 渡ってくる内容
        // title ... メディアのタイトル
        // album ... メディアの収録アルバム
        // source ... file path (どこに配置されているか)
        // 一旦、demo では sample file を assets配下に入れているのでそれを利用してくださいmm

        var playlists = data.getJSONArray(0);

        // とりあえず確認用に適当に音楽の方は再生させておきます。
        mediaPlayer = MediaPlayer();
        val filePath = "sample/sample1.mp3"
        val assetFd =  cordova.activity.assets.openFd(filePath)
        mediaPlayer.setDataSource(assetFd.fileDescriptor, assetFd.startOffset, assetFd.length)
        mediaPlayer.prepare();
        mediaPlayer.start();

        when(action) {
            "start" -> {
                result = this.start(callbackContext)
            }
            else -> {
                // TODO error
            }
        }


        return result
    }

    // プレイヤーの再生スタート
    private fun start(callbackContext: CallbackContext): Boolean {
        val pluginResult = PluginResult(PluginResult.Status.OK, true);
        callbackContext.sendPluginResult(pluginResult);
        return true;
    }

    companion object {
        protected val TAG = "CDVNativeVideoPlayer"
    }
}