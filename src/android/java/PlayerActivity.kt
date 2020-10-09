
package jp.rabee

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.Activity
import android.app.Notification
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.content.pm.PackageManager.FEATURE_PICTURE_IN_PICTURE
import android.content.res.Configuration
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.support.v4.media.session.MediaSessionCompat
import android.util.Pair
import android.view.View
import android.view.WindowManager
import android.webkit.MimeTypeMap
import android.widget.*
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.Target.SIZE_ORIGINAL
import com.github.rubensousa.previewseekbar.PreviewBar
import com.github.rubensousa.previewseekbar.PreviewLoader
import com.github.rubensousa.previewseekbar.exoplayer.PreviewTimeBar
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
import com.google.android.exoplayer2.mediacodec.MediaCodecRenderer
import com.google.android.exoplayer2.mediacodec.MediaCodecUtil
import com.google.android.exoplayer2.source.*
import com.google.android.exoplayer2.source.ads.AdsLoader
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.ui.PlayerControlView
import com.google.android.exoplayer2.ui.PlayerNotificationManager
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.ErrorMessageProvider
import com.google.android.exoplayer2.util.EventLogger
import com.google.android.exoplayer2.util.Log
import com.google.android.exoplayer2.util.Util
import com.google.gson.GsonBuilder
import java.io.File
import java.io.Serializable
import java.net.URL
import java.net.URLDecoder
import kotlin.math.max

class PlayerActivity : AppCompatActivity(), PlayerControlView.VisibilityListener, PlaybackPreparer {

    private var player : SimpleExoPlayer? = null
    private var mediaSource : MediaSource? = null
    private var adsLoader : AdsLoader? = null
    private var items: List<MediaItem>? = null

    private lateinit var dataSourceFactory : DataSource.Factory

    private var controllerView : ConstraintLayout? = null
    private var playerView : PlayerView? = null
    private var previewTimeBar : PreviewTimeBar? = null
    private var titleView : TextView? = null
    private var rateButton : Button? = null
    private var fullscreenButton : ImageButton? = null
    private var closeButton : ImageButton? = null
    private var previewImageView : ImageView? = null
    private var lastSeenTrackGroupArray : TrackGroupArray? = null
    private var trackSelector : DefaultTrackSelector? = null
    private var trackSelectorParameters : DefaultTrackSelector.Parameters? = null

    private var startAutoPlay = true
    private var startWindow = C.INDEX_UNSET
    private var startPosition = C.TIME_UNSET
    private var playbackRate = PLAYBACK_RATE_10
    private var orientation: Int = Configuration.ORIENTATION_PORTRAIT

    // 通知マネージャー
    var playerNotificationManager: PlayerNotificationManager? = null
    private var notificationId = 123456
    

    companion object {
        var activity: PlayerActivity? = null
        // TAG
        private const val TAG = "PlayerActivity"

        // Saved instance state keys.
        private const val KEY_WINDOW = "window"
        private const val KEY_POSITION = "position"
        private const val KEY_AUTO_PLAY = "auto_play"
        private const val KEY_TRACK_SELECTOR_PARAMETERS = "track_selector_parameters"

        // Playback speed
        private const val PLAYBACK_RATE_08 = 0.8f
        private const val PLAYBACK_RATE_10 = 1.0f
        private const val PLAYBACK_RATE_15 = 1.5f

        @Suppress("DEPRECATED_IDENTITY_EQUALS")
        private fun isBehindLiveWindow(error :ExoPlaybackException) : Boolean {
            if (error.type !== ExoPlaybackException.TYPE_SOURCE) {
                return false
            }
            var cause: Throwable? = error.sourceException
            while (cause != null) {
                if (cause is BehindLiveWindowException) {
                    return true
                }
                cause = cause.cause
            }
            return false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(resources.getIdentifier("activity_player", "layout", application.packageName))

        savedInstanceState?.also {
            trackSelectorParameters = it.getParcelable(KEY_TRACK_SELECTOR_PARAMETERS)
            startAutoPlay = it.getBoolean(KEY_AUTO_PLAY)
            startWindow = it.getInt(KEY_WINDOW)
            startPosition = it.getLong(KEY_POSITION)
        } ?: run {
            val builder = DefaultTrackSelector.ParametersBuilder(this@PlayerActivity)
            trackSelectorParameters = builder.build()
            clearStartPosition()
        }

        controllerView = findViewById(resources.getIdentifier("controller_view", "id", application.packageName))
        playerView = findViewById(resources.getIdentifier("player_view", "id", application.packageName))
        previewTimeBar = findViewById(R.id.exo_progress)
        titleView = findViewById(resources.getIdentifier("title_view", "id", application.packageName))
        rateButton = findViewById(resources.getIdentifier("rate_change_button", "id", application.packageName))
        fullscreenButton = findViewById(resources.getIdentifier("fullscreen_button", "id", application.packageName))
        closeButton = findViewById(resources.getIdentifier("close_button", "id", application.packageName))
        previewImageView = findViewById(resources.getIdentifier("imageView", "id", application.packageName))
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        releasePlayer()
        releaseAdsLoader()
        clearStartPosition()
        setIntent(intent)
    }

    @SuppressLint("SourceLockedOrientationActivity")
    override fun onStart() {
        super.onStart()

        playerView?.let {
            it.setControllerVisibilityListener(this)
            it.setErrorMessageProvider(PlayerErrorMessageProvider())
            it.requestFocus()
        }

        previewTimeBar?.apply {
            addOnScrubListener(PreviewChangeListener())
            // FIXME: サーバー側でminifyされたthumbnailが用意できれば解放する
//            setPreviewLoader(ImagePreviewLoader())
        }

        rateButton?.setOnClickListener {
            var rate = playbackRate
            when (playbackRate) {
                PLAYBACK_RATE_08 -> {
                    rate = PLAYBACK_RATE_10
                }
                PLAYBACK_RATE_10 -> {
                    rate = PLAYBACK_RATE_15
                }
                PLAYBACK_RATE_15 -> {
                    rate = PLAYBACK_RATE_08
                }
            }
            setPlaybackSpeed(rate)
        }

        fullscreenButton?.setOnClickListener {
            if (orientation == Configuration.ORIENTATION_PORTRAIT) {
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
                fullScreenToLandscape()
            } else {
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                fullScreenToPortrait()
            }
        }

        closeButton?.setOnClickListener {
            finish()
            releasePlayer()
        }

        dataSourceFactory = buildDataSourceFactory()

        initializePlayer()
        playerView?.apply {
            onResume()
        }
    }

    override fun onResume() {
        super.onResume()

        // fullscreen on landscape
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            fullScreenToLandscape()
        } else {
            fullScreenToPortrait()
        }

        if (Util.SDK_INT <= 23 || player == null) {
//            initializePlayer()
            playerView?.apply {
                onResume()
            }
        }
    }

    override fun onPause() {
        if (Util.SDK_INT <= 23) {
//            playerView?.apply {
//                onPause()
//            }
//            releasePlayer()
        }

        super.onPause()
    }

    override fun onStop() {
        super.onStop()
        if (Util.SDK_INT > 23) {
//            playerView?.apply {
//                onPause()
//            }
//            releasePlayer()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        playerNotificationManager?.setPlayer(null)
        releaseAdsLoader()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            initializePlayer()
        } else {
            showToast(resources.getIdentifier("storage_permission_denied", "string", application.packageName))
            finish()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        updateTrackSelectorParameters()
        updateStartPosition()

        outState.apply {
            putBoolean(KEY_AUTO_PLAY, startAutoPlay)
            putInt(KEY_WINDOW, startWindow)
            putLong(KEY_POSITION, startPosition)
            putParcelable(KEY_TRACK_SELECTOR_PARAMETERS, trackSelectorParameters)
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT) {
            fullScreenToPortrait()
        } else {
            fullScreenToLandscape()
        }
    }

    override fun onBackPressed() {
        //FIXME: pipModeで別タスク起動を解決できれば解放する
        super.onBackPressed()
        releasePlayer()
//        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
//                && packageManager.hasSystemFeature(FEATURE_PICTURE_IN_PICTURE)) {
//            enterPIPMode()
//        } else {
//            super.onBackPressed()
//        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        //FIXME: pipModeで別タスク起動を解決できれば解放する
//        enterPIPMode()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)

        if (!isInPictureInPictureMode) {
            playerView?.apply {
                useController = true
            }
            titleView?.apply {
                textSize = 32.0f
            }
        } else {
            playerView?.apply {
                useController = false
            }
            titleView?.apply {
                textSize = 10.0f
            }
        }
    }

    @Suppress("DEPRECATION")
    fun enterPIPMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
                && packageManager.hasSystemFeature(FEATURE_PICTURE_IN_PICTURE)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val params = PictureInPictureParams.Builder()
                this.enterPictureInPictureMode(params.build())
            } else {
                this.enterPictureInPictureMode()
            }
        }
    }

    private fun fullScreenToLandscape() {
        fullscreenButton?.setImageResource(resources.getIdentifier("ic_fullscreen_exit_white", "drawable", application.packageName))
        orientation = Configuration.ORIENTATION_LANDSCAPE

        playerView?.let {
            it.systemUiVisibility = (View.SYSTEM_UI_FLAG_LOW_PROFILE
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION)
        }
    }

    private fun fullScreenToPortrait() {
        fullscreenButton?.setImageResource(resources.getIdentifier("ic_fullscreen_white", "drawable", application.packageName))
        orientation = Configuration.ORIENTATION_PORTRAIT

        playerView?.let {
            it.systemUiVisibility = (View.SYSTEM_UI_FLAG_LOW_PROFILE
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION)
        }
    }

    private fun initializePlayer() {
        mediaSource = createTopLevelMediaSource()

        if (player == null) {
            lastSeenTrackGroupArray = null
            trackSelector = DefaultTrackSelector(this)
            trackSelector?.let { trackSelector ->
                trackSelectorParameters?.let {
                    trackSelector.parameters = it
                }

                player = SimpleExoPlayer.Builder(applicationContext)
                        .setTrackSelector(trackSelector)
                        .build()
                        .also {
                            it.setAudioAttributes(AudioAttributes.DEFAULT, true)
                            setPlaybackSpeed(playbackRate)
                            it.playWhenReady = startAutoPlay
                            it.addListener(PlayerEventListener())
                            it.addAnalyticsListener(EventLogger(trackSelector))
                            it.setWakeMode(1)
                            it.setForegroundMode(true)

                            playerView?.apply {
                                player = it
                                setPlaybackPreparer(this@PlayerActivity)
                            }

                            adsLoader?.apply {
                                setPlayer(it)
                            }

                            val haveStartPosition = startWindow != C.INDEX_UNSET
                            if (haveStartPosition) it.seekTo(startWindow, startPosition)

                            mediaSource?.let { mediaSource ->
                                it.prepare(mediaSource)
                            }

                            // 通知処理を追加する
                            val self = this
                            playerNotificationManager = PlayerNotificationManager.createWithNotificationChannel(
                                    this,
                                    application.packageName,
                                    R.string.exo_download_notification_channel_name,
                                    notificationId,
                                    object: PlayerNotificationManager.MediaDescriptionAdapter {
                                        override fun createCurrentContentIntent(player: Player): PendingIntent? {
                                            return null
                                        }
                                        override fun getCurrentContentTitle(player: Player): CharSequence {
                                            val media = self.getCurrentMedia()
                                            if (media != null) {
                                                updateTitleView()
                                                return media.title as CharSequence
                                            }
                                            else {
                                                return "title"
                                            }
                                        }
                                        override fun getCurrentContentText(player: Player): CharSequence? {
                                            return null
                                        }
                                        override fun getCurrentLargeIcon(player: Player, callback: PlayerNotificationManager.BitmapCallback): Bitmap? {
                                            return null
                                        }
                                    },
                                    // 通知コントローラー
                                    object: PlayerNotificationManager.NotificationListener {
                                        override fun onNotificationStarted(notificationId: Int, notification: Notification) {
                                            startBackgroundNotification(notificationId, notification)
                                        }
                                        override fun onNotificationCancelled(notificationId: Int, dismissedByUser: Boolean) {
                                            self.releasePlayer()
                                        }

                                        override fun onNotificationPosted(notificationId: Int, notification: Notification, ongoing: Boolean) {
                                            startBackgroundNotification(notificationId, notification)
                                        }
                            })
                            playerNotificationManager?.setPlayer(it)
                            val session = MediaSessionCompat(applicationContext, "nativeVideoPlayer")
                            session.isActive = true
                            val connector = MediaSessionConnector(session)
                            connector.setPlayer(it)
                            playerNotificationManager?.setMediaSessionToken(session.sessionToken)
                        }
            }
        }
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun startBackgroundNotification(notificationId: Int, notification: Notification) {
        val playerServiceIntent = Intent(this, PlayerService::class.java)
        playerServiceIntent.putExtra("notification", notification)
        playerServiceIntent.putExtra("notificationId", notificationId)

        if (Util.SDK_INT >= 26) {
          startForegroundService(playerServiceIntent)
        }

    }

    private fun getCurrentMedia() : MediaItem? {
        player?.let {  player ->
            items?.let {items ->
                return items[player.currentTag as Int]
            }
        }

        return null
    }

    private fun createTopLevelMediaSource() : ConcatenatingMediaSource {
        intent.getStringExtra(MediaItem.MEDIA_ITEMS_EXTRA)?.let {
            GsonBuilder().create().apply {
                items = fromJson(it, Array<MediaItem>::class.java).toList()
            }
        }

        var concatMediaSource = ConcatenatingMediaSource()
        playerView?.let {
            items?.forEachIndexed { index, item ->
                val url = Uri.parse(URLDecoder.decode(item.source, "UTF-8"))
                when (Util.inferContentType(url)) {
                    C.TYPE_HLS -> {
                        val mediaSource = HlsMediaSource
                                .Factory(dataSourceFactory)
                                .setTag(index)
                                .createMediaSource(url)
                        concatMediaSource.addMediaSource(mediaSource)
                    }
                    C.TYPE_OTHER -> {
                        val mediaSource = ProgressiveMediaSource
                                .Factory(dataSourceFactory)
                                .setTag(index)
                                .createMediaSource(url)
                        concatMediaSource.addMediaSource(mediaSource)
                    }
                    else -> {
                        //do nothing.
                    }
                }
            }
        }

        return concatMediaSource
    }

    private fun releasePlayer() {
        player?.apply {
            updateTrackSelectorParameters()
            updateStartPosition()
            release()
            player = null
            mediaSource = null
            trackSelector = null
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

    private fun updateTrackSelectorParameters() {
        trackSelector?.let {
            trackSelectorParameters = it.parameters
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

    private fun setPlaybackSpeed(rate : Float) {
        if (rate < 0.5 || rate > 2.0) {
            Log.w(TAG, "playback speed is invalid, speed = [" + rate + "]");
            return;
        }
        player?.let {
            val playbackParameters = it.playbackParameters;
            if (playbackParameters.speed != rate) {
                it.setPlaybackParameters(PlaybackParameters(rate));
                playbackRate = rate
            } else {
                Log.d(TAG, "playback speed is not changed!");
            }
        }
        rateButton?.text = String.format("x%.1f", rate)
    }

    private fun buildDataSourceFactory() : DataSource.Factory {
        val userAgent = Util.getUserAgent(applicationContext, applicationInfo.loadLabel(packageManager).toString())
        return DefaultDataSourceFactory(applicationContext,
                                        Util.getUserAgent(applicationContext, userAgent))
    }

    private fun getMimeType(url: String): String? {
        var extension:String
        var path = url
        if (url.startsWith("file://")) {
            val file = File(url.removePrefix("file://"))
            val name = file.name
            val ext = name.substring(name.lastIndexOf(".")).removePrefix(".")
            var type = when(ext) {
                "mp4" ->  "video/$ext"
                "mp3", "mp2", "mpga" -> "audio/mpeg"
                "wav" -> "audio/x-wav"
                "mpeg", "mpg", "mpe" -> "video/mpeg"
                else -> ""
            }
            return type

        }
        else {
            extension = MimeTypeMap.getFileExtensionFromUrl(path)
            extension?.let {
                return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            }
        }

        return null
    }

    private fun showControls() {
        controllerView?.apply {
            this.visibility = View.VISIBLE
        }
    }

    private fun showToast(messageId: Int) {
        showToast(getString(messageId))
    }

    private fun showToast(message: String) {
        Toast.makeText(applicationContext, message, Toast.LENGTH_LONG).show()
    }

    private inner class PlayerEventListener : Player.EventListener {
        override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
            when (playbackState) {

                Player.STATE_READY -> {
                        if (playWhenReady) {
                        previewTimeBar?.hidePreview()
                    }
                }
                Player.STATE_BUFFERING -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                Player.STATE_ENDED -> {
                    showControls()
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
            }
        }

        override fun onPlayerError(error: ExoPlaybackException) {
            if (isBehindLiveWindow(error)) {
                clearStartPosition()
                initializePlayer()
            } else {
                showControls()
            }
        }


        override fun onTracksChanged(trackGroups: TrackGroupArray, trackSelections: TrackSelectionArray) {
            if (trackGroups != lastSeenTrackGroupArray) {
                updateTitleView()
            }
            lastSeenTrackGroupArray = trackGroups
            playerNotificationManager
        }
    }

    private fun updateTitleView() {
        player?.let {  player ->
            items?.let {items ->
                val item = items[player.currentTag as Int]
                print(item)
                item.source?.let {
                    val mimeType = getMimeType(URLDecoder.decode(it, "UTF-8"))
                    if (mimeType != null && mimeType.startsWith("video")) {
                        titleView?.text = null
                        titleView?.visibility = View.INVISIBLE
                    } else {
                        titleView?.text = item.title
                        titleView?.visibility = View.VISIBLE
                    }
                }
            }
        }
    }

    private inner class PlayerErrorMessageProvider : ErrorMessageProvider<ExoPlaybackException> {
        override fun getErrorMessage(throwable: ExoPlaybackException): Pair<Int, String> {
            var errorString = getString(resources.getIdentifier("error_generic", "string", application.packageName))

            if (throwable.type == ExoPlaybackException.TYPE_RENDERER) {
                val cause = throwable.rendererException
                if (cause is MediaCodecRenderer.DecoderInitializationException) {
                    val decoderInitializationException = cause
                    decoderInitializationException.codecInfo?.also {
                        if (decoderInitializationException.cause is MediaCodecUtil.DecoderQueryException) {
                            errorString = getString(resources.getIdentifier("error_querying_decoders", "string", application.packageName))
                        } else if (decoderInitializationException.secureDecoderRequired) {
                            errorString = getString(
                                    resources.getIdentifier("error_no_secure_decoder", "string", application.packageName),
                                    decoderInitializationException.mimeType)
                        } else {
                            errorString = getString(
                                    resources.getIdentifier("error_no_decoder", "string", application.packageName),
                                    decoderInitializationException.mimeType)
                        }
                    } ?: run {
                        errorString = getString(
                                resources.getIdentifier("error_instantiating_decoder", "string", application.packageName),
                                decoderInitializationException.codecInfo?.name)
                    }
                }
            }

            return Pair.create(0, errorString)
        }
    }

    private inner class PreviewChangeListener : PreviewBar.OnScrubListener {
        override fun onScrubMove(previewBar: PreviewBar?, progress: Int, fromUser: Boolean) {
        }

        override fun onScrubStart(previewBar: PreviewBar?) {
            player?.playWhenReady = false
        }

        override fun onScrubStop(previewBar: PreviewBar?) {
            player?.playWhenReady = true
        }
    }

    private inner class ImagePreviewLoader : PreviewLoader {
        override fun loadPreview(currentPosition: Long, max: Long) {
            player?.let { player ->
                if (player.isPlaying) {
                    player.playWhenReady = false
                }
                items?.let { items ->
                    previewImageView?.let {
                        val item = items[player.currentTag as Int]
                        Glide.with(it)
                                .load(URLDecoder.decode(item.source, "UTF-8"))
                                .override(SIZE_ORIGINAL, SIZE_ORIGINAL)
                                .transform(GlideThumbnailTransformation(currentPosition))
                                .into(it)
                    }
                }
            }
        }
    }

    // MARK: - PlayerControlView.VisibilityListener

    override fun onVisibilityChange(visibility: Int) {
        controllerView?.visibility = visibility
    }

    // MARK: - PlaybackPreparer

    override fun preparePlayback() {
        player?.retry()
    }
}
