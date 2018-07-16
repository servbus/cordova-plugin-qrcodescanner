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
    public var strBarCodeType:String? = ""
    
    //码在图像中的位置
    public var arrayCorner:[AnyObject]?
    
    public init(str:String?,img:UIImage?,barCodeType:String?,corner:[AnyObject]?)
    {
        self.strScanned = str
        self.imgScanned = img
        self.strBarCodeType = barCodeType
        self.arrayCorner = corner
    }
}



open class LBXScanWrapper:NSObject, ZXCaptureDelegate {
    
    var _capture = ZXCapture()

    //存储返回结果
    var arrayResult:[LBXScanResult] = [];
    
    //扫码结果返回block
    var successBlock:([LBXScanResult]) -> Void
    //当前扫码结果是否处理
    var isNeedScanResult:Bool = true
    
    //ZXCaptureDelegate
    public func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        
        if result.isEqual(nil)
        {
            return
        }
        print("barcodeFormat")
        print(String(describing: result.barcodeFormat))
        print("text")
        print(result.text)
        
        
        //Vibrate
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        //        cancelScan(sender: "" as AnyObject)
        
    }
    
    
    /**
     初始化设备
     - parameter videoPreView: 视频显示UIView
     - parameter objType:      识别码的类型,缺省值 QR二维码
     - parameter cropRect:     识别区域
     - parameter success:      返回识别信息
     - returns:
     */
    init( videoPreView:UIView,objType:[String] = [AVMetadataObjectTypeQRCode],cropRect:CGRect=CGRect.zero,success:@escaping ( ([LBXScanResult]) -> Void) )
    {
//        self.view.backgroundColor = UIColor.black
        successBlock = success

        super.init()
        print("init")
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
    
    func start()
    {
            isNeedScanResult = true
    }
    func stop()
    {
            isNeedScanResult = false
        
    }
    
    open func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if !isNeedScanResult
        {
            //上一帧处理中
            return
        }
        
        isNeedScanResult = false
        
        arrayResult.removeAll()
        
        //识别扫码类型
        for current:Any in metadataObjects
        {
            if (current as AnyObject).isKind(of: AVMetadataMachineReadableCodeObject.self)
            {
                let code = current as! AVMetadataMachineReadableCodeObject
                
                //码类型
                let codeType = code.type
                print("code type:%@",codeType)
                //码内容
                let codeContent = code.stringValue
                print("code string:%@",codeContent)
                
                //4个字典，分别 左上角-右上角-右下角-左下角的 坐标百分百，可以使用这个比例抠出码的图像
                // let arrayRatio = code.corners
                
                arrayResult.append(LBXScanResult(str: codeContent, img: UIImage(), barCodeType: codeType,corner: code.corners as [AnyObject]?))
            }
        }
        
        if arrayResult.count > 0
        {
            stop()
            successBlock(arrayResult)
        }
        else
        {
            isNeedScanResult = true
        }
        
    }
    
    open func connectionWithMediaType(mediaType:String,connections:[AnyObject]) -> AVCaptureConnection?
    {
        for connection:AnyObject in connections
        {
            let connectionTmp:AVCaptureConnection = connection as! AVCaptureConnection
            
            for port:Any in connectionTmp.inputPorts
            {
                if (port as AnyObject).isKind(of: AVCaptureInputPort.self)
                {
                    let portTmp:AVCaptureInputPort = port as! AVCaptureInputPort
                    if portTmp.mediaType == mediaType
                    {
                        return connectionTmp
                    }
                }
            }
        }
        return nil
    }
    
    
    //MARK:切换识别区域
//    open func changeScanRect(cropRect:CGRect)
//    {
//        //待测试，不知道是否有效
//        stop()
//        output.rectOfInterest = cropRect
//        start()
//    }

//    //MARK: 切换识别码的类型
//    open func changeScanType(objType:[String])
//    {
//        //待测试中途修改是否有效
//        output.metadataObjectTypes = objType
//    }
//
//    open func isGetFlash()->Bool
//    {
//        if (device != nil &&  device!.hasFlash && device!.hasTorch)
//        {
//            return true
//        }
//        return false
//    }

//    /**
//     打开或关闭闪关灯
//     - parameter torch: true：打开闪关灯 false:关闭闪光灯
//     */
//    open func setTorch(torch:Bool)
//    {
//        if isGetFlash()
//        {
//            do
//            {
//                try input?.device.lockForConfiguration()
//
//                input?.device.torchMode = torch ? AVCaptureTorchMode.on : AVCaptureTorchMode.off
//
//                input?.device.unlockForConfiguration()
//            }
//            catch let error as NSError {
//                print("device.lockForConfiguration(): \(error)")
//
//            }
//        }
//
//    }
//    
//    
//    /**
//    ------闪光灯打开或关闭
//    */
//    open func changeTorch()
//    {
//        if isGetFlash()
//        {
//            do
//            {
//                try input?.device.lockForConfiguration()
//                
//                var torch = false
//                
//                if input?.device.torchMode == AVCaptureTorchMode.on
//                {
//                    torch = false
//                }
//                else if input?.device.torchMode == AVCaptureTorchMode.off
//                {
//                    torch = true
//                }
//                
//                input?.device.torchMode = torch ? AVCaptureTorchMode.on : AVCaptureTorchMode.off
//                
//                input?.device.unlockForConfiguration()
//            }
//            catch let error as NSError {
//                print("device.lockForConfiguration(): \(error)")
//                
//            }
//        }
//    }
//    
    //MARK: ------获取系统默认支持的码的类型
    static func defaultMetaDataObjectTypes() ->[String]
    {
        var types =
        [AVMetadataObjectTypeQRCode,
            AVMetadataObjectTypeUPCECode,
            AVMetadataObjectTypeCode39Code,
            AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code,
            AVMetadataObjectTypeEAN8Code,
            AVMetadataObjectTypeCode93Code,
            AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code,
            AVMetadataObjectTypeAztecCode,
            
        ];
        //if #available(iOS 8.0, *)
       
        types.append(AVMetadataObjectTypeInterleaved2of5Code)
        types.append(AVMetadataObjectTypeITF14Code)
        types.append(AVMetadataObjectTypeDataMatrixCode)
        
        types.append(AVMetadataObjectTypeInterleaved2of5Code)
        types.append(AVMetadataObjectTypeITF14Code)
        types.append(AVMetadataObjectTypeDataMatrixCode)
        
        
        return types;
    }
    
    
    //MARK:根据扫描结果，获取图像中得二维码区域图像（如果相机拍摄角度故意很倾斜，获取的图像效果很差）
    static func getConcreteCodeImage(srcCodeImage:UIImage,codeResult:LBXScanResult)->UIImage?
    {
        let rect:CGRect = getConcreteCodeRectFromImage(srcCodeImage: srcCodeImage, codeResult: codeResult)
        
        if rect.isEmpty
        {
            return nil
        }
        
        let img = imageByCroppingWithStyle(srcImg: srcCodeImage, rect: rect)
        
        if img != nil
        {
            let imgRotation = imageRotation(image: img!, orientation: UIImageOrientation.right)
            return imgRotation
        }
        return nil
    }
    //根据二维码的区域截取二维码区域图像
    static open func getConcreteCodeImage(srcCodeImage:UIImage,rect:CGRect)->UIImage?
    {
        if rect.isEmpty
        {
            return nil
        }
        
        let img = imageByCroppingWithStyle(srcImg: srcCodeImage, rect: rect)
        
        if img != nil
        {
            let imgRotation = imageRotation(image: img!, orientation: UIImageOrientation.right)
            return imgRotation
        }
        return nil
    }

    //获取二维码的图像区域
    static open func getConcreteCodeRectFromImage(srcCodeImage:UIImage,codeResult:LBXScanResult)->CGRect
    {
        if (codeResult.arrayCorner == nil || (codeResult.arrayCorner?.count)! < 4  )
        {
            return CGRect.zero
        }
        
        let corner:[[String:Float]] = codeResult.arrayCorner  as! [[String:Float]]
        
        let dicTopLeft     = corner[0]
        let dicTopRight    = corner[1]
        let dicBottomRight = corner[2]
        let dicBottomLeft  = corner[3]
        
        let xLeftTopRatio:Float = dicTopLeft["X"]!
        let yLeftTopRatio:Float  = dicTopLeft["Y"]!
        
        let xRightTopRatio:Float = dicTopRight["X"]!
        let yRightTopRatio:Float = dicTopRight["Y"]!
        
        let xBottomRightRatio:Float = dicBottomRight["X"]!
        let yBottomRightRatio:Float = dicBottomRight["Y"]!
        
        let xLeftBottomRatio:Float = dicBottomLeft["X"]!
        let yLeftBottomRatio:Float = dicBottomLeft["Y"]!
        
        //由于截图只能矩形，所以截图不规则四边形的最大外围
        let xMinLeft = CGFloat( min(xLeftTopRatio, xLeftBottomRatio) )
        let xMaxRight = CGFloat( max(xRightTopRatio, xBottomRightRatio) )
        
        let yMinTop = CGFloat( min(yLeftTopRatio, yRightTopRatio) )
        let yMaxBottom = CGFloat ( max(yLeftBottomRatio, yBottomRightRatio) )
        
        let imgW = srcCodeImage.size.width
        let imgH = srcCodeImage.size.height
        
        //宽高反过来计算
        let rect = CGRect(x: xMinLeft * imgH, y: yMinTop*imgW, width: (xMaxRight-xMinLeft)*imgH, height: (yMaxBottom-yMinTop)*imgW)
        return rect
    }
    
    //MARK: ----图像处理


    //图像缩放
    static func resizeImage(image:UIImage,quality:CGInterpolationQuality,rate:CGFloat)->UIImage?
    {
        var resized:UIImage?;
        let width    = image.size.width * rate;
        let height   = image.size.height * rate;
        
        UIGraphicsBeginImageContext(CGSize(width: width, height: height));
        let context = UIGraphicsGetCurrentContext();
        context!.interpolationQuality = quality;
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        resized = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resized;
    }
    
    
    //图像裁剪
    static func imageByCroppingWithStyle(srcImg:UIImage,rect:CGRect)->UIImage?
    {
        let imageRef = srcImg.cgImage
        let imagePartRef = imageRef!.cropping(to: rect)
        let cropImage = UIImage(cgImage: imagePartRef!)
        
        return cropImage
    }
    //图像旋转
    static func imageRotation(image:UIImage,orientation:UIImageOrientation)->UIImage
    {
        var rotate:Double = 0.0;
        var rect:CGRect;
        var translateX:CGFloat = 0.0;
        var translateY:CGFloat = 0.0;
        var scaleX:CGFloat = 1.0;
        var scaleY:CGFloat = 1.0;
        
        switch (orientation) {
        case UIImageOrientation.left:
            rotate = M_PI_2;
            rect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientation.right:
            rotate = 3 * M_PI_2;
            rect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientation.down:
            rotate = M_PI;
            rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height);
            translateX = 0;
            translateY = 0;
            break;
        }
        
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext()!;
        //做CTM变换
        context.translateBy(x: 0.0, y: rect.size.height);
        context.scaleBy(x: 1.0, y: -1.0);
        context.rotate(by: CGFloat(rotate));
        context.translateBy(x: translateX, y: translateY);
        
        context.scaleBy(x: scaleX, y: scaleY);
        //绘制图片
        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))        
        let newPic = UIGraphicsGetImageFromCurrentImageContext();
        
        return newPic!;
    }

    deinit
    {
        print("LBXScanWrapper deinit")
    }
    
    

}
