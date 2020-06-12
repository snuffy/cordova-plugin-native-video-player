
var app = {
    // Application Constructor
    initialize: function() {
        document.addEventListener('deviceready', this.onDeviceReady.bind(this), false);
    },

    onDeviceReady: function() {
        this.receivedEvent('deviceready');
        
        // open video player
        const videoBtn = document.querySelector('.openVideoBtn');
        videoBtn.addEventListener('click', openVideo);
    },
};

app.initialize();

function openVideo () {
    NativeVideoPlayer.start([
        // 音声ファイル
        {
            title: 'タイトル1',
            album: 'アルバム1',
            source: encodeURIComponent('http://www.hochmuth.com/mp3/Haydn_Cello_Concerto_D-1.mp3')
        },
        // 動画ファイル
        {
            title: 'タイトル2',
            album: 'アルバム2',
            source: encodeURIComponent('https://dh2.v.netease.com/2017/cg/fxtpty.mp4')
        }, 
    ])
}