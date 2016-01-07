//
//  QRCodeViewController.swift
//  QRcodeSample
//
//  Created by joinhov on 16/1/5.
//  Copyright © 2016年 lance. All rights reserved.
//

import UIKit
import AVFoundation

private let contentHeightRatio:CGFloat = 0.8;

public protocol QRCodeViewControllerDelegate:NSObjectProtocol {
    
    func qrcode(controller:QRCodeViewController, result:String);
}

/// 扫码
public class QRCodeViewController: UIViewController {
    
    weak var delegate:QRCodeViewControllerDelegate?;
    private var session:AVCaptureSession!;
    
    private var animImageView:UIImageView!;
    private var keyAnimation:CAKeyframeAnimation?;
    
    private var bottomBar:UIView!;// 底部预留的空白区域
    
    private var hasNavigationBar:Bool = false;
    override public func viewDidLoad() {
        super.viewDidLoad();
        self.view.clipsToBounds = true;
        
        self.setupScanning();
        
        self.setupMaskView();
        self.setupPreviewView();
        
        print("qrframe:   \(self.view.frame)");
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didBecomeActive", name: kApplicationDidBecomeActive, object: nil);
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
        self.startAnimation();
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        self.stopAnimation();
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kApplicationDidBecomeActive, object: nil);
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        
        print("qrframe2:   \(self.view.frame)");
    }
    func didBecomeActive() {
        self.startAnimation();
        
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        
    }
    
    // 关联到父控制器
    public func attachToViewController(controller:UIViewController, hasNavigationBar:Bool, delegate:QRCodeViewControllerDelegate?) {
        
        self.attachToViewController(controller, rootView: controller.view, hasNavigationBar: hasNavigationBar, delegate: delegate);
    }
    
    public func attachToViewController(controller:UIViewController, rootView:UIView, hasNavigationBar:Bool, delegate:QRCodeViewControllerDelegate?){
        self.hasNavigationBar = hasNavigationBar;
        controller.addChildViewController(self);
        self.delegate = delegate;
        rootView.insertSubview(self.view, atIndex: 0);
        
        self.didMoveToParentViewController(controller);
    }
    
    public func cancelAttachToViewController() {
        self.removeFromParentViewController();
    }
    
    public func startRunning() {
        if self.session == nil {
            return;
        }
        
        self.session.startRunning();
    }
    
    public func stopRunning() {
        if self.session == nil {
            return;
        }
        
        self.session.stopRunning();
    }
    
    // 添加预览遮罩
    func setupMaskView() {
        let maskView = UIView();
        //maskView.backgroundColor = UIColor.redColor();
        
        let size = contentSize();
        
        let topOffset:CGFloat = hasNavigationBar ? 64 : 0;
        let bottomSize = (self.view.height - topOffset) * (1 - contentHeightRatio);
        
        // 计算出离顶边的距离
        let borderWidth = (self.view.height * contentHeightRatio - size.height) / 2.0 + bottomSize;
        // 计算出边框宽度
        maskView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).CGColor;
        maskView.layer.borderWidth = borderWidth;// 预留底部工具栏
        
        // 计算出内容尺寸
        maskView.frame = CGRectMake(0, 0, size.width + borderWidth * 2, size.height + borderWidth * 2);
        maskView.center = CGPointMake(self.view.center.x, self.view.center.y - bottomSize / 2.0 - topOffset / 2.0);
        
        self.view.addSubview(maskView);
    }
    
    // 添加扫描动画视图
    func setupPreviewView() {
        let size = contentSize();
        let originX = (self.view.width - size.width) / 2;
        
        let topOffset:CGFloat = hasNavigationBar ? 64 : 0;
        let originY = ((self.view.height - topOffset) * contentHeightRatio - size.height) / 2;
        let previewView = UIView();
        previewView.clipsToBounds = true;
        previewView.frame = CGRectMake(originX, originY, size.width, size.height);
        
        self.view.addSubview(previewView);
        
        self.animImageView = UIImageView();
        // 起始位置看不见
        self.animImageView.frame = CGRectMake(0, -size.height, size.width, size.height);
        self.animImageView.image = UIImage(named: "ic_scan_grid");
        
        previewView.addSubview(self.animImageView);
        
        let cornerSize:CGFloat = 18;
        let cornerImage = UIImage(named: "ic_scan_corner");
        let topLeft = UIButton(type: .Custom);
        topLeft.frame = CGRectMake(0, 0, cornerSize, cornerSize);
        topLeft.setImage(cornerImage, forState: UIControlState.Normal);
        
        let topRight = UIButton(type: .Custom);
        topRight.frame = CGRectMake(previewView.width - cornerSize, 0, cornerSize, cornerSize);
        topRight.setImage(cornerImage, forState: UIControlState.Normal);
        
        let bottomLeft = UIButton(type: .Custom);
        bottomLeft.frame = CGRectMake(0, previewView.height - cornerSize, cornerSize, cornerSize);
        bottomLeft.setImage(cornerImage, forState: UIControlState.Normal);
        
        let bottomRight = UIButton(type: .Custom);
        bottomRight.frame = CGRectMake(previewView.width - cornerSize, previewView.height - cornerSize, cornerSize, cornerSize);
        bottomRight.setImage(cornerImage, forState: UIControlState.Normal);
        
        topLeft.transform = CGAffineTransformIdentity;
        topRight.transform = CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0));
        bottomLeft.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI / 2.0));
        bottomRight.transform = CGAffineTransformMakeRotation(CGFloat(M_PI));
        
        // 添加4个角
        previewView.addSubview(topLeft);
        previewView.addSubview(topRight);
        previewView.addSubview(bottomLeft);
        previewView.addSubview(bottomRight);
    }
    
    // 设置扫描动画
    public func startAnimation() {
        if self.animImageView == nil {
            return;
        }
        
        let size = contentSize();
        
        self.animImageView.layer.removeAllAnimations();
        
        // 控制Y轴上的循环运动
        let keyAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y");
        keyAnimation.delegate = self;
        keyAnimation.values = [0, size.height];
        keyAnimation.keyTimes = [0.0, 1.0];
        keyAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut);
        keyAnimation.duration = 1.0;
        keyAnimation.repeatCount = Float.infinity;
        
        // 这里必须设置key否则会出现一些问题
        self.animImageView.layer.addAnimation(keyAnimation, forKey: "scanAnimation");
    }
    
    public func stopAnimation() {
        if self.animImageView == nil {
            return;
        }
        
        self.animImageView.layer.removeAllAnimations();
    }
    
    /// 获取扫描区域
    private func contentSize() ->CGSize {
        
        let width = self.view.width * contentHeightRatio;
        
        return CGSizeMake(width, width);
    }
    
    private func setupScanning() {
        
        let size = contentSize();
        let ratiox = (1 - (size.width / self.view.width)) / 2.0;
        let ratioHeight = size.height / self.view.height;
        /// 获取默认的后置摄像头
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo);
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device);
            
            let output = AVCaptureMetadataOutput();
            // 这里要计算出扫描区域
            // 指定预览区域中敢兴趣的区域来扫描
            
            //NSLog("%f   %f   %f   %f", ratiox, (1 - ratioHeight - (1 - contentHeightRatio)) / 2.0, 1 - ratiox * 2, ratioHeight);
            output.rectOfInterest = CGRectMake((1 - ratioHeight - (1 - contentHeightRatio)) / 2.0, ratiox, ratioHeight, 1 - ratiox * 2);
            
            //output.rectOfInterest = CGRectMake(0, 0, 1, 1);
            output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue());
            
            self.session = AVCaptureSession();
            self.session.sessionPreset = AVCaptureSessionPresetHigh;
            
            self.session.addInput(deviceInput);
            self.session.addOutput(output);
            
            // 设置扫码支持的格式，二维码和条码兼容 --- 这个地方需要先添加后设置，否则易出错
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
            
            // 设置预览区域
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.session);
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            previewLayer.frame = self.view.bounds;
            
            self.view.layer.insertSublayer(previewLayer, atIndex: 0);
        }catch let error as NSError {
            NSLog("error: %@", error.description);
        }
        
    }
    
    public override func animationDidStart(anim: CAAnimation) {
        // NSLog("animationDidStart:", "");
    }
    
    public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        // NSLog("animationDidStop:", "");
    }
    
}

extension QRCodeViewController:AVCaptureMetadataOutputObjectsDelegate {
    /// 扫描后的回调
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects == nil && metadataObjects.count == 0 {
            return;
        }
        
        self.session.stopRunning();
        
        // AVMetadataMachineReadableCodeObject
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject;
        
        let result = metadataObj.stringValue!;
        
        self.delegate?.qrcode(self, result: result);
    }
    
}


