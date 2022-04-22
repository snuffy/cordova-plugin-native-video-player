# cordova-plugin-native-video-player

add activity to config.xml

```xml
<platform name="android">
    <config-file target="AndroidManifest.xml" parent="/manifest/application">
        <activity
            android:configChanges="keyboard|keyboardHidden|orientation|screenSize|screenLayout|smallestScreenSize|uiMode"
            android:name="jp.rabee.PlayerActivity"
            android:theme="@style/PlayerTheme"
            android:label="PlayerActivity"
            android:launchMode="singleTask"
            android:resizeableActivity="true"
            android:supportsPictureInPicture="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
        </activity>
    </config-file>
</platform>
```
