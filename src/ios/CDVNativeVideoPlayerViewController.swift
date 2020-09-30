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

extension UIColor {
    static let playerColorMain = #colorLiteral(red: 0, green: 0.5333333333, blue: 0.5882352941, alpha: 1)
}
// プレイヤーイベント周り
extension Notification.Name {
    static let nativeVideoPlayerChangeVolume = Notification.Name("nativeVideoPlayerChangeVolume")
    static let nativeVideoPlayerChangeSpeed = Notification.Name("nativeVideoPlayerChangeSpeed")
    static let nativeVideoPlayerChangeToPip = Notification.Name("nativeVideoPlayerChangeToPip")
    static let nativeVideoPlayerChangeToFull = Notification.Name("nativeVideoPlayerChangeToFull")
    static let CDVNVPDidClose = Notification.Name("CDVNVPDidClose")
}

extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}

// Side menu view
class SideMenuView: UIView {
        // video slider
    lazy var volumeSlider: ControlSlider = {
        let slider = ControlSlider()
        guard let image = CDVNVPResoucesLoader().getImage(named: "slider") else {return slider}
        slider.setThumbImage(image, for: .normal)
        let audioSession = AVAudioSession.sharedInstance()
        let volume = audioSession.outputVolume
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .playerColorMain
        slider.maximumTrackTintColor = .white
        slider.value = volume

        slider.addTarget(self, action: #selector(handleVolumeSliderChange), for: .valueChanged)
        return slider
    }()
    
    // 音量
    let volumeLabel: UILabel = {
        let label = UILabel()
        let audioSession = AVAudioSession.sharedInstance()
        let volume = audioSession.outputVolume
        let volumePercent = Int(volume * 100)
        label.text = "\(volumePercent)%"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        
        label.textAlignment = .center
        return label
    }()
    
    lazy var speedSlider: ControlSlider = {
        let slider = ControlSlider()
        guard let image = CDVNVPResoucesLoader().getImage(named: "slider") else {return slider}
        slider.setThumbImage(image, for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .playerColorMain
        slider.maximumTrackTintColor = .white
        slider.value = 0.5
        slider.addTarget(self, action: #selector(handleSpeedSliderChange), for: .valueChanged)
        return slider
    }()
        
    // 音量
    let speedLabel: UILabel = {
        let label = UILabel()
        label.text = "1x"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    // 輝度
    lazy var brightnessSlider: ControlSlider = {
        let slider = ControlSlider()
        guard let image = CDVNVPResoucesLoader().getImage(named: "slider") else {return slider}
        let currentBrightness = UIScreen.main.brightness
    
        slider.setThumbImage(image, for: .normal)
        let value = currentBrightness
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .playerColorMain
        slider.maximumTrackTintColor = .white
        slider.value = Float(value)
        slider.addTarget(self, action: #selector(handleBrightnessSliderChange), for: .valueChanged)
        return slider
    }()
    // 輝度
    let brightnessLabel: UILabel = {
        let currentBrightness = UIScreen.main.brightness
        let value = floor(currentBrightness * 100) / 100
        let label = UILabel()
        label.text = "\(value)"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        
        label.textAlignment = .center
        return label
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.8)
        
        // volume slider
        let volumeImage = CDVNVPResoucesLoader().getImage(named: "speaker")
        let volumeIcon = UIImageView(image: volumeImage)
        let volumeSliderStack = UIStackView(arrangedSubviews: [volumeIcon, volumeSlider, volumeLabel])
        volumeSliderStack.translatesAutoresizingMaskIntoConstraints = false
        volumeSliderStack.axis = .horizontal
        volumeSliderStack.alignment = .center
        volumeSliderStack.distribution = .fill
        volumeSliderStack.spacing = 12
        NSLayoutConstraint.activate([
            volumeLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        // スピード
        let speedImage = CDVNVPResoucesLoader().getImage(named: "speed")
        let speeedIcon = UIImageView(image: speedImage)
        let speedSliderStack = UIStackView(arrangedSubviews: [speeedIcon, speedSlider, speedLabel])
        speedSliderStack.translatesAutoresizingMaskIntoConstraints = false
        speedSliderStack.axis = .horizontal
        speedSliderStack.alignment = .center
        speedSliderStack.distribution = .fill
        speedSliderStack.spacing = 12
        
        NSLayoutConstraint.activate([
            speedLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        
        // 輝度
        let brightnessImage = CDVNVPResoucesLoader().getImage(named: "brightness")
        let brightnessIcon = UIImageView(image: brightnessImage)
        let brightnessSliderStack = UIStackView(arrangedSubviews: [brightnessIcon, brightnessSlider, brightnessLabel])
        brightnessSliderStack.translatesAutoresizingMaskIntoConstraints = false
        brightnessSliderStack.axis = .horizontal
        brightnessSliderStack.alignment = .center
        brightnessSliderStack.distribution = .fill
        brightnessSliderStack.spacing = 12
        
        NSLayoutConstraint.activate([
            brightnessLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        let sliders = UIStackView(arrangedSubviews: [
            volumeSliderStack,
            speedSliderStack,
            brightnessSliderStack
        ])
        sliders.translatesAutoresizingMaskIntoConstraints = false
        sliders.axis = .vertical
        sliders.alignment = .fill
        sliders.distribution = .fill
        sliders.spacing = 20
        
        addSubview(sliders)
        NSLayoutConstraint.activate([
            sliders.centerXAnchor.constraint(equalTo: centerXAnchor),
            sliders.centerYAnchor.constraint(equalTo: centerYAnchor),
            sliders.widthAnchor.constraint(equalTo: widthAnchor, constant: -20)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleVolumeSliderChange() {
        let volumePercent = Int(volumeSlider.value * 100)
        volumeLabel.text = "\(volumePercent)%"
        NotificationCenter.default.post(name: .nativeVideoPlayerChangeVolume, object: nil, userInfo: ["value": volumeSlider.value])
    }
    
    @objc private func handleSpeedSliderChange() {
        let value = floor((speedSlider.value + 0.5) * 100) / 100
        speedLabel.text = "\(value)x"
        NotificationCenter.default.post(name: .nativeVideoPlayerChangeSpeed, object: nil, userInfo: ["value": speedSlider.value + 0.5])
    }
    
    @objc private func handleBrightnessSliderChange() {
        let value = floor((brightnessSlider.value) * 100) / 100
        brightnessLabel.text = "\(value)"
        UIScreen.main.brightness = CGFloat(brightnessSlider.value)
    }
    
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


extension UIView {
    func fadeIn(_ duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        self.transform = CGAffineTransform(translationX: 0, y: 300)
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { completed in
            completion(completed)
        })  }

    func fadeOut(_ duration: TimeInterval = 0.5, delay: TimeInterval = 1.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform(translationX: 0, y: 300)
    }, completion: completion)}
    // 入ってくる
    func leftIn(_ duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        self.transform = CGAffineTransform(translationX: 300, y: 0)
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { completed in
            completion(completed)
        })  }
    // 出す
    func leftOut(_ duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform(a: 1, b: 0,
                   c: 0, d: 1,
                   tx: 300, ty: 0)
    }, completion: completion)}
}


class VideoPlayerView: UIView, UIGestureRecognizerDelegate {
    var playlist: [MediaItem] = []
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPlay = false
    let resourceLoader = CDVNVPResoucesLoader()
    var gradientLayer: CAGradientLayer?
    var timer: Timer?
    var showControl = false
    var rate: Float = 1.0
    var currentIndex = 0
    // title text
    let pipTitleFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    let defualtTitleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
    
    let pauseImage = CDVNVPResoucesLoader().getImage(named: "pause")!
    let playImage = CDVNVPResoucesLoader().getImage(named: "play")!
    
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
    
    lazy var closeButton: UIButton = {
        var button = UIButton(type: .system)
        button.setTitle("閉じる", for: .normal)
        button.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 20.0)
        button.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var pipButton: UIButton = {
        let button = UIButton(type: .system)
        let image = CDVNVPResoucesLoader().getImage(named: "pipin")
        guard let pipinImage = image else {return button}
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(pipinImage, for: .normal)
        button.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7956095951)
        button.layer.cornerRadius = 20
        button.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        button.addTarget(self, action: #selector(handlePip), for: [.touchUpInside, .touchUpOutside])
        return button
    }()
    
    @objc private func handlePip() {
        if PIPKit.isPIP {
            closeButton.isHidden = false
            controlsStack.isHidden = false
//            pipButton.setImage(fullScreenImage, for: .normal)
            NotificationCenter.default.post(name: .nativeVideoPlayerChangeToFull, object: nil, userInfo: nil)
            titleTextView.font = defualtTitleFont
        }
        else {
            NotificationCenter.default.post(name: .nativeVideoPlayerChangeToPip, object: nil, userInfo: nil)
//                 pipButton.setImage(fullScreenImage, for: .normal)
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
        self.sideMenuView.isHidden = false
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
    
    private func setupGradientLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [0.1, 1.2]
        self.gradientLayer = gradientLayer
//        controlsStack.layer.addSublayer(gradientLayer)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerView()
        
        controlsContainerView.frame = frame
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
        
        // double tap gesture register
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        addGestureRecognizer(doubleTap)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        addGestureRecognizer(tap)

        setupGradientLayer()
        // バックグラウンドで再生するやつ
        addRemoteCommandEvent()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleChangeVolume(notification:)), name: NSNotification.Name.nativeVideoPlayerChangeVolume, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleChangeSpeed(notification:)), name: NSNotification.Name.nativeVideoPlayerChangeSpeed, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)

        
    }
    
    @objc func playerDidFinishPlaying() {
        nextVideo()
    }
    
    private func prevVideo() {
        if (currentIndex == 0) {return}
        currentIndex -= 1
        let prevVideo = playlist[currentIndex]
        let playerItem = AVPlayerItem(url: prevVideo.source)
        player?.replaceCurrentItem(with: playerItem)
        player?.playImmediately(atRate: rate)
        
        // セットしたら情報表示のため controls を表示する
        handleShowVideoCotnrol()
        
        updateTitleTextView()
        
        // updateNowPlayingInfo
        updateNowPlayingInfo()
        updateRemoteCommandCenter()
    }
    
    private func nextVideo() {
        // 次のビデオがない場合は最初に戻る
        if playlist.count-1 == currentIndex {
            currentIndex = 0
        }
        else {
            currentIndex = currentIndex + 1
        }
        
        let nextMusic = playlist[currentIndex]
        let playerItem = AVPlayerItem(url: nextMusic.source)
        player?.replaceCurrentItem(with: playerItem)
        player?.playImmediately(atRate: rate)
        
        // セットしたら情報表示のため controls を表示する
        handleShowVideoCotnrol()
        
        updateTitleTextView()
        
        // updateNowPlayingInfo
        updateNowPlayingInfo()
        updateRemoteCommandCenter()
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
    
    @objc func handleChangeVolume(notification: Notification) {
        guard let value = notification.userInfo?["value"] as? Float else {return}
        self.player?.volume = value
    }
    
    @objc func handleChangeSpeed(notification: Notification) {
        guard let value = notification.userInfo?["value"] as? Float else {return}
        self.player?.rate = value
        self.rate = value
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // single tap
    @objc func tapped() {
        handleShowVideoCotnrol()
        handleCloseSideMenu()
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
    
    @objc func doubleTapped() {
        handleToggle()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        playerLayer?.frame = self.bounds
        controlsContainerView.frame = self.bounds
        gradientLayer?.frame = self.bounds
    }
    
    public func setPlaylist(playlist: [MediaItem]) {
        self.playlist = playlist

        if playlist.count > 0 {
            currentIndex = 0
            let playerItem = AVPlayerItem(url: playlist[currentIndex].source)
            player?.replaceCurrentItem(with: playerItem)
            player?.playImmediately(atRate: rate)
            updateTitleTextView()
            // updateNowPlayingInfo
            updateNowPlayingInfo()
            updateRemoteCommandCenter()
            timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(onTimerEnd), userInfo: nil, repeats: false)
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
    
    private func setupPlayerView() {
        let player = AVPlayer()
        player.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        
        
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let interval = CMTime(seconds: 0.5, preferredTimescale: timeScale)
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
    
    // play and pause
    @objc private func handleToggle() {
        self.isPlay = !self.isPlay
        if !self.isPlay {
            isPlay = false
            toggleButton.setImage(playImage, for: .normal)
            player?.pause()
        }
        else {
            isPlay = true
            toggleButton.setImage(pauseImage, for: .normal)
            DispatchQueue.global().async { [weak self] in
                guard let self = self else {return}
                self.player?.playImmediately(atRate: self.rate)
            }
            
        }
        
        print(isPlay)
   
    }
    
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // ロードが終わると発火
        if keyPath == "currentItem.loadedTimeRanges" {
            activityIndicatorView.stopAnimating()
            controlsContainerView.backgroundColor = .clear
            toggleButton.isHidden = false
            isPlay = true
            
            if let duration = player?.currentItem?.duration {
                videoLengthLabel.text = getTimes(duration: duration)
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

    func remoteTogglePlayPause(_ event: MPRemoteCommandEvent) {
        if isPlay {
            player?.pause()
        }
        else {
            player?.play()
        }
    }

    func remotePlay(_ event: MPRemoteCommandEvent) {
        player?.play()
    }

    func remotePause(_ event: MPRemoteCommandEvent) {
        player?.pause()
    }

    func remoteNextTrack(_ event: MPRemoteCommandEvent) {
        nextVideo()
    }

    func remotePrevTrack(_ event: MPRemoteCommandEvent) {
        prevVideo()
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleChangeToFull(notification:)), name: NSNotification.Name.nativeVideoPlayerChangeToFull, object: nil)
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
    // フォアグラウンド移行時に呼び出されます
    @objc func applicationDidEnterBackground(_ notifiaction: Notification){
        changeVideoTrackState(isEnabled: false)
    }
    // バックグラウンド移行時に呼び出されます
    @objc func applicationDidBecomeActive(_ notifiaction: Notification){
        changeVideoTrackState(isEnabled: true)
    }
}
