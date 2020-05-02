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
        vc.stopPIPMode()
        self.viewController.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc func stop(_ command: CDVInvokedUrlCommand) {
        UIApplication.shared.isIdleTimerDisabled = false
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    
}


extension Notification.Name {
    static let closeButton = Notification.Name("notifyName")
}
