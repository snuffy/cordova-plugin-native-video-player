package jp.rabee

import com.google.gson.annotations.SerializedName
import java.net.URLDecoder

data class MediaItem(
        @SerializedName("title") var title: String? = null,
        @SerializedName("album") var album: String? = null,
        @SerializedName("source") var source: String? = null
)