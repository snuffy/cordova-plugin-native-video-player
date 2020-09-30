import UIKit
import AVFoundation
import PIPKit

@objc(CDVNativeVideoPlayer) class CDVNativeVideoPlayer : CDVPlugin {

    override func pluginInitialize() {
        // setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            // for close event
            NotificationCenter.default.addObserver(self, selector: #selector(close), name: Notification.Name.CDVNVPDidClose, object: nil)
        }
        catch {
            // TODO error
        }
    };

    @objc func start(_ command: CDVInvokedUrlCommand) {
        // js から受け取った playlist を [MediaItem] に変換
        let data = command.argument(at: 0) as! [[String:String]]
        var playlist: [MediaItem] = []
        data.forEach { (item) in
            guard let title = item["title"]?.removingPercentEncoding,
                let album = item["album"]?.removingPercentEncoding,
                let source = item["source"]?.removingPercentEncoding
            else {return}
            
            // source が web なのか file なのかを判定する
            let regularURL = source.replacingOccurrences(of: "file://", with: "")
            var url: URL?
            //
            if regularURL.contains("http://") || regularURL.contains("https://") {
                url = URL(string: regularURL)
            }
            else {
                url = URL(fileURLWithPath: regularURL)
            }
            guard let sourceURL = url else {return}
            
            let m = MediaItem(title: title, album: album, source: sourceURL)
            playlist.append(m)
        }
        
        if #available(iOS 11.0, *) {
            let vc = CDVNativeVideoPlayerLayoutViewController()
            vc.playlist = playlist
            PIPKit.show(with: vc)
        }
    }

    @objc func stop(_ command: CDVInvokedUrlCommand) {
        UIApplication.shared.isIdleTimerDisabled = false
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc func close(_ notification: Notification) {
        resetWebviewSize()
    }
    
    @objc private func handleDidLayoutSubviews(notification: Notification) {
        resetWebviewSize()
    }
    
    private func resetWebviewSize() {
        if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_7_1 && NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            return;
        }
        
        if (!(viewController.isViewLoaded && viewController.view?.window != nil)) {
            return;
        }
        
        guard let frame = webView.superview?.frame else {return}
        webView.frame = frame
    }
    
}
