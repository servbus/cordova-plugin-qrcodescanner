import UIKit
import Foundation
import AVFoundation

@available(iOS 8.0, *)
@objc(HWPQRCodeScanner) class QRCodeScannerPlugin : CDVPlugin {
    var scanCommand:CDVInvokedUrlCommand?
    
    @objc(scan:)
    func scan(command: CDVInvokedUrlCommand) {
        //var message = command.arguments[0] as String
        scanCommand=command;
        
        if(!LBXPermissions.isGetCameraPermission()){
            
            let cv=UIAlertController(title: "提示", message: "未获得授权使用摄像头，请在设置中打开", preferredStyle: .alert);
            let okAction=UIAlertAction(title: "设置", style: .default, handler: {
                action in
                UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
            });
            let cancelAction=UIAlertAction(title: "取消", style: .cancel, handler: nil);
            cv.addAction(okAction);
            cv.addAction(cancelAction);
            self.viewController?.present(cv, animated: true,completion: nil);
            
            
            
            let result=["format":nil ,"text":nil,"cancelled":true] as [String : Any]
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK , messageAs:result)
            
            
            self.commandDelegate.send(pluginResult, callbackId:self.scanCommand!.callbackId);
            return;
            
        }
        
        //扫码框占屏幕的百分比
        let frameWith=0.6;
        var screenWith=UIScreen.main.bounds.width;
        if(UIDevice.current.orientation==UIDeviceOrientation.landscapeLeft||UIDevice.current.orientation==UIDeviceOrientation.landscapeRight)
        {
            screenWith=UIScreen.main.bounds.height;
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
        
        self.viewController?.present(vc, animated: true,completion: nil)
        
        
    }
    
    func callBack(codeType:String?,codeResult:String?,isCancelled:Bool) -> Void {
        self.viewController?.dismiss(animated:false, completion: nil)
        
        
        let result=["format":codeType ,"text":codeResult,"cancelled":isCancelled] as [String : Any]
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
        commandDelegate.send(pluginResult, callbackId:scanCommand!.callbackId)
    }
}
