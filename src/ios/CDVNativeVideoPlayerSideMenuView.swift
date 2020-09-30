import UIKit
import Foundation
import AVFoundation

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
