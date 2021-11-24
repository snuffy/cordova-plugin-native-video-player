package jp.rabee

import android.app.Notification
import android.app.Service
import android.content.Intent
import android.os.IBinder

class PlayerService: Service() {
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // foreground service of video player
        val notification = intent?.getParcelableExtra("notification") as Notification?
        val notificationId = intent?.getIntExtra("notificationId", 0)
        if (notification != null && notificationId != 0) {
            if (notificationId != null) {
                startForeground(notificationId, notification)
            }
        }
        else {
            stopSelf()
        }
        return START_STICKY
    }

}