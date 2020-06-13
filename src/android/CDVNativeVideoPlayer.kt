package jp.rabee

import android.content.res.AssetFileDescriptor
import android.media.MediaPlayer
import android.net.Uri
import org.apache.cordova.*
import org.json.JSONException
import android.util.Log
import android.view.WindowManager
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlayerFactory
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory
import com.google.android.exoplayer2.source.ExtractorMediaSource
import com.google.android.exoplayer2.source.MediaSourceFactory
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import org.json.*


class CDVNativeVideoPlayer : CordovaPlugin() {

    lateinit var mediaPlayer: MediaPlayer
    // アプリ起動時に呼ばれる

    lateinit var player : SimpleExoPlayer

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

        var params = data.getJSONArray(0);


//        // とりあえず確認用に適当に音楽の方は再生させておきます。
        mediaPlayer = MediaPlayer();
        val filePath = "sample/sample1.mp3"
        val assetFd =  cordova.activity.assets.openFd(filePath)
        mediaPlayer.setDataSource(assetFd.fileDescriptor, assetFd.startOffset, assetFd.length)
        mediaPlayer.prepare();
        mediaPlayer.start();

//        val activity = cordova.activity
//        val app = activity.application
//        val resources = activity.resources
//        val id = resources.getIdentifier("playerView", "layout", app.packageName)
//        val playerView: PlayerView = cordova.activity.findViewById(id)
//
//        player = SimpleExoPlayer.Builder(app.applicationContext).build()
//        playerView.player = player
//
//        val userAgent = Util.getUserAgent(playerView.context, activity.applicationInfo.loadLabel(activity.packageManager).toString())
//        val mediaSourceFactory = ProgressiveMediaSource.Factory(
//                DefaultDataSourceFactory(
//                        playerView.context,
//                        userAgent
//                ),
//                DefaultExtractorsFactory()
//        )
//
//        val dataSourceFactory =
//                DefaultDataSourceFactory(this,
//                        Util.getUserAgent(this,
//                                applicationInfo.loadLabel(packageManager)
//                                        .toString()))
//
//        when (Util.inferContentType(Uri.parse(mUrl))) {
//            C.TYPE_HLS -> {
//                val mediaSource = HlsMediaSource
//                        .Factory(dataSourceFactory)
//                        .createMediaSource(Uri.parse(mUrl))
//                player.prepare(mediaSource)
//            }
//
//            C.TYPE_OTHER -> {
//                val mediaSource = ExtractorMediaSource
//                        .Factory(dataSourceFactory)
//                        .createMediaSource(Uri.parse(mUrl))
//                player.prepare(mediaSource)
//            }
//
//            else -> {
//                //This is to catch SmoothStreaming and
//                //DASH types which we won't support currently, exit
//                finish()
//            }
//        }
//        player.playWhenReady = true

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