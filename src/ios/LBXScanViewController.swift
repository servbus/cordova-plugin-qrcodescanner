//
//  LBXScanViewController.swift
//  swiftScan
//
//  Created by lbxia on 15/12/8.
//  Copyright © 2015年 xialibing. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation


open class LBXScanViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    open var scanObj: LBXScanWrapper?
    
    open var scanStyle: LBXScanViewStyle? = LBXScanViewStyle()
    
    open var qRScanView: LBXScanView?
    
    open var callBack:((String?, String?, Bool) -> Void)?
    //public typealias callBackType = (String? , String? , Bool) -> Void
    
    
    //启动区域识别功能
    open var isOpenInterestRect = false
    
    //识别码的类型
    var arrayCodeType:[String]?
    
    //禁止旋转，仅支持竖着的。其他的待研究实现方式
    
    open override var shouldAutorotate:Bool{
        return false
    }
    
    open override var supportedInterfaceOrientations:UIInterfaceOrientationMask{
        return .portrait
    }
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // [self.view addSubview:_qRScanView];
        self.view.backgroundColor = UIColor.black
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
    }
    
    //设置框内识别
    open func setOpenInterestRect(isOpen:Bool){
        isOpenInterestRect = isOpen
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        drawScanView()
        
        perform(#selector(LBXScanViewController.startScan), with: nil, afterDelay: 0.3)
        
    }
    
    open func startScan()
    {
        if(!LBXPermissions .isGetCameraPermission())
        {
            showMsg(title: "提示", message: "没有相机权限，请到设置->隐私中开启本程序相机权限")
            return;
        }
        
        if (scanObj == nil)
        {
            var cropRect = CGRect.zero
            if isOpenInterestRect
            {
                cropRect = LBXScanView.getScanRectWithPreView(preView: self.view, style:scanStyle! )
            }
            
            //识别各种码，
            //let arrayCode = LBXScanWrapper.defaultMetaDataObjectTypes()
            
            //指定识别几种码
            if arrayCodeType == nil
            {
                arrayCodeType = [AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeCode128Code]
            }
            
            scanObj = LBXScanWrapper(videoPreView: self.view,objType:arrayCodeType!, cropRect:cropRect, success: { [weak self] (arrayResult) -> Void in
                
                if let strongSelf = self
                {
                    //停止扫描动画
                    strongSelf.qRScanView?.stopScanAnimation()
                    
                    strongSelf.handleCodeResult(arrayResult: arrayResult)
                }
            })
        }
        
        //结束相机等待提示
        qRScanView?.deviceStopReadying()
        
        //开始扫描动画
        qRScanView?.startScanAnimation()
        
        //相机运行
        scanObj?.start()
    }
    
    open func drawScanView()
    {
        if qRScanView == nil
        {
            qRScanView = LBXScanView(frame: self.view.frame,vstyle:scanStyle! )
            self.view.addSubview(qRScanView!)
        }
        let btnCancel = UIButton()
        btnCancel.setTitle("取消", for: UIControlState.normal)
        
        let yMax = self.view.frame.maxY - self.view.frame.minY
        
        let bottomItemsView = UIView(frame:CGRect( origin:CGPoint(x:0.0, y:yMax-60), size:CGSize(width:self.view.frame.size.width, height:60) ) )
        
        
        bottomItemsView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)
        
        self.view .addSubview(bottomItemsView)
        
        
        let size = CGSize(width:65.0, height:87);
        
        
        btnCancel.bounds = CGRect(origin:CGPoint(x:0,y:0), size:size)
        btnCancel.center = CGPoint(x:bottomItemsView.frame.width/2, y:bottomItemsView.frame.height/2)
        btnCancel.addTarget(self, action: #selector(LBXScanViewController.btnCancelAction), for: UIControlEvents.touchUpInside)
        
        bottomItemsView.addSubview(btnCancel)
        
        self.view .addSubview(bottomItemsView)
        
        qRScanView?.deviceStartReadying(readyStr: "相机启动中...")
        
    }
    
    func btnCancelAction() -> Void {
        callBack!(nil,nil,true)
    }
    
    
    /**
     处理扫码结果，如果是继承本控制器的，可以重写该方法,作出相应地处理
     */
    open func handleCodeResult(arrayResult:[LBXScanResult])
    {
        
        let result:LBXScanResult = arrayResult[0]
        
        //showMsg(result.strBarCodeType, message: result.strScanned)
        callBack?(result.strBarCodeType,result.strScanned,false)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        qRScanView?.stopScanAnimation()
        
        scanObj?.stop()
    }
    
    open func openPhotoAlbum()
    {
        if(!LBXPermissions.isGetPhotoPermission())
        {
            showMsg(title: "提示", message: "没有相册权限，请到设置->隐私中开启本程序相册权限")
        }
        
        let picker = UIImagePickerController()
        
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        picker.delegate = self;
        
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    

    
    func showMsg(title:String?,message:String?)
    {
        let alertController = UIAlertController(title: title, message:message, preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction(title:  "知道了", style: UIAlertActionStyle.default) { [weak self] (alertAction) in
            
            if let strongSelf = self
            {
                strongSelf.startScan()
            }
        }
        
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    deinit
    {
        print("LBXScanViewController deinit")
    }
    
}





