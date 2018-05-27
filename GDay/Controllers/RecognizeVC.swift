//
//  RecognizeVC.swift
//  GDay
//
//  Created by Erik Mai on 25/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import UIKit
import AVFoundation

class DetailsView: UIView {
    func setup() {
        layer.borderColor = UIColor.red.withAlphaComponent(0.7).cgColor
        layer.borderWidth = 5.0
    }
}


class RecognizeVC: UIViewController {
    fileprivate var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
    
    @IBOutlet weak var audioImageView: UIImageView!
    @IBOutlet weak var toggleCameraImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var resultCollectionView: ResultCollectionView!
    @IBOutlet weak var outputLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
 
    let stillImageOutput = AVCaptureStillImageOutput()
    var autoRecognize = false
    
    var lastRecognizeRequestTimeStamp = Double(0)
    var lastFaceDetectTimeStamp = Double(0)
    
    var useFrontCamera = false
    var voiceEnabled = true
    
    let synthesizer = AVSpeechSynthesizer()
    
    var results = [Result]()
    let numHistoryKept = 3
    var skipFirstNSeconds = Double(3)   // 3 seconds since first face frame before starting recoginzing
    var detectMinGap = Double(15)       // every dectection should be at least 10 seconds apart
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let audioSession = AVAudioSession.sharedInstance()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(RecognizeVC.toggleCamera))
        toggleCameraImageView.isUserInteractionEnabled = true
        toggleCameraImageView.addGestureRecognizer(tap)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(RecognizeVC.toggleAudio))
        audioImageView.isUserInteractionEnabled = true
        audioImageView.addGestureRecognizer(tap2)
        
        
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
        } catch let sessionError {
            print(sessionError)
        }
        
        sessionPrepare(front: useFrontCamera)
        session?.startRunning()
        statusLabel.text = "Ready"
        
        outputLabel.text = ""
        if let previewLayer = previewLayer {
            cameraView.layer.addSublayer(previewLayer)
        }
        cameraView.addSubview(detailsView)
        cameraView.bringSubview(toFront: detailsView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.frame
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        guard let previewLayer = previewLayer else { return }
//
//
//
//    }
    
    func startCountDown() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(RecognizeVC.updateTimer)), userInfo: nil, repeats: true)
    }
    @objc func updateTimer() {
        let now = Date().timeIntervalSince1970
        let elapsed = now - lastRecognizeRequestTimeStamp
        let remaining = Int64(detectMinGap - elapsed)
        if remaining <= 0 {
            statusLabel.text = "Ready"
            timer.invalidate()
            return
        }
        statusLabel.text = "\(remaining) s"
    }
    
    @IBAction func didTapOnX(_ sender: Any) {
        
        dismiss(animated: false, completion: nil)
    }
    @objc func toggleAudio() {
        voiceEnabled = !voiceEnabled
        audioImageView.image = voiceEnabled ? UIImage(named: "audio") : UIImage(named: "mute")
    }
    @objc func toggleCamera() {
        useFrontCamera = !useFrontCamera
        sessionPrepare(front: useFrontCamera)
        session?.startRunning()
    }
    
    func recognize() {
        
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (CMSampleBuffer, Error) in
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(CMSampleBuffer!) {
                    
                    if let cameraImage = UIImage(data: imageData) {
                        self.doRecognize(image: cameraImage)
                        //UIImageWriteToSavedPhotosAlbum(cameraImage, nil, nil, nil)
                    }
                }
            })
        }
    }
    
    func takePicAndRecognize() {
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (CMSampleBuffer, Error) in
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(CMSampleBuffer!) {
                    
                    if let cameraImage = UIImage(data: imageData) {
                        self.doRecognize(image: cameraImage)
                    }
                }
            })
        }
    }
    
    func doAutoRecognize() {
        takePicAndRecognize()
    }
    func doRecognize(image: UIImage) {
        self.outputLabel.text = "Detecting..."
        KairosAPI.sharedInstance.recognize(image) { [unowned self] result in
            
            self.startCountDown()
            let newDetected = Result()
            newDetected.image = image
            
            switch result {
            case .success(let users):
                newDetected.users = users
                //self.doneRecognized(users: users, image: image)
               
            //self.setUIForResponse(.analyzed(analyzis))
            case .error(let error):
                print(error)
                //self.outputLabel.text = "G'day"
                //self.setUIForResponse(.error(error))
            }
            self.doneRecognized(result: newDetected)
        }
    }
    
    func sayGreeting(_ greeting: String) {
        let utterance = AVSpeechUtterance(string: greeting)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-AU")
        utterance.rate = 0.5
        utterance.volume = 0.6
        synthesizer.speak(utterance)
    }
    func doneRecognized(result: Result) {
        results.append(result)
        if results.count > numHistoryKept {
            results.remove(at: 0)
        }
        
        let greeting = result.buildGreeting()
        self.outputLabel.text = greeting
        if voiceEnabled {
            sayGreeting(greeting)
        }
        resultCollectionView.addNewResult(result)
    }
    
    @IBAction func didTapOnRecognize(_ sender: Any) {
//        if let button = sender as? UIButton {
//            if button.currentTitle == "Recognize" {
//                autoRecognize = true
//                button.setTitle("Stop", for: .normal)
//            } else {
//                autoRecognize = false
//                button.setTitle("Recognize", for: .normal)
//            }
//        }
        takePicAndRecognize()
        
    }
    var images = [UIImage]()
   
    var session: AVCaptureSession?
    var stillOutput = AVCaptureStillImageOutput()
    var borderLayer: CAShapeLayer?
    
    let detailsView: DetailsView = {
        let detailsView = DetailsView()
        detailsView.setup()
        
        return detailsView
    }()
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
    
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyLow])
 

}

extension RecognizeVC {
    
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
            
//            let videoDataOutput = AVCaptureVideoDataOutput()
//            videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
            
            
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(videoDataOutput) {
                videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
                session.addOutput(videoDataOutput)
            }
            
            session.commitConfiguration()
            
            
        } catch {
            print("error with creating AVCaptureDeviceInput")
        }
    }
}

extension RecognizeVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        let options: [String : Any] = [CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
                                       CIDetectorSmile: true,
                                       CIDetectorEyeBlink: true]
        let allFeatures = faceDetector?.features(in: ciImage, options: options)
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
        
        guard let features = allFeatures else { return }
        
        for feature in features {
            
            if let faceFeature = feature as? CIFaceFeature {
                
                let faceRect = calculateFaceRect(facePosition: faceFeature.mouthPosition, faceBounds: faceFeature.bounds, clearAperture: cleanAperture)
                update(with: faceRect)
                let now = Date().timeIntervalSince1970
                let elapsed = now - lastRecognizeRequestTimeStamp
                print(elapsed)
                if elapsed > detectMinGap {
                    //elapsed = now - lastFaceDetectTimeStamp
                    //if elapsed > skipFirstNSeconds {
                    //    lastFaceDetectTimeStamp = now
                        lastRecognizeRequestTimeStamp = now
                        doAutoRecognize()
                    //}
                }
                
            }
        }
        
        if features.count == 0 {
            DispatchQueue.main.async {
                self.detailsView.alpha = 0.0
            }
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)  {
        
        
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 1
        default:
            return 6
        }
    }
    
    func videoBox(frameSize: CGSize, apertureSize: CGSize) -> CGRect {
        let apertureRatio = apertureSize.height / apertureSize.width
        let viewRatio = frameSize.width / frameSize.height
        
        var size = CGSize.zero
        
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width
            size.height = apertureSize.width * (frameSize.width / apertureSize.height)
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width)
            size.height = frameSize.height
        }
        
        var videoBox = CGRect(origin: .zero, size: size)
        
        if (size.width < frameSize.width) {
            videoBox.origin.x = (frameSize.width - size.width) / 2.0
        } else {
            videoBox.origin.x = (size.width - frameSize.width) / 2.0
        }
        
        if (size.height < frameSize.height) {
            videoBox.origin.y = (frameSize.height - size.height) / 2.0
        } else {
            videoBox.origin.y = (size.height - frameSize.height) / 2.0
        }
        
        return videoBox
    }
    
    func calculateFaceRect(facePosition: CGPoint, faceBounds: CGRect, clearAperture: CGRect) -> CGRect {
        let parentFrameSize = previewLayer!.frame.size
        let previewBox = videoBox(frameSize: parentFrameSize, apertureSize: clearAperture.size)
        
        var faceRect = faceBounds
        
        swap(&faceRect.size.width, &faceRect.size.height)
        swap(&faceRect.origin.x, &faceRect.origin.y)
        
        let widthScaleBy = previewBox.size.width / clearAperture.size.height
        let heightScaleBy = previewBox.size.height / clearAperture.size.width
        
        faceRect.size.width *= widthScaleBy
        faceRect.size.height *= heightScaleBy
        faceRect.origin.x *= widthScaleBy
        faceRect.origin.y *= heightScaleBy
        
        faceRect = faceRect.offsetBy(dx: 0.0, dy: previewBox.origin.y)
        let frame = CGRect(x: parentFrameSize.width - faceRect.origin.x - faceRect.size.width - previewBox.origin.x / 2.0, y: faceRect.origin.y, width: faceRect.width, height: faceRect.height)
        
        return frame
    }
    
}
extension RecognizeVC {
    func update(with faceRect: CGRect) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.detailsView.alpha = 1.0
                self.detailsView.frame = faceRect
            }
        }
    }
}
