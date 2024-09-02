import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    var onGestureDetected: ((String) -> Void)?
    
    var cameraView: CameraView!
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var lastPrintTime: Date?
    private let printInterval: TimeInterval = 1.0 // 设置为1秒

    override func loadView() {
        view = UIView()
        addCameraView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "HandPoseDetection"
    }
    
    func addCameraView() {
        cameraView = CameraView()
        view.addSubview(cameraView)
        
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func setupAVSession() throws {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw AppError.captureSessionSetup(reason: "Could not find a front facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    func processPoints(_ points: [CGPoint?]) {
        let previewLayer = cameraView.previewLayer
        var pointsConverted: [CGPoint] = []
        for point in points {
            pointsConverted.append(previewLayer.layerPointConverted(fromCaptureDevicePoint: point!))
        }

        let thumbTip = pointsConverted[0]
        let wrist = pointsConverted[pointsConverted.count - 1]
        
        let yDistance = thumbTip.y - wrist.y
        
        let now = Date()
        if lastPrintTime == nil || now.timeIntervalSince(lastPrintTime!) >= printInterval {
            if yDistance > 50 {
                print("👎")
                onGestureDetected?("👎")
            } else if yDistance < -50 {
                print("👍")
                onGestureDetected?("👍")
            } else {
                print("✋")
                onGestureDetected?("✋")
            }
            lastPrintTime = now
        }

        cameraView.showPoints(pointsConverted)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                cameraView.showPoints([])
                return
            }
            
            let thumbPoints = try observation.recognizedPoints(.thumb)
            let wristPoints = try observation.recognizedPoints(.all)
            
            guard let thumbTipPoint = thumbPoints[.thumbTip],
                  let wristPoint = wristPoints[.wrist]
            else {
                cameraView.showPoints([])
                return
            }
            
            let confidenceThreshold: Float = 0.3
            guard thumbTipPoint.confidence > confidenceThreshold &&
                  wristPoint.confidence > confidenceThreshold
            else {
                cameraView.showPoints([])
                return
            }
            
            let thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            let wrist = CGPoint(x: wristPoint.location.x, y: 1 - wristPoint.location.y)
            
            DispatchQueue.main.async {
                self.processPoints([thumbTip, wrist])
            }
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}
