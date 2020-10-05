//
//  CDVNativeVideoPlayerViewController.swift
//  Example
//
//  Created by snuffy on 2020/04/30
//  Copyright © 2020年 snuffy. All rights reserved.
//

import UIKit
import PIPKit
import MediaPlayer
import Foundation

public struct MediaItem {
    var title: String
    var album: String
    var source: URL
}

class ControlSlider: UISlider {
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true // どんなtouchでもスライダー調節を行う
    }
    var currentThumbImageView: UIImageView? {
        guard let image = self.currentThumbImage else { return nil }
        return self.subviews.compactMap({ $0 as? UIImageView }).first(where: { $0.image == image })
    }
}


@available(iOS 11.0, *)
class CDVNativeVideoPlayerLayoutViewController: UIViewController, PIPUsable {
    var initialState: PIPState { return .full }
    var playlist: [MediaItem]?
    var videoPlayerView: VideoPlayerView?
    
    override func viewDidLoad() {
        view.backgroundColor = .black
        view.layer.cornerRadius = 0
        let videoPlayerView = VideoPlayerView()
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        videoPlayerView.backgroundColor = .black
        videoPlayerView.layer.cornerRadius = 0
        view.addSubview(videoPlayerView)
            NSLayoutConstraint.activate([
                videoPlayerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                videoPlayerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                videoPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                videoPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                videoPlayerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
                videoPlayerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                
            ])
        
        if playlist?.count ?? 0 > 0 {
            videoPlayerView.setPlaylist(playlist: playlist!)
        }
        
        self.videoPlayerView = videoPlayerView
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleChangeToPip), name: NSNotification.Name.nativeVideoPlayerChangeToPip, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleChangeToFull(notification:)), name: NSNotification.Name.nativeVideoPlayerChangeToFull, object: nil)

        // NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        // NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc private func handleChangeToPip(notification: Notification) {
        self.startPIPMode()
    }
    @objc private func handleChangeToFull(notification: Notification) {
        self.stopPIPMode()
    }
    
    
    func changeVideoTrackState(isEnabled: Bool){
        if let tracks = videoPlayerView?.player?.currentItem?.tracks {
          for playerItemTrack in tracks {
            // Find the video tracks.
            let assetTrack = playerItemTrack.assetTrack
            if assetTrack.hasMediaCharacteristic(.visual) {
              // Enable/Disable the track.
              playerItemTrack.isEnabled = isEnabled
            }
          }
      }
    }
    // フォアグラウンド移行時に呼び出される
    @objc func applicationDidEnterBackground(_ notifiaction: Notification){
        // changeVideoTrackState(isEnabled: false)
    }
    // バックグラウンド移行時に呼び出される
    @objc func applicationDidBecomeActive(_ notifiaction: Notification){
        // changeVideoTrackState(isEnabled: true)
    }
}
