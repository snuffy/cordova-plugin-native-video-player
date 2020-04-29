

@objc(CDVNativeVideoPlayer) class CDVNativeVideoPlayer : CDVPlugin {
  override func pluginInitialize() {};

  @objc func start(_ command: CDVInvokedUrlCommand) {
    UIApplication.shared.isIdleTimerDisabled = true
    let result = CDVPluginResult(status: CDVCommandStatus_OK)
    commandDelegate.send(result, callbackId: command.callbackId)
  }

  @objc func stop(_ command: CDVInvokedUrlCommand) {
    UIApplication.shared.isIdleTimerDisabled = false
    let result = CDVPluginResult(status: CDVCommandStatus_OK)
    commandDelegate.send(result, callbackId: command.callbackId)
  }
}
