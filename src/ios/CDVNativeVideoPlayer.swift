import UIKit
import AVFoundation
import PIPKit
import SJVideoPlayer

@objc(CDVNativeVideoPlayer) class CDVNativeVideoPlayer : CDVPlugin {

    override func pluginInitialize() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            SJVideoPlayer.update { (settings) in
                settings.progress_thumbSize = 12;
            }
            
//            NotificationCenter.default.addObserver(self, selector: #selector(handleDidLayoutSubviews(notification:)), name: Notification.Name.CDVViewDidLayoutSubviews, object: nil)
//
            // for close event
            NotificationCenter.default.addObserver(self, selector: #selector(close), name: Notification.Name.CDVNVPDidClose, object: nil)
        }
        catch {
            // TODO error
        }

    };

    @objc func start(_ command: CDVInvokedUrlCommand) {
        
        // get media
        let data = command.argument(at: 0) as! [[String:String]]
        var playlist: [MediaItem] = []
        data.forEach { (item) in
            guard let title = item["title"]?.removingPercentEncoding,
                    let album = item["album"]?.removingPercentEncoding,
                    var source = item["source"]?.removingPercentEncoding
            else {
                return
            }
            
            // get source
            if let range = source.range(of: "file://") {
                source.replaceSubrange(range, with: "")
                print(source)
                let u = URL(fileURLWithPath:source)
                let m = MediaItem(title: title, album: album, source: u)
                playlist.append(m)
            }
            
        }

        let vc = VGMediaViewController()
        vc.playlist = playlist
        PIPKit.show(with: vc)
    }

    @objc func stop(_ command: CDVInvokedUrlCommand) {
        UIApplication.shared.isIdleTimerDisabled = false
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc func close(_ notification: Notification) {
        print("close!!!!")
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



