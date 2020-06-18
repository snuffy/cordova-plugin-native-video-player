package jp.rabee

import android.graphics.Bitmap
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool
import com.bumptech.glide.load.resource.bitmap.BitmapTransformation
import java.nio.ByteBuffer
import java.security.MessageDigest

class GlideThumbnailTransformation(position : Long) : BitmapTransformation() {

    private val x : Int = (position.toInt() / THUMBNAILS_EACH) % MAX_COLUMNS
    private val y : Int = (position.toInt() / THUMBNAILS_EACH) / MAX_LINES

    companion object {
        private const val MAX_LINES = 7
        private const val MAX_COLUMNS = 7
        private const val THUMBNAILS_EACH = 5000
    }

    override fun transform(pool: BitmapPool, toTransform: Bitmap, outWidth: Int, outHeight: Int): Bitmap {
        val width = toTransform.width / MAX_COLUMNS
        val height = toTransform.height / MAX_LINES
        return Bitmap.createBitmap(toTransform, x * width, y * height, width, height)
    }

    override fun updateDiskCacheKey(messageDigest: MessageDigest) {
        val data = ByteBuffer.allocate(8).putInt(x).putInt(y).array()
        messageDigest.update(data)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other == null || javaClass != other.javaClass) return false

        val that = other as GlideThumbnailTransformation

        if (x != that.x) return false
        return y == that.y
    }

    override fun hashCode(): Int {
        var result = x
        result = 31 * result + y
        return result
    }
}