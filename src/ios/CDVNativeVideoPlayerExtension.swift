// 色定義
extension UIColor {
    static let playerColorMain = #colorLiteral(red: 0, green: 0.5333333333, blue: 0.5882352941, alpha: 1)
}
// 通知
extension Notification.Name {
    static let nativeVideoPlayerChangeVolume = Notification.Name("nativeVideoPlayerChangeVolume")
    static let nativeVideoPlayerChangeSpeed = Notification.Name("nativeVideoPlayerChangeSpeed")
    static let nativeVideoPlayerChangeToPip = Notification.Name("nativeVideoPlayerChangeToPip")
    static let nativeVideoPlayerChangeToFull = Notification.Name("nativeVideoPlayerChangeToFull")
    static let CDVNVPDidClose = Notification.Name("CDVNVPDidClose")
}
//UIStackView に 色をつける拡張
extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}
//UIView にアニメーションを追加する拡張
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