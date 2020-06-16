package jp.rabee

import android.content.Intent
import org.apache.cordova.*
import android.util.Log
import com.google.gson.GsonBuilder
import org.json.*
import java.net.URLDecoder

class CDVNativeVideoPlayer : CordovaPlugin() {

//    lateinit var player : SimpleExoPlayer

    override public fun initialize(cordova: CordovaInterface,  webView: CordovaWebView) {
        LOG.d(TAG, "hi! This is CDVKeepAwake. Now intitilaizing ...");
    }


    // js 側で関数が実行されるとこの関数がまず発火する
    override fun execute(action: String, data: JSONArray, callbackContext: CallbackContext): Boolean {
        var result = false

//        val activity = cordova.activity
//        val app = activity.application
//
//        //TODO: Intentで別Activityにすること、PlayerUIをカスタマイズすること、再生速度を変更すること、PIPモードを試すこと
//        activity.runOnUiThread {
//            val inflater = cordova.activity.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
//            val id = app.resources.getIdentifier("activity_main", "layout", app.packageName)
//            val rootView = inflater.inflate(id, null)
//            activity.setContentView(rootView)
//            val playerView: PlayerView = rootView.findViewWithTag("playerView")
//
//
//            player = SimpleExoPlayer.Builder(app.applicationContext).build()
//            playerView.player = player
//
//            val userAgent = Util.getUserAgent(playerView.context, activity.applicationInfo.loadLabel(activity.packageManager).toString())
//            val dataSourceFactory =
//                    DefaultDataSourceFactory(playerView.context,
//                            Util.getUserAgent(playerView.context,
//                                    userAgent))
//
//            var concatMediaSource = ConcatenatingMediaSource()
//            items.forEach {
//                val url = Uri.parse(URLDecoder.decode(it.source, "UTF-8"))
//                when (Util.inferContentType(url)) {
//                    C.TYPE_HLS -> {
//                        val mediaSource = HlsMediaSource
//                                .Factory(dataSourceFactory)
//                                .createMediaSource(url)
//                        concatMediaSource.addMediaSource(mediaSource)
//                    }
//                    C.TYPE_OTHER -> {
//                        val mediaSource = ProgressiveMediaSource
//                                .Factory(dataSourceFactory)
//                                .createMediaSource(url)
//                        concatMediaSource.addMediaSource(mediaSource)
//                    }
//                    else -> {
//                        //do nothing.
//                    }
//                }
//            }
//            player.prepare(concatMediaSource)
//        }
//        player.playWhenReady = true

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
            GsonBuilder().create().let { gson ->
                val items = gson.fromJson(params.toString(), Array<MediaItem>::class.java).toList()
                items.forEach {
                    Log.d(TAG, "MediaItem: ${URLDecoder.decode(it.source, "UTF-8")}")
                }

                val intent = Intent(cordova.activity.application, PlayerActivity::class.java)
                intent.putExtra(MediaItem.MEDIA_ITEMS_EXTRA, gson.toJson(items))
                startActivity(intent)

                val pluginResult = PluginResult(PluginResult.Status.OK, true);
                callbackContext.sendPluginResult(pluginResult);
                return true
            }
        }

        val pluginResult = PluginResult(PluginResult.Status.ERROR, false);
        callbackContext.sendPluginResult(pluginResult);

        return false;
    }

    companion object {
        protected val TAG = "CDVNativeVideoPlayer"
    }
}