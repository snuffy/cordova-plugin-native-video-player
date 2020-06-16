
package jp.rabee

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.ImageButton
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.github.rubensousa.previewseekbar.exoplayer.PreviewTimeBar
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.source.ConcatenatingMediaSource
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.ads.AdsLoader
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import com.google.gson.GsonBuilder
import jp.snuffy.nativeVideoPlayerTest.R
import java.net.URLDecoder
import kotlin.math.max

class PlayerActivity : AppCompatActivity() {

    private var player : SimpleExoPlayer? = null
    private var mediaSource : MediaSource? = null
    private var adsLoader : AdsLoader? = null
    private var items: List<MediaItem>? = null

    private lateinit var dataSourceFactory : DataSource.Factory

    private var playerView : PlayerView? = null
    private var previewTimeBar : PreviewTimeBar? = null
    private var closeButton : ImageButton? = null

    private var startAutoPlay = true
    private var startWindow = C.INDEX_UNSET
    private var startPosition = C.TIME_UNSET


    companion object {
        // Saved instance state keys.
        private const val KEY_WINDOW = "window"
        private const val KEY_POSITION = "position"
        private const val KEY_AUTO_PLAY = "auto_play"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        releasePlayer()
        releaseAdsLoader()
        clearStartPosition()
        setIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        setContentView(R.layout.activity_player)

        playerView = findViewById(R.id.player_view);
        previewTimeBar = findViewById(R.id.exo_progress)
        closeButton = findViewById(R.id.close_button)
        closeButton?.setOnClickListener {
            finish()
        }

        dataSourceFactory = buildDataSourceFactory()

        if (Util.SDK_INT > 23) {
            initializePlayer()
            playerView?.apply {
                onResume()
            }
        }
    }

    override fun onResume() {
        super.onResume()

        // fullscreen
        window.decorView.apply {
            systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                            or View.SYSTEM_UI_FLAG_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    )
        }

        if (Util.SDK_INT <= 23 || player == null) {
            initializePlayer()
            playerView?.apply {
                onResume()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        if (Util.SDK_INT <= 23) {
            playerView?.apply {
                onPause()
            }
            releasePlayer()
        }
    }

    override fun onStop() {
        super.onStop()
        if (Util.SDK_INT > 23) {
            playerView?.apply {
                onPause()
            }
            releasePlayer()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseAdsLoader()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            initializePlayer()
        } else {
            showToast(R.string.storage_permission_denied)
            finish()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        updateStartPosition()

        outState.apply {
            putBoolean(KEY_AUTO_PLAY, startAutoPlay)
            putInt(KEY_WINDOW, startWindow)
            putLong(KEY_POSITION, startPosition)
        }
    }

    override fun onBackPressed() {
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
                && packageManager
                        .hasSystemFeature(
                                PackageManager.FEATURE_PICTURE_IN_PICTURE)){
            enterPIPMode()
        } else {
            super.onBackPressed()
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()

        enterPIPMode()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration?) {
        (super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig))

        if (!isInPictureInPictureMode) {
            playerView?.apply {
                useController = true
            }
        }
    }

    @Suppress("DEPRECATION")
    fun enterPIPMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
                && packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
            playerView?.apply {
                useController = false
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val params = PictureInPictureParams.Builder()
                this.enterPictureInPictureMode(params.build())
            } else {
                this.enterPictureInPictureMode()
            }
        }
    }

    private fun initializePlayer() {
        mediaSource = createTopLevelMediaSource()

        if (player == null) {
            player = SimpleExoPlayer.Builder(applicationContext).build().also {
                it.setAudioAttributes(AudioAttributes.DEFAULT, true)
                it.playWhenReady = startAutoPlay

                playerView?.apply {
                    player = it
                }

                adsLoader?.apply {
                    setPlayer(it)
                }

                val haveStartPosition = startWindow != C.INDEX_UNSET
                if (haveStartPosition) it.seekTo(startWindow, startPosition)

                mediaSource?.let { mediaSource ->
                    it.prepare(mediaSource)
                }
            }
        }
    }

    private fun createTopLevelMediaSource() : ConcatenatingMediaSource {
        intent.getStringExtra(MediaItem.MEDIA_ITEMS_EXTRA)?.let {
            GsonBuilder().create().apply {
                items = fromJson(it, Array<MediaItem>::class.java).toList()
            }
        }

        var concatMediaSource = ConcatenatingMediaSource()
        playerView?.let {
            items?.forEach { item ->
                val url = Uri.parse(URLDecoder.decode(item.source, "UTF-8"))
                when (Util.inferContentType(url)) {
                    C.TYPE_HLS -> {
                        val mediaSource = HlsMediaSource
                                .Factory(dataSourceFactory)
                                .createMediaSource(url)
                        concatMediaSource.addMediaSource(mediaSource)
                    }
                    C.TYPE_OTHER -> {
                        val mediaSource = ProgressiveMediaSource
                                .Factory(dataSourceFactory)
                                .createMediaSource(url)
                        concatMediaSource.addMediaSource(mediaSource)
                    }
                    else -> {
                        //do nothing.
                    }
                }
                item.title?.let { title ->
                    // do nothing.
                }
            }
        }

        return concatMediaSource
    }

    private fun releasePlayer() {
        player?.apply {
            release()
            player = null
        }

        adsLoader?.apply {
            setPlayer(null)
        }
    }

    private fun releaseAdsLoader() {
        adsLoader?.also {
            it.release()
            adsLoader = null

            playerView?.apply {
                overlayFrameLayout?.apply {
                    removeAllViews()
                }
            }
        }
    }

    private fun updateStartPosition() {
        player?.let {
            startAutoPlay = it.playWhenReady
            startWindow = it.currentWindowIndex
            startPosition = max(0, it.contentPosition)

        }
    }

    private fun clearStartPosition() {
        startAutoPlay = true
        startWindow = C.INDEX_UNSET
        startPosition = C.TIME_UNSET
    }

    private fun buildDataSourceFactory() : DataSource.Factory {
        val userAgent = Util.getUserAgent(applicationContext, applicationInfo.loadLabel(packageManager).toString())
        return DefaultDataSourceFactory(applicationContext,
                                        Util.getUserAgent(applicationContext, userAgent))
    }

    private fun showToast(messageId: Int) {
        showToast(getString(messageId))
    }

    private fun showToast(message: String) {
        Toast.makeText(applicationContext, message, Toast.LENGTH_LONG).show()
    }
}