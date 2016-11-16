import UIKit
import Foundation
import AVFoundation

@available(iOS 8.0, *)
@objc(HWPQRCodeScanner) class QRCodeScannerPlugin : CDVPlugin {
    var scanCommand:CDVInvokedUrlCommand?
    
    func scan(command: CDVInvokedUrlCommand) {
        //var message = command.arguments[0] as String
        scanCommand=command;
        
        if(!LBXPermissions.isGetCameraPermission()){
            
            let cv=UIAlertController(title: "提示", message: "为获得授权使用摄像头，请在设置中打开", preferredStyle: .Alert);
            let okAction=UIAlertAction(title: "设置", style: .Default, handler: {
                action in
                let seturi=NSURL(string: UIApplicationOpenSettingsURLString)!;
                UIApplication.sharedApplication().openURL(seturi);
            });
            let cancelAction=UIAlertAction(title: "取消", style: .Cancel, handler: nil);
            cv.addAction(okAction);
            cv.addAction(cancelAction);
            self.viewController?.presentViewController(cv, animated: true,completion: nil);
           
            let result=NSMutableDictionary()
            result.setValue(nil, forKey: "format")
            result.setValue(nil, forKey: "text")
            result.setValue(true, forKey: "cancelled")
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: result as [NSObject : AnyObject])
            self.commandDelegate.sendPluginResult(pluginResult, callbackId:self.scanCommand!.callbackId);
            return;
            
        }
    
        //扫码框占屏幕的百分比
        let frameWith=0.6;
        var screenWith=UIScreen.mainScreen().bounds.width;
        if(UIDevice.currentDevice().orientation==UIDeviceOrientation.LandscapeLeft||UIDevice.currentDevice().orientation==UIDeviceOrientation.LandscapeRight){
            screenWith=UIScreen.mainScreen().bounds.height;
        }
        
        let offset =  Double(screenWith)*(1-frameWith)/2;
        
        
        //设置扫码区域参数
        var style = LBXScanViewStyle()
        //style.centerUpOffset = 44;
        style.photoframeAngleStyle = LBXScanViewPhotoframeAngleStyle.On;
        style.photoframeLineW = 6;
        style.photoframeAngleW = 24;
        style.photoframeAngleH = 24;
        style.isNeedShowRetangle = true;
        
        style.anmiationStyle = LBXScanViewAnimationStyle.NetGrid;
        
        
        //矩形框离左边缘及右边缘的距离
        style.xScanRetangleOffset = CGFloat(offset);
        
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
