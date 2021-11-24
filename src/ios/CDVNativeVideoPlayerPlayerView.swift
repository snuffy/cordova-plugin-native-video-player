
import UIKit
import PIPKit
import MediaPlayer
import Foundation

class VideoPlayerView: UIView, UIGestureRecognizerDelegate {
    var playlist: [MediaItem] = []
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPlay = false
    let resourceLoader = CDVNVPResoucesLoader()
    var timer: Timer?
    var showControl = false
    var rate: Float = 1.0
    var currentIndex = 0
    var isBackground = false
    // title text
    let pipTitleFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    let defualtTitleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
    
    let pauseImage = CDVNVPResoucesLoader().getImage(named: "pause")!
    let playImage = CDVNVPResoucesLoader().getImage(named: "play")!
    
    let pipinImage = CDVNVPResoucesLoader().getImage(named: "pipin")!
    let fullScreenImage = CDVNVPResoucesLoader().getImage(named: "fullscreen")!
    
    var defaultRotateValue : Int = UIInterfaceOrientation.portrait.rawValue
    
    let titleTextView: UILabel = {
        var textView = UILabel()
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        textView.textAlignment = .center
        textView.numberOfLines = 3
        textView.lineBreakMode = .byTruncatingTail
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    let sideMenuView: SideMenuView = {
        let view = SideMenuView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.transform = CGAffineTransform(a: 1, b: 0,
        c: 0, d: 1,
        tx: 300, ty: 0)
        view.isHidden = true
        
        return view
    }()
    // コントロールのコンテナ
    let controlsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 1)
        return view
    }()
    // ポーズボタン
    lazy var toggleButton: UIButton = {
        
        let button = UIButton(type: .custom)
        button.isHidden = true
        guard let image = resourceLoader.getImage(named: "pause") else {return button}
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.tintColor = .white
        
        return button
    }()
    // インジケーター
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.startAnimating()
        return aiv
    }()
    // 設定ボタン
    lazy var settingButton: UIButton = {
        let button = UIButton(type: .system)
        guard let image = resourceLoader.getImage(named: "settings") else {return button}
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleOpenSideMenu), for: .touchUpInside)
        return button
    }()
    
    // 再生時間
    let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 11)
        
        label.textAlignment = .center
        return label
    }()
    // 総再生時間
    let videoLengthLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.textAlignment = .center
        return label
    }()
    
    // video slider
    lazy var videoSlider: ControlSlider = {
        let slider = ControlSlider()
        guard let image = resourceLoader.getImage(named: "slider") else {return slider}
        slider.setThumbImage(image, for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .playerColorMain
        slider.maximumTrackTintColor = .white
        slider.currentThumbImageView?.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        slider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        return slider
    }()
    // 回転ボタン
    lazy var rotationButton: UIButton = {
        let button = UIButton(type: .system)
        guard let image = resourceLoader.getImage(named: "rotation") else {return button}
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: #selector(handleChangeRotation), for: .touchUpInside)
        return button
    }()
    // video コントローラー
    lazy var controlsStack: UIStackView = {
        // control stack
        let controlsStack = UIStackView(arrangedSubviews: [
            toggleButton,
            currentTimeLabel,
            videoLengthLabel,
            videoSlider,
            rotationButton,
            settingButton,
        ])
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.axis = .horizontal
        controlsStack.alignment = .center
        controlsStack.distribution = .fill
        controlsStack.spacing = 6
        controlsStack.heightAnchor.constraint(equalToConstant: 50).isActive = true
        controlsStack.addBackground(color: UIColor(white: 0, alpha: 0.3))
        return controlsStack
    }()
    // 閉じるボタン
    lazy var closeButton: UIButton = {
        var button = UIButton(type: .system)
        button.setTitle("閉じる", for: .normal)
        button.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 20.0)
        button.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    // pip button
    lazy var pipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(pipinImage, for: .normal)
        button.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7956095951)
        button.layer.cornerRadius = 20
        button.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        button.addTarget(self, action: #selector(handlePip), for: [.touchUpInside, .touchUpOutside])
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        controlsContainerView.frame = frame
        // setup player
        setupPlayer()
        // setup auto layout
        setupLayout() 
        // double tap gesture register
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        addGestureRecognizer(doubleTap)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        addGestureRecognizer(tap)
        
        // デフォルトの向きを入れる
        defaultRotateValue = UIDevice.current.orientation.rawValue

        // バックグラウンドで再生する処理のセットアップ
        addRemoteCommandEvent()
        
        // 通知オブザーバーのセットアップ
        setupNotificationObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // レイアウト処理の override
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
        controlsContainerView.frame = self.bounds
    }

    // play and pause
    @objc private func handleToggle() {
        if isPlay {
            pause()
        }
        else {
            play()
        }
    }

    // toggle pip
    @objc private func handlePip() {
        if PIPKit.isPIP {
            closeButton.isHidden = false
            controlsStack.isHidden = false
            pipButton.setImage(pipinImage, for: .normal)
            NotificationCenter.default.post(name: .nativeVideoPlayerChangeToFull, object: nil, userInfo: nil)
            titleTextView.font = defualtTitleFont
        }
        else {
            NotificationCenter.default.post(name: .nativeVideoPlayerChangeToPip, object: nil, userInfo: nil)
            pipButton.setImage(fullScreenImage, for: .normal)
            closeButton.isHidden = true
            controlsStack.isHidden = true
            handleCloseSideMenu()
            titleTextView.font = pipTitleFont
        }
    }
    
    @objc private func handleClose() {
        PIPKit.dismiss(animated: true)
        player?.replaceCurrentItem(with: nil)
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        
//      向きを元に戻す
        UIDevice.current.setValue(defaultRotateValue, forKey: "orientation")
        player = nil
    }
    
    @objc private func handleChangeRotation() {
        let current = UIApplication.shared.statusBarOrientation
        var value = UIInterfaceOrientation.landscapeRight.rawValue
        if current.isLandscape {
            value = UIInterfaceOrientation.portrait.rawValue
        }
        
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    @objc func handleSliderChange() {
        if let duration = player?.currentItem?.duration {
            let totalSecounds = CMTimeGetSeconds(duration)
            let value = Float64(videoSlider.value) * totalSecounds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player?.seek(to: seekTime)
        }
    }
    
    @objc func handleOpenSideMenu() {
        sideMenuView.isHidden = false
        sideMenuView.leftIn()
    }
    
    private func startTimer() {
        if let timer = timer {
            timer.invalidate()
        }
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(onTimerEnd), userInfo: nil, repeats: false)
    }

    @objc func onTimerEnd() {
        controlsStack.fadeOut(completion: { _ in
            self.showControl = false
        })
    }
    
    
    // プレイヤーが終了した時
    @objc func playerDidFinishPlaying() {
        nextVideo()
    }

    private func nextVideo() {
        // 次のビデオがない場合は何もしない
        if playlist.count-1 == currentIndex {
            return
        }
        else {
            currentIndex = currentIndex + 1
        }
        
        let nextMusic = playlist[currentIndex]
        let playerItem = AVPlayerItem(url: nextMusic.source)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        player?.replaceCurrentItem(with: playerItem)
        player?.playImmediately(atRate: rate)
        
        // セットしたら情報表示のため controls を表示する
        handleShowVideoCotnrol()
        
        updateTitleTextView()
        
        // updateNowPlayingInfo
        updateNowPlayingInfo()
        updateRemoteCommandCenter()
    }

    private func prevVideo() {
        if (currentIndex == 0) {return}
        currentIndex -= 1
        let prevVideo = playlist[currentIndex]
        let playerItem = AVPlayerItem(url: prevVideo.source)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        player?.replaceCurrentItem(with: playerItem)
        player?.playImmediately(atRate: rate)
        
        // セットしたら情報表示のため controls を表示する
        handleShowVideoCotnrol()
        
        updateTitleTextView()
        
        // updateNowPlayingInfo
        updateNowPlayingInfo()
        updateRemoteCommandCenter()
    }
    
    // single tap
    @objc func tapped() {
        handleShowVideoCotnrol()
        handleCloseSideMenu()
    }
    // double tap
    @objc func doubleTapped() {
        handleToggle()
    }
    
    @objc func handleChangeVolume(notification: Notification) {
        guard let value = notification.userInfo?["value"] as? Float else {return}
        self.player?.volume = value
    }
    
    @objc func handleChangeSpeed(notification: Notification) {
        guard let value = notification.userInfo?["value"] as? Float else {return}
        self.player?.rate = value
        self.rate = value
        
    }
    private func handleShowVideoCotnrol() {
        if !showControl {
            controlsStack.fadeIn()
            showControl = true
        }
        startTimer()
    }
    private func handleCloseSideMenu() {
        if !sideMenuView.isHidden {
            sideMenuView.leftOut(completion: { [weak self] _ in
                guard let self = self else {return}
                self.sideMenuView.isHidden = true
            })
        }
    }
    
    public func setPlaylist(playlist: [MediaItem]) {
        self.playlist = playlist

        if playlist.count > 0 {
            currentIndex = 0
            let playerItem = AVPlayerItem(url: playlist[currentIndex].source)
            playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
            player?.replaceCurrentItem(with: playerItem)
            player?.playImmediately(atRate: rate)
            updateTitleTextView()
            // updateNowPlayingInfo
            updateNowPlayingInfo()
            updateRemoteCommandCenter()
            timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(onTimerEnd), userInfo: nil, repeats: false)
            isPlay = true
        }
    }
    
    private func updateTitleTextView() {
        let current = playlist[currentIndex]
        let ext = current.source.pathExtension
        // mp3 だった時は出す
        if ext == "mp3" {
            titleTextView.isHidden = false
            titleTextView.text = current.title
        }
        else {
            titleTextView.isHidden = true
        }
    }

    private func setupLayout() {
        addSubview(controlsContainerView)
        
        // ロードインジケーター
        controlsContainerView.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // コントロールバー
        controlsContainerView.addSubview(controlsStack)
        NSLayoutConstraint.activate([
            controlsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            controlsStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -24),
            controlsStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 24)
        ])
        // 再生時間
        NSLayoutConstraint.activate([
            videoLengthLabel.widthAnchor.constraint(equalToConstant: 40),
            videoLengthLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        // 現在時間
        NSLayoutConstraint.activate([
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 45),
            currentTimeLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        // ポーズボタン
        toggleButton.addTarget(self, action: #selector(handleToggle), for: [.touchUpInside, .touchUpOutside])
        NSLayoutConstraint.activate([
            toggleButton.widthAnchor.constraint(equalToConstant: 30),
            toggleButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        NSLayoutConstraint.activate([
            settingButton.widthAnchor.constraint(equalToConstant: 24),
            settingButton.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        NSLayoutConstraint.activate([
             rotationButton.widthAnchor.constraint(equalToConstant: 24),
             rotationButton.heightAnchor.constraint(equalToConstant: 24),
         ])
        
        
        controlsContainerView.addSubview(closeButton)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                closeButton.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 18)
            ])
        }
        controlsContainerView.addSubview(pipButton)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                pipButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                pipButton.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -18),
                pipButton.widthAnchor.constraint(equalToConstant: 40),
                pipButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
        
        // 音楽の時のラベル
        controlsContainerView.addSubview(titleTextView)
        NSLayoutConstraint.activate([
            titleTextView.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleTextView.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleTextView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            titleTextView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16)
        ])
        
        // sidemenu
        controlsContainerView.addSubview(sideMenuView)
        NSLayoutConstraint.activate([
            sideMenuView.widthAnchor.constraint(equalToConstant: 300),
            sideMenuView.heightAnchor.constraint(equalTo: heightAnchor),
            sideMenuView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
        
    }

    private func setupNotificationObserver() {
        // ボリュームやスピードが変わった
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleChangeVolume(notification:)), name: NSNotification.Name.nativeVideoPlayerChangeVolume, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleChangeSpeed(notification:)), name: NSNotification.Name.nativeVideoPlayerChangeSpeed, object: nil)

        // プレイヤーの再生が終わった
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)

        // バックグラウンド関係
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    private func setupPlayer() {
        let player = AVPlayer()
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let interval = CMTime(seconds: 0.5, preferredTimescale: timeScale)

        player.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] progress in
            guard let self = self else {return}
            let seconds = CMTimeGetSeconds(progress)
            let times = self.getTimes(duration: progress)
            self.currentTimeLabel.text = "\(times) /"
            if let duration = self.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                self.videoSlider.value = Float(seconds / durationSeconds)
            }
        })
        
        self.player = player
        playerLayer = AVPlayerLayer(player: self.player)
        self.layer.addSublayer(playerLayer!)
    }
    

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // 動画のロードが終わると発火する
        if keyPath == "currentItem.loadedTimeRanges" {
            activityIndicatorView.stopAnimating()
            controlsContainerView.backgroundColor = .clear
            toggleButton.isHidden = false
            if let duration = player?.currentItem?.duration {
                videoLengthLabel.text = getTimes(duration: duration)
            }
        }
        // バックグラウンドに入った時に、再生がストップするのを防止する
        if keyPath == #keyPath(AVPlayerItem.playbackLikelyToKeepUp) {
            guard let item = object as? AVPlayerItem else {return}
            if isBackground, isPlay {
                guard let player = self.player else {return}
                if player.currentItem == item {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        guard let self = self else {return}
                        player.playImmediately(atRate: self.rate)
                    }
                }
            }
        }
    }
    
    private func getTimes(duration: CMTime) -> String {
        let duration = CMTimeGetSeconds(duration)
        let seconds = duration.truncatingRemainder(dividingBy: 60)
        let minute = (duration / 60)
        guard !seconds.isNaN && !minute.isNaN else {
            return "00:00"
        }
        
        var secondsText = String(Int(seconds))
        var minuteText = String(Int(minute))
        
        if seconds < 10 {
            secondsText = "0\(Int(seconds))"
        }
        if minute < 10 {
            minuteText = "0\(Int(minute))"
        }
        
        return "\(minuteText):\(secondsText)"
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

    private func play() {
        guard let player = self.player else {return}
        toggleButton.setImage(pauseImage, for: .normal)
        player.playImmediately(atRate: rate)
        isPlay = true
    }
    
    private func pause() {
        guard let player = self.player else {return}
        toggleButton.setImage(playImage, for: .normal)
        player.pause()
        isPlay = false
    }

    func remoteTogglePlayPause(_ event: MPRemoteCommandEvent) {
        handleToggle()
    }

    func remotePlay(_ event: MPRemoteCommandEvent) {
        play()
    }

    func remotePause(_ event: MPRemoteCommandEvent) {
        pause()
    }

    func remoteNextTrack(_ event: MPRemoteCommandEvent) {
        nextVideo()
    }

    func remotePrevTrack(_ event: MPRemoteCommandEvent) {
        prevVideo()
    }

        // フォアグラウンド移行時
    @objc func applicationDidEnterBackground(_ notifiaction: Notification){
        isBackground = true
    }
    // バックグラウンド移行時
    @objc func applicationDidBecomeActive(_ notifiaction: Notification){
        isBackground = false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if  touch.view == self.sideMenuView ||
            touch.view == self.sideMenuView.speedSlider ||
            touch.view == self.sideMenuView.volumeSlider
        {
            return false
        }
        return true
    }
    
}
