import UIKit
import Foundation
import AVFoundation

@available(iOS 8.0, *)
@objc(HWPQRCodeScanner) class QRCodeScannerPlugin : CDVPlugin {
    var scanCommand:CDVInvokedUrlCommand?
    
	func scan(command: CDVInvokedUrlCommand) {
		//var message = command.arguments[0] as String
		scanCommand=command
        
		//设置扫码区域参数
        var style = LBXScanViewStyle()
        style.centerUpOffset = 44;
        style.photoframeAngleStyle = LBXScanViewPhotoframeAngleStyle.On;
        style.photoframeLineW = 6;
        style.photoframeAngleW = 24;
        style.photoframeAngleH = 24;
        style.isNeedShowRetangle = true;
        
        style.anmiationStyle = LBXScanViewAnimationStyle.NetGrid;
        
        
        //矩形框离左边缘及右边缘的距离
        style.xScanRetangleOffset = 80;
        
        //使用的支付宝里面网格图片
        style.animationImage = UIImage(named: "CDVQRCodeScanner.bundle/qrcode_scan_part_net")
        
        let vc = LBXScanViewController();
        vc.scanStyle = style
        
        
        vc.isOpenInterestRect = true
        vc.callBack=callBack

		self.viewController?.presentViewController(vc, animated: true,completion: nil)

		
	}
    
    func callBack(codeType:String?,codeResult:String?,isCancelled:Bool) -> Void {
        self.viewController?.dismissViewControllerAnimated(false, completion: nil)
             let result=NSMutableDictionary()
        result.setValue(codeType, forKey: "format")
        result.setValue(codeResult, forKey: "text")
        result.setValue(isCancelled, forKey: "cancelled")
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: result as [NSObject : AnyObject])
        commandDelegate.sendPluginResult(pluginResult, callbackId:scanCommand!.callbackId)
    }
}
