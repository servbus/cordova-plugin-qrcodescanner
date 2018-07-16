//
//  LBXScanWrapper.swift
//  swiftScan https://github.com/MxABC/swiftScan
//
//  Created by lbxia on 15/12/10.
//  Copyright © 2015年 xialibing. All rights reserved.
//

import UIKit
import AVFoundation

public struct  LBXScanResult {
    
    //码内容
    public var strScanned:String? = ""
    //扫描图像
    public var imgScanned:UIImage?
    //码的类型
    public var strBarCodeType:Int32
    
    //码在图像中的位置
    public var arrayCorner:[AnyObject]?
    
    public init(str:String?,img:UIImage?,barCodeType:Int32,corner:[AnyObject]?)
    {
        self.strScanned = str
        self.imgScanned = img
        self.strBarCodeType = barCodeType
        self.arrayCorner = corner
    }
}



open class LBXScanWrapper:NSObject, ZXCaptureDelegate {
    
    var _capture = ZXCapture()

    //扫码结果返回block
    var successBlock:(LBXScanResult) -> Void

    //ZXCaptureDelegate
    public func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        
        if result.isEqual(nil)
        {
            return
        }
        
        let res  = LBXScanResult(str: result.text, img: nil, barCodeType: Int32(result.barcodeFormat.rawValue), corner: nil)
        //Vibrate
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        successBlock(res)
    }
    
    
    /**
     初始化设备
     - parameter videoPreView: 视频显示UIView
     - parameter cropRect:     识别区域
     - parameter success:      返回识别信息
     - returns:
     */
    init( videoPreView:UIView,cropRect:CGRect=CGRect.zero,success:@escaping ( (LBXScanResult) -> Void) )
    {
//        self.view.backgroundColor = UIColor.black
        successBlock = success

        super.init()
        _capture.camera = _capture.back()
        _capture.focusMode = AVCaptureFocusMode.continuousAutoFocus
        _capture.rotation = 90.0
        
        _capture.layer.frame = videoPreView.frame
        var scaleVideo, scaleVideoX, scaleVideoY:CGFloat
        var videoSizeX, videoSizeY:CGFloat
        var transformedVideoRect = cropRect;
        if(_capture.sessionPreset == AVCaptureSessionPreset1920x1080) {
            print(_capture.sessionPreset)
            videoSizeX = 1080;
            videoSizeY = 1920;
        } else {
            videoSizeX = 720;
            videoSizeY = 1280;
        }
        
//        if(UIInterfaceOrientationIsPortrait(orientation)) {
            scaleVideoX = videoPreView.frame.size.width / videoSizeX;
            scaleVideoY = videoPreView.frame.size.height / videoSizeY;
        
            scaleVideo = max(scaleVideoX, scaleVideoY);
            if(scaleVideoX > scaleVideoY) {
                transformedVideoRect.origin.y += (scaleVideo * videoSizeY - videoPreView.frame.size.height) / 2;
            } else {
                transformedVideoRect.origin.x += (scaleVideo * videoSizeX - videoPreView.frame.size.width) / 2;
            }
//        } else {
//            scaleVideoX = self.view.frame.size.width / videoSizeY;
//            scaleVideoY = self.view.frame.size.height / videoSizeX;
//            scaleVideo = MAX(scaleVideoX, scaleVideoY);
//            if(scaleVideoX > scaleVideoY) {
//                transformedVideoRect.origin.y += (scaleVideo * videoSizeX - self.view.frame.size.height) / 2;
//            } else {
//                transformedVideoRect.origin.x += (scaleVideo * videoSizeY - self.view.frame.size.width) / 2;
//            }
//        }
        let  captureSizeTransform = CGAffineTransform(scaleX:1/scaleVideo, y:1/scaleVideo);
        _capture.scanRect = transformedVideoRect.applying(captureSizeTransform)

        print("scanRect")
        print(_capture.scanRect)
        
        
        _capture.delegate = self
        
        videoPreView.layer .insertSublayer(_capture.layer, at: 0)
        
    }
    

    deinit
    {
        print("LBXScanWrapper deinit")
    }
    
    

}
