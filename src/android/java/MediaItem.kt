package jp.rabee

import com.google.gson.annotations.SerializedName

data class MediaItem(
        @SerializedName("title") var title: String? = null,
        @SerializedName("album") var album: String? = null,
        @SerializedName("source") var source: String? = null
) {
    companion object {
        val MEDIA_ITEMS_EXTRA = "media_items_extra"
    }
}