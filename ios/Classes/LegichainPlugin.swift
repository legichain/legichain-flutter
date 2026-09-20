import Flutter
import UIKit

public final class LegichainPlugin: NSObject, FlutterPlugin {
    private var active = false
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel=FlutterMethodChannel(name:"legichain/kyc",binaryMessenger:registrar.messenger())
        registrar.addMethodCallDelegate(LegichainPlugin(),channel:channel)
    }
    public func handle(_ call: FlutterMethodCall,result: @escaping FlutterResult) {
        guard call.method=="start" else { result(FlutterMethodNotImplemented);return }
        DispatchQueue.main.async {
            guard !self.active else { result(FlutterError(code:"BUSY",message:"A KYC flow is already running",details:nil));return }
            guard let args=call.arguments as? [String:Any],let token=args["apiToken"] as? String,!token.isEmpty,
                  let url=URL(string:args["baseUrl"] as? String ?? "https://api.legichain.com"),url.scheme=="https" else {
                result(FlutterError(code:"INVALID_OPTIONS",message:"Invalid KYC options",details:nil));return
            }
            let windows=UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
            var host=windows.first(where: { $0.isKeyWindow })?.rootViewController
            while let presented=host?.presentedViewController { host=presented }
            guard let host else { result(FlutterError(code:"NO_ACTIVITY",message:"Foreground view required",details:nil));return }
            let screen=KycViewController(options:KycOptions(apiToken:token,baseURL:url,language:args["language"] as? String ?? "tr",application:args["application"] as? [String:Any] ?? [:]))
            self.active=true;screen.onComplete={ value in self.active=false;result(value.dictionary) };host.present(screen,animated:true)
        }
    }
}
