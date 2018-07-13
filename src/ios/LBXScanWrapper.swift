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



open class LBXScanWrapper: NSObject,AVCaptureMetadataOutputObjectsDelegate {
    
    let device:AVCaptureDevice? = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo);
    
    var input:AVCaptureDeviceInput?
    var output:AVCaptureMetadataOutput
    
    let session = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer?
    var stillImageOutput:AVCaptureStillImageOutput?
    
    //存储返回结果
    var arrayResult:[LBXScanResult] = [];
    
    //扫码结果返回block
    var successBlock:([LBXScanResult]) -> Void
    //当前扫码结果是否处理
    var isNeedScanResult:Bool = true
    
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
        do{
            input = try AVCaptureDeviceInput(device: device)
        }
        catch let error as NSError {
            print("AVCaptureDeviceInput(): \(error)")
        }
        
        successBlock = success
        
        // Output
        output = AVCaptureMetadataOutput()
                
        stillImageOutput = AVCaptureStillImageOutput();
        
        super.init()
        
        if device == nil
        {
            return
        }
        
        if session.canAddInput(input)
        {
            session.addInput(input)
        }
        if session.canAddOutput(output)
        {
            session.addOutput(output)
        }
        if session.canAddOutput(stillImageOutput)
        {
            session.addOutput(stillImageOutput)
        }
        
        let outputSettings:Dictionary = [AVVideoCodecJPEG:AVVideoCodecKey]
        stillImageOutput?.outputSettings = outputSettings
    
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        //参数设置
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        output.metadataObjectTypes = objType
        
        if !cropRect.equalTo(CGRect.zero)
        {
            //启动相机后，直接修改该参数无效
            output.rectOfInterest = cropRect
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        var frame:CGRect = videoPreView.frame
        frame.origin = CGPoint.zero
        previewLayer?.frame = frame
        
        videoPreView.layer .insertSublayer(previewLayer!, at: 0)
        
        if ( device!.isFocusPointOfInterestSupported && device!.isFocusModeSupported(AVCaptureFocusMode.continuousAutoFocus) )
        {
            do
            {
                try input?.device.lockForConfiguration()
                
                input?.device.focusMode = AVCaptureFocusMode.continuousAutoFocus
                
                input?.device.unlockForConfiguration()
            }
            catch let error as NSError {
                print("device.lockForConfiguration(): \(error)")
                
            }
        }
        
    }
    
    func start()
    {
        if !session.isRunning
        {
            isNeedScanResult = true
            session.startRunning()
        }
    }
    func stop()
    {
        if session.isRunning
        {
            isNeedScanResult = false
            session.stopRunning()
        }
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
    open func changeScanRect(cropRect:CGRect)
    {
        //待测试，不知道是否有效
        stop()
        output.rectOfInterest = cropRect
        start()
    }

    //MARK: 切换识别码的类型
    open func changeScanType(objType:[String])
    {
        //待测试中途修改是否有效
        output.metadataObjectTypes = objType
    }
    
    open func isGetFlash()->Bool
    {
        if (device != nil &&  device!.hasFlash && device!.hasTorch)
        {
            return true
        }
        return false
    }

    /**
     打开或关闭闪关灯
     - parameter torch: true：打开闪关灯 false:关闭闪光灯
     */
    open func setTorch(torch:Bool)
    {
        if isGetFlash()
        {
            do
            {
                try input?.device.lockForConfiguration()
                
                input?.device.torchMode = torch ? AVCaptureTorchMode.on : AVCaptureTorchMode.off
                
                input?.device.unlockForConfiguration()
            }
            catch let error as NSError {
                print("device.lockForConfiguration(): \(error)")
                
            }
        }
        
    }
    
    
    /**
    ------闪光灯打开或关闭
    */
    open func changeTorch()
    {
        if isGetFlash()
        {
            do
            {
                try input?.device.lockForConfiguration()
                
                var torch = false
                
                if input?.device.torchMode == AVCaptureTorchMode.on
                {
                    torch = false
                }
                else if input?.device.torchMode == AVCaptureTorchMode.off
                {
                    torch = true
                }
                
                input?.device.torchMode = torch ? AVCaptureTorchMode.on : AVCaptureTorchMode.off
                
                input?.device.unlockForConfiguration()
            }
            catch let error as NSError {
                print("device.lockForConfiguration(): \(error)")
                
            }
        }
    }
    
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
