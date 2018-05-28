//
//  EnrolVC.swift
//  GDay
//
//  Created by Erik Mai on 26/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//


import UIKit
import AVFoundation
class EnrolVC: UIViewController {

    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var toggleCameraImageView: UIImageView!
    @IBOutlet weak var bottomDistance: NSLayoutConstraint!
    @IBOutlet weak var enrolCollectionView: EnrolCollectionView!
    @IBOutlet weak var takePicImageView: UIImageView!
    @IBOutlet weak var cameraView: UIView!
    
    var stillImageOutput = AVCaptureStillImageOutput()
    var session: AVCaptureSession?
    var stillOutput = AVCaptureStillImageOutput()
    var autoEnrolment = false
    
    
    fileprivate var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        var previewLay = AVCaptureVideoPreviewLayer(session: self.session!)
        previewLay.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        return previewLay
    }()
    
    lazy var frontCamera: AVCaptureDevice? = {
        
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else { return nil }
        
        return devices.filter { $0.position == .front }.first
    }()
    
    lazy var backCamera: AVCaptureDevice? = {
        
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else { return nil }
        
        return devices.filter { $0.position == .back }.first
    }()
    
    let numImagesToTrain = 3
    var useFrontCamera = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        hideMessage()
        let tap = UITapGestureRecognizer(target: self, action: #selector(EnrolVC.didTapOnTakePhoto))
        takePicImageView.isUserInteractionEnabled = true
        takePicImageView.addGestureRecognizer(tap)
        
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(EnrolVC.toggleCamera))
        toggleCameraImageView.isUserInteractionEnabled = true
        toggleCameraImageView.addGestureRecognizer(tap2)
        
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(EnrolVC.didTapOnCameraView))
        cameraView.isUserInteractionEnabled = true
        cameraView.addGestureRecognizer(tap3)
        
        sessionPrepare(front: true)
        session?.startRunning()
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(EnrolVC.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EnrolVC.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        enrolCollectionView.enrolCollectionViewDelegate = self
    }
    @objc func keyboardDidShow(_ notification: Notification) {
        let keyboardSize = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        bottomDistance.constant = keyboardSize.size.height
        
    }
    
    @objc func keyboardWillBeHidden(_ notification: Notification) {
        bottomDistance.constant = 0
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.frame
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let previewLayer = previewLayer else { return }
        cameraView.layer.addSublayer(previewLayer)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didTapOnX(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    @objc func didTapOnTakePhoto() {
        takePicture()
    }
    @objc func toggleCamera() {
        useFrontCamera = !useFrontCamera
        sessionPrepare(front: useFrontCamera)
        session?.startRunning()
        
    }
    @objc func didTapOnCameraView() {
        
    }
    
    func showMessage(_ message: String) {
        messageLabel.text = message
        messageView.isHidden = false
    }
    func hideMessage() {
        messageView.isHidden = true
    }
    func takePicture() {
        hideMessage()
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (CMSampleBuffer, Error) in
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(CMSampleBuffer!) {
                    
                    if let cameraImage = UIImage(data: imageData) {
                        self.newImageTaken(image: cameraImage)
//                        let newEnrol = self.enrolCollectionView.makeNewEnrol()
//                        newEnrol.newImage(image: cameraImage)
//                        self.enrolCollectionView.addNewResult(newEnrol)
//                        self.enrolReady(true)
                    } else {
                        self.showMessage("Error taking picture")
                    }
                }
            })
        }
    }
    func newImageTaken(image: UIImage) {
        let imageCropper = FaceCropper(image: image)
        imageCropper.crop { (result) in
            switch result {
            case .failure(let error):
                self.showMessage("Error decting faces")
                print(error)
            case .notFound:
                self.showMessage("No faces found")
                print("not found")
            case .success(let images):
                for image in images {
                    let newEnrol = self.enrolCollectionView.makeNewEnrol()
                    newEnrol.newWith(image: image.image!)
                    self.enrolCollectionView.addNewResult(newEnrol)
                }
                if images.count == 0 {
                    self.showMessage("No faces found")
                } else {
                    self.startAutoEnroling()
                }
                
            }
            
            
        }
    }
    
    
    func sessionPrepare(front: Bool) {
        if let currentSession = session {
            currentSession.stopRunning()
        } else {
            session = AVCaptureSession()
        }
        guard let session = session, let captureDevice = front ? frontCamera : backCamera else { return }
        
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        for input in session.inputs {
            session.removeInput(input)
        }
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecType.jpeg]
            
            if session.canAddOutput(stillImageOutput) {
                session.addOutput(stillImageOutput)
            }
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(videoDataOutput) {
                //videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
                session.addOutput(videoDataOutput)
            }
            
            session.commitConfiguration()
            
            //let queue = DispatchQueue(label: "output.queue")
            
            
        } catch {
            print("error with creating AVCaptureDeviceInput")
        }
    }
    func doEnrol(_ enrolment: Enrolment) {
        if enrolment.notSubmitted {
            let vc = NameDialog(nibName: "NameDialog", bundle: nil)
            vc.enrol = enrolment
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            
            vc.delegate = self
            
            present(vc, animated: true, completion: nil)
        }
    }
    func enrolNext() {
        if let enrolment = enrolCollectionView.nextUnsubmittedEnrol {
            doEnrol(enrolment)
        } else {
            endEnroling()
        }
    }
    func stopCamera() {
        previewLayer?.connection?.isEnabled = false
        //session?.stopRunning()
    }
    func resumeCamera() {
        previewLayer?.connection?.isEnabled = true
        //session?.startRunning()
    }
    func endEnroling() {
        autoEnrolment = false
        resumeCamera()
    }
    func startAutoEnroling() {
        autoEnrolment = true
        stopCamera()
        enrolNext()
    }
}
extension EnrolVC: EnrolCollectionViewDelegate, NameDialogDelegate {
    func enrolCollectionView(_ collectionView: EnrolCollectionView, didSelect enrolment: Enrolment, at: IndexPath) {
        autoEnrolment = false
        doEnrol(enrolment)
    }
    func nameDialog(didCancel dialog: NameDialog) {
        endEnroling()
    }
    func nameDialog(_ dialog: NameDialog, didEnrol: Enrolment) {
        enrolCollectionView.updateEnrol(didEnrol)
        if autoEnrolment {
            enrolNext()
        } else {
            endEnroling()
        }
    }
}





