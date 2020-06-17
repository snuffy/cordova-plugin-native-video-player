package jp.rabee

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ui.PlayerNotificationManager
import jp.snuffy.nativeVideoPlayerTest.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

const val NOW_PLAYING_CHANNEL = "jp.rabee.NotificationManager.NOW_PLAYING"
const val NOW_PLAYING_NOTIFICATION = 0xb339

class NotificationManager(
        private val context: Context,
        private val player: ExoPlayer,
        sessionToken: MediaSessionCompat.Token,
        notificationListener: PlayerNotificationManager.NotificationListener
) {

    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.Main + serviceJob)
    private val notificationManager: PlayerNotificationManager
    private val platformNotificationManager: NotificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        val mediaController = MediaControllerCompat(context, sessionToken)

        notificationManager = PlayerNotificationManager.createWithNotificationChannel(
                context,
                NOW_PLAYING_CHANNEL,
                R.string.notification_channel,
                NOW_PLAYING_NOTIFICATION,
                DescriptionAdapter(mediaController),
                notificationListener
        ).apply {

            setMediaSessionToken(sessionToken)
            setSmallIcon(R.drawable.ic_notification)

            // Don't display the rewind or fast-forward buttons.
            setRewindIncrementMs(0)
            setFastForwardIncrementMs(0)
        }
    }

    fun hideNotification() {
        notificationManager.setPlayer(null)
    }

    fun showNotification() {
        notificationManager.setPlayer(player)
    }

    private inner class DescriptionAdapter(private val controller: MediaControllerCompat) :
            PlayerNotificationManager.MediaDescriptionAdapter {

        var currentIconUri: Uri? = null
        var currentBitmap: Bitmap? = null

        override fun createCurrentContentIntent(player: Player): PendingIntent? =
                controller.sessionActivity

        override fun getCurrentContentText(player: Player): CharSequence? =
                controller.metadata.description.subtitle.toString()


        override fun getCurrentContentTitle(player: Player): CharSequence =
                controller.metadata.description.title.toString()

        override fun getCurrentLargeIcon(player: Player, callback: PlayerNotificationManager.BitmapCallback): Bitmap? {
            val iconUri = controller.metadata.description.iconUri
            return if (currentIconUri != iconUri || currentBitmap == null) {

                // Cache the bitmap for the current song so that successive calls to
                // `getCurrentLargeIcon` don't cause the bitmap to be recreated.
                currentIconUri = iconUri
                serviceScope.launch {
                    currentBitmap = iconUri?.let {
                        resolveUriAsBitmap(it)
                    }
                    currentBitmap?.let { callback.onBitmap(it) }
                }
                null
            } else {
                currentBitmap
            }
        }

        private suspend fun resolveUriAsBitmap(uri: Uri): Bitmap? {
            return withContext(Dispatchers.IO) {
                val parcelFileDescriptor =
                        context.contentResolver.openFileDescriptor(uri, MODE_READ_ONLY)
                                ?: return@withContext null
                val fileDescriptor = parcelFileDescriptor.fileDescriptor
                BitmapFactory.decodeFileDescriptor(fileDescriptor).apply {
                    parcelFileDescriptor.close()
                }
            }
        }
    }

}

private const val MODE_READ_ONLY = "r"