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

    @IBOutlet weak var toggleCameraImageView: UIImageView!
    @IBOutlet weak var bottomDistance: NSLayoutConstraint!
    @IBOutlet weak var enrolCollectionView: EnrolCollectionView!
    var stillImageOutput = AVCaptureStillImageOutput()
    var session: AVCaptureSession?
    var stillOutput = AVCaptureStillImageOutput()
    
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
    
    @IBOutlet weak var takePicImageView: UIImageView!
    @IBOutlet weak var enrolButton: UIButton!
    @IBOutlet weak var enrolView: UIView!
    
    //@IBOutlet var picImageViews: [UIImageView]!
    @IBOutlet weak var nameLabel: UITextField!
    
    @IBOutlet weak var cameraView: UIView!
    let numImagesToTrain = 3
    var useFrontCamera = true
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        enrolView.isHidden = true
        enrolButton.isEnabled = false
        
        
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
    
    @IBAction func didTapOnEnrol(_ sender: Any) {
        guard let name = nameLabel.text, !name.isEmpty else {
            return
        }
        
        enrolButton.isEnabled = false
        takePicImageView.isUserInteractionEnabled = false
        enrolButton.setTitle("Enrolling...", for: .normal)
        nameLabel.resignFirstResponder()
        enrolImages(name: name)
        
    }
    @IBAction func didTapOnX(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    @objc func didTapOnTakePhoto() {
        takePhoto()
    }
    @objc func toggleCamera() {
        useFrontCamera = !useFrontCamera
        sessionPrepare(front: useFrontCamera)
        session?.startRunning()
        
    }
    @objc func didTapOnCameraView() {
        nameLabel.resignFirstResponder()
    }
    func enrolImages(name: String) {
        if let unSubmittedEnrol = enrolCollectionView.nextUnsubmittedEnrol {
            doEnrol(unSubmittedEnrol, name: name)
        } else {
            finishEnrol()
        }
    }
    func doEnrol(_ enrol: Enrollment, name: String) {
        let image = enrol.image
        KairosAPI.sharedInstance.enrol(image, subjectId: name) { [unowned self] result in
            switch result {
            case .success(let analyzis):
                self.doneEnrol(enrol, name: name)
            //self.setUIForResponse(.analyzed(analyzis))
            case .error(let error):
                print(error)
                self.enrolError(enrol, name: name, error: error)
                //self.setUIForResponse(.error(error))
            }
        }
    }
    func enrolError(_ enrol: Enrollment, name: String, error: String) {
        enrol.errorSubmitting(message: error)
        enrolCollectionView.updateEnrol(enrol)
        enrolImages(name: name)
    }
    
    func doneEnrol(_ enrol: Enrollment, name: String) {
        enrol.submitted(name: name)
        enrolCollectionView.updateEnrol(enrol)
        enrolImages(name: name)
    }
    func finishEnrol() {
        enrolReady(false)
        takePicImageView.isUserInteractionEnabled = true
    }

    func takePhoto() {
        
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (CMSampleBuffer, Error) in
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(CMSampleBuffer!) {
                    
                    if let cameraImage = UIImage(data: imageData) {
                        let newEnrol = self.enrolCollectionView.makeNewEnrol()
                        newEnrol.newImage(image: cameraImage)
                        self.enrolCollectionView.addNewResult(newEnrol)
                        self.enrolReady(true)
                  }
                }
            })
        }
    }
    func enrolReady(_ ready: Bool) {
        if ready {
            enrolView.isHidden = false
            enrolButton.isEnabled = true
            enrolButton.setTitle("Enrol", for: .normal)
        } else {
            enrolView.isHidden = true
            enrolButton.isEnabled = false
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

}





