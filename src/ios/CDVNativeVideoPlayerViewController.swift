//
//  CDVNativeVideoPlayerViewController.swift
//  Example
//
//  Created by snuffy on 2020/04/30
//  Copyright © 2020年 snuffy. All rights reserved.
//

import UIKit
import SnapKit
import PIPKit
import MediaPlayer
import SJUIKit
import SJVideoPlayer
import Masonry

public struct MediaItem {
    var title: String
    var album: String
    var source: URL
}

class VGMediaViewController: UIViewController, ConstraintRelatableTarget, PIPUsable {
    
    
    var portrateViewSize: CGRect?
    var player:SJVideoPlayer!
    var initialState: PIPState { return .full }
    var initialPosition: PIPPosition { return .bottomRight }
    
    let closeButton = UIButton(type: .custom)
    let pipButton = UIButton(type: .custom)
    let titleTextView = UILabel()
    let resourceLoader = CDVNVPResoucesLoader()
    let pipinImage = CDVNVPResoucesLoader().getImage(named: "pipin")!
    
    let shrinkScreenImage = SJVideoPlayerResourceLoader.imageNamed("sj_video_player_shrinkscreen")
    let fullScreenImage = SJVideoPlayerResourceLoader.imageNamed("sj_video_player_fullscreen")
    // font
    let defualtTitleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
    let pipTitleFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    
    let fullScreenGesture = SJPlayerGestureTypeMask(rawValue: SJPlayerGestureTypeMask_SingleTap.rawValue | SJPlayerGestureTypeMask_DoubleTap.rawValue)
    let pipScreenGesture = SJPlayerGestureTypeMask(rawValue: SJPlayerGestureTypeMask_DoubleTap.rawValue)
    // let media = MediaItem(title: "タイトル1", album: "アルバム1", source: URL(string: "http://www.hochmuth.com/mp3/Haydn_Cello_Concerto_D-1.mp3")! )
    // let media2 = MediaItem(title: "タイトル2", album: "アルバム3", source: URL(string: "http://www.hochmuth.com/mp3/Haydn_Cello_Concerto_D-1.mp3")!)
    // let media3 = MediaItem(title: "タイトル3", album: "アルバム2", source: URL(string: "https://dh2.v.netease.com/2017/cg/fxtpty.mp4")!)

    
    var playlist:[MediaItem] = []
    
    var currentIndex = 0
    
    var isRotating = false;
    
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {

//         playlist.append(media)
//         playlist.append(media2)
//         playlist.append(media3)
        
        player = SJVideoPlayer()
        player.pauseWhenAppDidEnterBackground = false;
        player.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.player.view)
        self.player.view.mas_makeConstraints { (make) in
            make?.edges.setOffset(0)
        }
        
        // 元の大きさをとっておく
        portrateViewSize = self.view.frame
        
        let first = playlist[currentIndex]
        player.urlAsset = SJVideoPlayerURLAsset(url: first.source)
        
        // プレイヤーの設定
        setupPlayerSettings()
        // クローズボタン
        createCloseButton()
        // PIP ボタン
        createPipButton()
        // タイトルの生成
        createTitleTextView()

        // remote commandEvent を作成
        addRemoteCommandEvent()
        // play 中の情報表示
        updateNowPlayingInfo()
        
        // 再生が終了したらよばれれる
        player.playbackObserver.playbackDidFinishExeBlock = {[weak self] _ in
            guard let self = self else {return}
            self.nextMedia()
            return
        }

    }
    
    private func showTitlePrompt() {
        // 最初に消してから呼ぶ
        player.prompt.hidden()
        let current = playlist[currentIndex]
        let ext = current.source.pathExtension
        // mp3 の時だけ出現させる
        if ext != "mp3" {return}
        
        let attributes: [NSAttributedString.Key : Any] = [
             .font : UIFont.systemFont(ofSize: 20, weight: .bold), // 文字色
             .foregroundColor : UIColor.white, // カラー
         ]
        let title = NSAttributedString(string: current.title, attributes: attributes)
        player.prompt.show(title, duration: 999999999999)
    }
    
    private func hideTitlePrompt() {
        player.prompt.hidden()
    }
    
    
    private func createCloseButton() {
        self.closeButton.setTitle("閉じる", for: .normal)
        self.closeButton.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 20.0)
        self.closeButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.closeButton.addTarget(self, action: #selector(self.tappedClose(_:)), for: .touchUpInside)
        self.closeButton.sizeToFit();
        self.view.addSubview(self.closeButton)
        self.closeButton.snp.makeConstraints { (make) in
            if #available(iOS 11, *) {
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(4)
            } else {
                make.top.equalTo(self.view)
            }
            make.left.equalTo(self.view.snp.left).offset(16)

        }
    }
    
    private func createPipButton() {
        self.pipButton.setImage(pipinImage, for: .normal)
        self.pipButton.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7956095951)
        self.pipButton.layer.cornerRadius = 20
        self.pipButton.titleEdgeInsets = UIEdgeInsetsMake(2.0, 6.0, 2.0, 6.0)
        self.pipButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        self.pipButton.addTarget(self, action: #selector(self.touchStart(_:)), for: .touchDown)
        self.pipButton.addTarget(self, action: #selector(self.tapToPip(_:)), for: [.touchUpInside, .touchUpOutside])
        
        self.view.addSubview(self.pipButton)
        self.pipButton.snp.makeConstraints { (make) in
            if #available(iOS 11, *) {
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(4)
            } else {
                make.top.equalTo(self.view)
            }
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.left.equalTo(self.view.snp.right).offset(-44)
        }
    }
    
    private func setupPlayerSettings() {
        player.defaultEdgeControlLayer.isHiddenBottomProgressIndicator = true
        // gesture control の設定
        player.gestureControl.supportedGestureTypes = fullScreenGesture
        // 1.5倍速
        player.rateWhenLongPressGestureTriggered = 1.5

        player.showMoreItemToTopControlLayer = true
        
        // 縦の時には戻るボタンは消す
        player.defaultEdgeControlLayer.isHiddenBackButtonWhenOrientationIsPortrait = true
        // 横向きのロックボタンは削除
        player.defaultEdgeControlLayer.leftAdapter.removeItem(forTag: SJEdgeControlLayerLeftItem_Lock)
        // 横向き more ボタンは削除
        player.defaultEdgeControlLayer.topAdapter.removeItem(forTag: SJEdgeControlLayerTopItem_More)
        // 自動回転のオン
        player.rotationManager.isDisabledAutorotation = false
        
        // 回転が始まる時
        player.rotationObserver.rotationDidStartExeBlock = { mgr in
            
            if (mgr.isFullscreen) {
                self.showTitlePrompt()
            }
            else {
                self.hideTitlePrompt()
            }
            
            self.pipButton.isEnabled = false;
            self.isRotating = true;
        }
        // 回転が終わった後
        player.rotationObserver.rotationDidEndExeBlock = { mgr in
            // 画面が元に戻った時に、サイズ調整をする
            if (!mgr.isFullscreen && !mgr.isTransitioning) {
                self.view.frame = self.portrateViewSize!
                self.view.superview?.frame = self.portrateViewSize!
                self.stopPIPMode()
            }
            self.pipButton.isEnabled = true;
            self.isRotating = false;
        }
        
        // 設定ボタンの配置
        let tune = resourceLoader.getImage(named: "settings")!
        let settingSwitchItem = SJEdgeControlButtonItem(image: tune, target: self, action: #selector(openMore), tag: 50)
        
        player.defaultEdgeControlLayer.bottomAdapter.add(settingSwitchItem)
        player.defaultEdgeControlLayer.bottomAdapter.reload()

    }

    // 音声の時はタイトルを出す
    private func createTitleTextView() {
        titleTextView.textColor = .white
        view.addSubview(titleTextView)
        titleTextView.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleTextView.textAlignment = .center
        titleTextView.numberOfLines = 3
        titleTextView.snp.makeConstraints { make in
            make.width.equalToSuperview().inset(10)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        updateTitleTextView()
    }
    
    // タイトルの更新を行う
    private func updateTitleTextView() {
        let current = playlist[currentIndex]
        let ext = current.source.pathExtension
        // mp3 だった時は出す
        if ext == "mp3" {
            titleTextView.isHidden = false
            titleTextView.text = current.title
            
            // 画面が横向きだった場合には、プロンプトタイトルを表示する
            if player.rotationManager.isFullscreen {
                showTitlePrompt()
            }
            // 画面が縦向きだった場合には、プロンプトタイトルを非表示に
            else {
                hideTitlePrompt()
            }
        }
        else {
            hideTitlePrompt()
            titleTextView.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.vc_viewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.vc_viewWillDisappear()
        player.assetURL = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.vc_viewDidDisappear()
        player.assetURL = nil
    }
    
    @objc func tappedClose(_ sender: UIButton) {
        player.controlLayerNeedAppear()
        PIPKit.dismiss(animated: true)
        player.assetURL = nil
        NotificationCenter.default.post(name: Notification.Name.CDVNVPDidClose, object: nil)
    }
    
    @objc func touchStart(_ sender: UIButton) {
        player.rotationManager.isDisabledAutorotation = true
    }
    @objc func tapToPip(_ sender: UIButton) {
        if PIPKit.isPIP {
            stopPIPMode()
            // 自動回転オン
            player.rotationManager.isDisabledAutorotation = false
            pipButton.setImage(pipinImage, for: .normal)
            closeButton.isHidden = false;
            player.defaultEdgeControlLayer.isHidden = false
            player.gestureControl.supportedGestureTypes = fullScreenGesture
            titleTextView.font = defualtTitleFont
        } else {
            startPIPMode()
            // 自動回転オフ
            player.rotationManager.isDisabledAutorotation = true
            pipButton.setImage(fullScreenImage, for: .normal)
            closeButton.isHidden = true;
            player.defaultEdgeControlLayer.isHidden = true
            player.gestureControl.supportedGestureTypes = pipScreenGesture
            titleTextView.font = pipTitleFont
        }
    }
    // more ボタンを押した時の挙動
    @objc func openMore() {
        self.player.switcher.switchControlLayer(forIdentitfier: SJControlLayer_MoreSettting)
    }
    // 次の音声を再生する
    func nextMedia() {
        if (playlist.count-1 == currentIndex) {return}
        currentIndex += 1
        // なければ何もしない
        let next = self.playlist[self.currentIndex]
        self.player.urlAsset = SJVideoPlayerURLAsset(url: next.source)
        self.player.play()
        // タイトルのアップデート
        updateTitleTextView()
        // update info
        updateNowPlayingInfo()
        updateRemoteCommandCenter()
    }
    // 一つ前の音声を再生する
    func prevMedia() {
        if (currentIndex == 0) {return}
        currentIndex -= 1
        let prev = self.playlist[self.currentIndex]
        self.player.urlAsset = SJVideoPlayerURLAsset(url: prev.source)
        self.player.play()
        // タイトルのアップデート
        updateTitleTextView()
        // update info
        updateNowPlayingInfo()
        updateRemoteCommandCenter()
    }
    
    func updateRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        let hasNext = (playlist.count-1 == currentIndex) ? false : true
        let hasPrev = (currentIndex == 0) ? false : true
        
        commandCenter.nextTrackCommand.isEnabled = hasNext
        commandCenter.previousTrackCommand.isEnabled = hasPrev
    }
    
    func updateNowPlayingInfo() {
        let currentMedia = playlist[currentIndex]
        let title = currentMedia.title
        let album = currentMedia.album
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        let image = UIImage(named: "ICON") ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
          return image
        })

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1.0)
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    // Remote Command Event
    func addRemoteCommandEvent() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false

        commandCenter.togglePlayPauseCommand.addTarget(handler: { [weak self] commandEvent -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}
            self.remoteTogglePlayPause(commandEvent)
            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.playCommand.addTarget(handler: { [weak self] commandEvent -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}
            self.remotePlay(commandEvent)
            return .success
        })
        commandCenter.pauseCommand.addTarget(handler: { [weak self] commandEvent -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}
            self.remotePause(commandEvent)
            return .success
        })
        
        commandCenter.nextTrackCommand.addTarget(handler: { [weak self] commandEvent -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}
            self.remoteNextTrack(commandEvent)
            return .success
        })
        commandCenter.previousTrackCommand.addTarget(handler: { [weak self] commandEvent -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}
            self.remotePrevTrack(commandEvent)
            return .success
        })
        
        updateRemoteCommandCenter()
    }

    func remoteTogglePlayPause(_ event: MPRemoteCommandEvent) {
        if (player.isPlaying) {
            player.pause()
        }
        else {
            player.play()
        }
    }

    func remotePlay(_ event: MPRemoteCommandEvent) {
        player.play()
    }

    func remotePause(_ event: MPRemoteCommandEvent) {
        player.pause()
    }

    func remoteNextTrack(_ event: MPRemoteCommandEvent) {
        nextMedia()
    }

    func remotePrevTrack(_ event: MPRemoteCommandEvent) {
        prevMedia()
    }
    
    
}


extension Notification.Name {
    static let CDVNVPDidClose = Notification.Name("CDVNVPDidClose")
}
