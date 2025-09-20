//
//  ViewController.swift
//  faceADE
//
//  Created by Katherine Guo on 4/23/24.
//  Edited by Anthony Newman 7/8/25
//

import UIKit
import ARKit
import AVFoundation
import Photos
import ReplayKit

//for setting neutral expression value capture
struct NeutralExpressionValues {
    let leftDMEyeHeight:  Float
    let rightDMEyeHeight:  Float
    let leftDMEyeArea:  Float
    let rightDMEyeArea:  Float
    let leftDMLLMovement:  Float
    let rightDMLLMovement:  Float
    let leftDMMouthArea:  Float
    let rightDMMouthArea:  Float
}

class ViewController: UIViewController, ARSCNViewDelegate, UIDocumentPickerDelegate{
    
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return pickerData.count
//    }
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return pickerData[row]
//    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        viewOption = pickerData[row]
//        // Optionally, update the label immediately after selection
//        // updateSymmetryLabel()
//    }
 
    //for setting neutral expression
    private var neutralExpression: NeutralExpressionValues?
    
    @IBOutlet weak var sceneView: ARSCNView!
   
    //creating switches for mesh and dots
    @IBOutlet weak var meshSwitch: UISwitch!
    @IBOutlet weak var dotsSwitch: UISwitch!
    
    @IBAction func meshSwitchChanged(_ sender: UISwitch) {
        isMeshEnabled = sender.isOn
        faceMeshNode?.isHidden = !sender.isOn
    }

    @IBAction func dotsSwitchChanged(_ sender: UISwitch) {
        isDotsEnabled = sender.isOn
        dotNodes.forEach { $0.isHidden = !sender.isOn }
    }
    
    //Set Neutral Button
    @IBAction func setNeutralPressed(_ sender: UIButton) {
        // Grab the “current” properties
        let values = NeutralExpressionValues (
            leftDMEyeHeight: currentleftEyeHeight,
            rightDMEyeHeight: currentrightEyeHeight,
            leftDMEyeArea: currentinsideLeftEyeArea,
            rightDMEyeArea: currentinsideRightEyeArea,
            leftDMLLMovement: currentLeftBotLipMes,
            rightDMLLMovement: currentRightBotLipMes,
            leftDMMouthArea: currentLeftMouthArea,
            rightDMMouthArea: currentRightMouthArea,
        )
        // Store them
        neutralExpression = values

        // give user feedback
        sender.setTitle("Neutral ✔︎", for: .normal)
        
        guard let window = view.window else {
            print("⚠️ No key window to snapshot")
            return
        }
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        let fullScreenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = fullScreenshot else {
            print("❌ Failed to capture full screen")
            return
        }

           // Request permission & save into Photos
           PHPhotoLibrary.requestAuthorization { status in
               guard status == .authorized else {
                   print("📷 Photo library access denied")
                   return
               }
               PHPhotoLibrary.shared().performChanges({
                   PHAssetChangeRequest.creationRequestForAsset(from: image)
               }) { success, error in
                   if let error = error {
                       print("❌ Error saving snapshot: \(error.localizedDescription)")
                   } else {
                       print("✅ Neutral expression snapshot saved!")
                   }
               }
           }
    }
    
    @IBOutlet weak var setNeutralButton: UIButton!

   // screenshot button
    @IBOutlet weak var screenshotButton: UIButton!
    
    @IBAction func screenshotPressed(_sender:UIButton) {
        // 1) Capture the full screen
           guard let window = view.window else {
               print("⚠️ No key window to snapshot")
               return
           }
           UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
           window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
           let fullImage = UIGraphicsGetImageFromCurrentImageContext()
           UIGraphicsEndImageContext()

           guard let image = fullImage else {
               print("❌ Failed to capture screenshot")
               return
           }

           // Ask for permission and save to Photos
           PHPhotoLibrary.requestAuthorization { status in
               guard status == .authorized else {
                   print("📷 Photo library access denied")
                   return
               }
               PHPhotoLibrary.shared().performChanges({
                   PHAssetChangeRequest.creationRequestForAsset(from: image)
               }) { success, error in
                   if let error = error {
                       print("❌ Error saving screenshot: \(error.localizedDescription)")
                   } else {
                       print("✅ Screenshot saved to Photos!")
                   }
               }
           }
    }
    @IBAction func screenshotPressed(_ sender: Any) {
    }
   
    //Fields for Last Name, First Name, DOB, MRN
    @IBOutlet weak var lastNameField:  UITextField!
    @IBAction func lastname(_ sender: Any) {
    }
    @IBOutlet weak var firstNameField: UITextField!
    @IBAction func firstname(_ sender: Any) {
    }
    @IBOutlet weak var dobField:       UITextField!
    @IBAction func dob(_ sender: Any) {
    }
    @IBOutlet weak var mrnField:       UITextField!
    @IBAction func mrn(_ sender: Any) {
    }
    
    //Clear Button
    @IBOutlet weak var clearButton: UIButton!
    @IBAction func clear(_ sender: Any) {
    }
    
    @IBAction func clearPressed(_ sender: UIButton) {
        // 1) Clear each text field
            lastNameField.text  = ""
            firstNameField.text = ""
            dobField.text       = ""
            mrnField.text       = ""

            // 2) (Optional) return placeholders back
            lastNameField.placeholder  = "Enter last name"
            firstNameField.placeholder = "Enter first name"
            dobField.placeholder       = "MM/DD/YYYY"
            mrnField.placeholder       = "Enter MRN"

            // 3) (Optional) dismiss the keyboard if it’s up
            view.endEditing(true)
    }
    
    var faceGeometry: ARSCNFaceGeometry?
    var symmetryLabel: UILabel!
    var mouthLabel: UILabel!
    var eyeLabel: UILabel!
    var dmLabel: UILabel!
    private var faceMeshNode: SCNNode?
    private var dotNodes: [SCNNode] = []
    private var isMeshEnabled = true
    private var isDotsEnabled = true

    //for csv
    private var csvFileURL: URL?
    private var csvFileHandle: FileHandle?
    private var dataTimer: Timer?
    private var secondsElapsed = 0
    
    // for landmarks CSV for ML (all XYZ coords for 1220 vertices)
    private var landmarkCsvFileURL: URL?
    private var landmarkFileHandle: FileHandle?
    private var frameCounter = 0
    
    //variables for CSV
    private var currentinsideMouthArea: Float  = 0
    private var currentCommissureWidth: Float = 0
    private var currentLeftMouthVertical: Float       = 0
    private var currentRightMouthVertical: Float       = 0
    private var currentRightTopLipMes: Float       = 0
    private var currentLeftTopLipMes: Float       = 0
    private var currentRightBotLipMes: Float       = 0
    private var currentLeftBotLipMes: Float       = 0
    private var currentleftEyeHeight: Float       = 0
    private var currentrightEyeHeight: Float       = 0
    private var currentinsideRightEyeArea: Float    = 0
    private var currentinsideLeftEyeArea: Float    = 0
    private var currentRightEyeWidth: Float    = 0
    private var currentLeftEyeWidth: Float    = 0
    private var currentLeftMouthArea: Float = 0
    private var currentRightMouthArea: Float = 0
    
    //variables for CSV but dynamic movement
    private var currentpctDMLeftEyeHeight: Float = 0
    private var currentpctDMRightEyeHeight: Float = 0
    private var currentpctDMLeftEyeArea: Float = 0
    private var currentpctDMRightEyeArea: Float = 0
    private var currentpctDMLeftLLMovement: Float = 0
    private var currentpctDMRightLLMovement: Float = 0
    private var currentpctDMLeftMouthArea: Float = 0
    private var currentpctDMRightMouthArea: Float = 0
    
    
    var userId: String = "katherine" // Replace this with actual user ID logic
//    var maxHeightDifference: Float = 0.0
//    var maxWidthDifference: Float = 0.0
    var maxDentalShow: Float = 0.0
    var minDentalShow: Float = .greatestFiniteMagnitude
    var maxRightMouthArea: Float = 0.0
    var minRightMouthArea: Float = .greatestFiniteMagnitude
    var maxLeftMouthArea: Float = 0.0
    var minLeftMouthArea: Float = .greatestFiniteMagnitude
    var minLeftMouthCorner_x: Float = .greatestFiniteMagnitude
    var maxLeftMouthCorner_x: Float = 0.0
    var minLeftMouthCorner_y: Float = .greatestFiniteMagnitude
    var maxLeftMouthCorner_y: Float = 0.0
    var minRightMouthCorner_x: Float = .greatestFiniteMagnitude
    var maxRightMouthCorner_x: Float = 0.0
    var minRightMouthCorner_y: Float = .greatestFiniteMagnitude
    var maxRightMouthCorner_y: Float = 0.0
    var minCommissureWidth: Float = .greatestFiniteMagnitude
    var maxCommissureWidth: Float = 0.0
    var minLeftMouthVertical: Float = .greatestFiniteMagnitude
    var maxLeftMouthVertical: Float = 0.0
    var minRightMouthVertical: Float = .greatestFiniteMagnitude
    var maxRightMouthVertical: Float = 0.0
    var minLeftCommPosLowLip: Float = .greatestFiniteMagnitude
    var maxLeftCommPosLowLip: Float = 0.0
    var minRightCommPosLowLip: Float = .greatestFiniteMagnitude
    var maxRightCommPosLowLip: Float = 0.0
    var minFPsymComLowLip: Float = .greatestFiniteMagnitude
    var maxFPsymComLowLip: Float = 0.0
    var minFPsymMouthVertical: Float = .greatestFiniteMagnitude
    var maxFPsymMouthVertical: Float = 0.0
    var minNPsymComLowLip: Float = .greatestFiniteMagnitude
    var maxNPsymComLowLip: Float = 0.0
    var minNPsymMouthVertical: Float = .greatestFiniteMagnitude
    var maxNPsymMouthVertical: Float = 0.0
    var minRightTopLipMes: Float = .greatestFiniteMagnitude
    var maxRightTopLipMes: Float = 0.0
    var minLeftTopLipMes: Float = .greatestFiniteMagnitude
    var maxLeftTopLipMes: Float = 0.0
    var minRightBotLipMes: Float = .greatestFiniteMagnitude
    var maxRightBotLipMes: Float = 0.0
    var minLeftBotLipMes: Float = .greatestFiniteMagnitude
    var maxLeftBotLipMes: Float = 0.0
    
    var chinPosition: SCNVector3?

//    var currHeightDifference: Float = 0.0
//    var currWidthDifference: Float = 0.0
//    var savedHeightDifference: Float = 0.0
//    var savedWidthDifference: Float = 0.0
    var minLeftEyeClosure: Float = .greatestFiniteMagnitude
    var minRightEyeClosure: Float = .greatestFiniteMagnitude
    var maxLeftEye: Float = 0.0
    var maxRightEye: Float = 0.0
    var minLeftEyeArea: Float = .greatestFiniteMagnitude
    var maxLeftEyeArea: Float = 0.0
    var minRightEyeArea: Float = .greatestFiniteMagnitude
    var maxRightEyeArea: Float = 0.0
    var minFPsymEyeHeight: Float = .greatestFiniteMagnitude
    var maxFPsymEyeHeight: Float = 0.0
    var minNPsymEyeHeight: Float = .greatestFiniteMagnitude
    var maxNPsymEyeHeight: Float = 0.0
    var minRightEyeWidth: Float = .greatestFiniteMagnitude
    var maxRightEyeWidth: Float = 0.0
    var minLeftEyeWidth: Float = .greatestFiniteMagnitude
    var maxLeftEyeWidth: Float = 0.0
    
    
    func makeLocalQuadNodeSCN(_ pts: [SCNVector3]) -> SCNNode {
        // Create a vertex source from the list of SCNVector3
        let source = SCNGeometrySource(vertices: pts)
        
        // Build indices for a fan‐triangulation: (0,1,2), (0,2,3), …
        var indices = [Int16]()
        for i in 1..<pts.count-1 {
            indices += [0, Int16(i), Int16(i+1)]
        }
        let data = Data(bytes: indices,
                        count: indices.count * MemoryLayout<Int16>.size)
        let element = SCNGeometryElement(
            data:          data,
            primitiveType: .triangles,
            primitiveCount: indices.count/3,
            bytesPerIndex: MemoryLayout<Int16>.size
        )
        
        let geo = SCNGeometry(sources: [source], elements: [element])
        geo.firstMaterial?.diffuse.contents  = UIColor.blue.withAlphaComponent(0.4)
        geo.firstMaterial?.lightingModel     = .constant
        
        return SCNNode(geometry: geo)
    }

    func addSpheresSCN(_ points: [SCNVector3], to parent: SCNNode) {
        // Remove old markers
        parent.childNode(withName: "markers", recursively: false)?.removeFromParentNode()
        let container = SCNNode()
        container.name = "markers"
        
        for p in points {
            let sphere = SCNSphere(radius: 0.02)
            sphere.firstMaterial?.diffuse.contents = UIColor.red
            let sNode = SCNNode(geometry: sphere)
            sNode.position = p
            container.addChildNode(sNode)
        }
        parent.addChildNode(container)
    }


    
    var resetButton: UIButton!
    var saveRestingButton: UIButton!
    
    var toolbar: UIToolbar!
//    var videoWriter: AVAssetWriter?
//    var videoWriterInput: AVAssetWriterInput?
//    var videoWriterAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    @IBOutlet weak var recordingButton: UIButton!
//    @IBAction func stopRecordingButton(_ sender: UIButton!) {
//    }
//    var startRecordingButton: UIButton!
//    var stopRecordingButton: UIButton!
//    var captureSession: AVCaptureSession!
//    var photoOutput: AVCapturePhotoOutput!
    var videoWriterFinished = false
    
    var screenRecorder = RPScreenRecorder.shared()
    var isRecording = false

    
//    var pickerView: UIPickerView!
//    var pickerData: [String] = ["Smile", "Eye Closure"] // Example options
//    var viewOption: String = "Smile" // Default selected option
    
    
//    @IBAction func saveRecords(_ sender: UIBarButtonItem) {
//        let record = FaceRecord(userId: self.userId, timestamp: Date(), minLeftEyeClosure: minLeftEyeClosure, minRightEyeClosure: minRightEyeClosure)
//       records.append(record)
//       print("Record saved: \(records.last!)")
//    }
//    @IBAction func saveRecords(_ sender: UIButton) {
//        let record = FaceRecord(userId: self.userId, timestamp: Date(), minLeftEyeClosure: minLeftEyeClosure, minRightEyeClosure: minRightEyeClosure)
//       records.append(record)
//       print("Record saved: \(records.last!)")
//    }
    
    var centeredFaceMesh: [String: CGPoint] = [:] // Store centered mesh data
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        sceneView.delegate = self
        
        meshSwitch.isOn = isMeshEnabled
        dotsSwitch.isOn = isDotsEnabled
        
       
        // Create the ARSCNFaceGeometry
        if let device = sceneView.device, let geom = ARSCNFaceGeometry(device: device) {
            faceGeometry = geom
            if let material = faceGeometry?.firstMaterial {
                material.diffuse.contents = UIColor.clear
                material.transparency = 0
                material.fillMode = .lines
            }
        }

        
        setupARSession()
        setupUI()
        requestPhotoLibraryPermissions()
        

        
        // Initialize and configure the label
        //        symmetryLabel = UILabel()
        //        symmetryLabel.frame = CGRect(x: 20, y: 100, width: 1000, height: 40)
        //        symmetryLabel.textColor = .white
        //        symmetryLabel.backgroundColor = .clear
        //        symmetryLabel.textAlignment = .center
        //        symmetryLabel.numberOfLines = 0 // Allow multiple lines
        //        //        setupLabelConstraints()
        //
        //
        //        self.view.addSubview(symmetryLabel)
        //
        // Initialize and configure the label
        //        xLabel = UILabel()
        //        xLabel.frame = CGRect(x: 20, y: 200, width: 300, height: 40)
        //        xLabel.textColor = .white
        //        xLabel.backgroundColor = .clear
        //        xLabel.textAlignment = .center
        //        //        setupLabelConstraints()
        //
        //
        //        self.view.addSubview(xLabel)
        
        //        // Initialize and configure the reset button
        //        resetButton = UIButton(type: .system)
        //        resetButton.frame = CGRect(x: 20, y: 400, width: 100, height: 50) // Adjust as needed
        //        resetButton.setTitle("Reset", for: .normal)
        //        resetButton.setTitleColor(.white, for: .normal)
        //        resetButton.backgroundColor = .red
        //        resetButton.addTarget(self, action: #selector(resetMaxValues), for: .touchUpInside)
        //
        //        self.view.addSubview(resetButton)
        //
        //        // Initialize and configure the save resting values button
        //        saveRestingButton = UIButton(type: .system)
        //        saveRestingButton.frame = CGRect(x: 140, y: 400, width: 100, height: 50) // Adjust as needed
        //        saveRestingButton.setTitle("Save Resting Values", for: .normal)
        //        saveRestingButton.setTitleColor(.white, for: .normal)
        //        saveRestingButton.backgroundColor = .blue
        //        saveRestingButton.addTarget(self, action: #selector(saveRestingValues), for: .touchUpInside)
        //
        //        self.view.addSubview(saveRestingButton)
        
        //        // Initialize and configure the start recording button
        //       startRecordingButton = UIButton(type: .system)
        //       startRecordingButton.frame = CGRect(x: 20, y: 370, width: 160, height: 50) // Adjust as needed
        //       startRecordingButton.setTitle("Start Recording", for: .normal)
        //       startRecordingButton.setTitleColor(.white, for: .normal)
        //       startRecordingButton.backgroundColor = .green
        //       startRecordingButton.addTarget(self, action: #selector(startRecordingTapped), for: .touchUpInside)
        //
        //       self.view.addSubview(startRecordingButton)
        //
        //       // Initialize and configure the stop recording button
        //       stopRecordingButton = UIButton(type: .system)
        //       stopRecordingButton.frame = CGRect(x: 200, y: 370, width: 160, height: 50) // Adjust as needed
        //       stopRecordingButton.setTitle("Stop Recording", for: .normal)
        //       stopRecordingButton.setTitleColor(.white, for: .normal)
        //       stopRecordingButton.backgroundColor = .orange
        //       stopRecordingButton.addTarget(self, action: #selector(stopRecordingTapped), for: .touchUpInside)
        //
        //       self.view.addSubview(stopRecordingButton)
    }
    
    func setupUI() {
//        let containerView = UIView()
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        self.view.addSubview(containerView)
        
//        let recordingButton = UIButton(type: .system)
//        recordingButton.setTitle("Start Recording", for: .normal)
//        recordingButton.setTitleColor(.white, for: .normal)
//        recordingButton.backgroundColor = .green
//        recordingButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
//        recordingButton.tag = 100 // Use a tag to identify the button later
//        recordingButton.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(recordingButton)
//
//        let resetButton = UIButton(type: .system)
//        resetButton.setTitle("Reset Values", for: .normal)
//        resetButton.setTitleColor(.white, for: .normal)
//        resetButton.backgroundColor = .red
//        resetButton.translatesAutoresizingMaskIntoConstraints = false
//        resetButton.addTarget(self, action: #selector(resetMaxValues), for: .touchUpInside)
//        containerView.addSubview(resetButton)
//
//        let saveRestingButton = UIButton(type: .system)
//        saveRestingButton.setTitle("Save Resting Values", for: .normal)
//        saveRestingButton.setTitleColor(.white, for: .normal)
//        saveRestingButton.backgroundColor = .blue
//        saveRestingButton.translatesAutoresizingMaskIntoConstraints = false
//        saveRestingButton.addTarget(self, action: #selector(saveRestingValues), for: .touchUpInside)
//        containerView.addSubview(saveRestingButton)
        
        
        // Constraints for container view
//        NSLayoutConstraint.activate([
//            containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//            containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
//            containerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
//            containerView.heightAnchor.constraint(equalToConstant: 50)
//        ])
        
        // Constraints for buttons
//        NSLayoutConstraint.activate([
//            recordingButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
//            recordingButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
//            recordingButton.heightAnchor.constraint(equalToConstant: 40),
//
//            resetButton.leadingAnchor.constraint(equalTo: recordingButton.trailingAnchor, constant: 20),
//            resetButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
//            resetButton.heightAnchor.constraint(equalToConstant: 40),
//
//            saveRestingButton.leadingAnchor.constraint(equalTo: resetButton.trailingAnchor, constant: 20),
//            saveRestingButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
//            saveRestingButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
//            saveRestingButton.heightAnchor.constraint(equalToConstant: 40)
//        ])
//
//        // Equal width constraint
//        NSLayoutConstraint.activate([
//            recordingButton.widthAnchor.constraint(equalTo: resetButton.widthAnchor),
//            resetButton.widthAnchor.constraint(equalTo: saveRestingButton.widthAnchor)
//        ])
//
        // Initialize and add symmetryLabel
        symmetryLabel = UILabel()
        symmetryLabel.translatesAutoresizingMaskIntoConstraints = false
        symmetryLabel.textColor = .white
        symmetryLabel.backgroundColor = .clear
        symmetryLabel.textAlignment = .center
        symmetryLabel.numberOfLines = 0 // Allow multiple lines
        self.view.addSubview(symmetryLabel)
        
        // Constraints for symmetryLabel
        NSLayoutConstraint.activate([
            symmetryLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            symmetryLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100),
            symmetryLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            symmetryLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
        ])
        
        // Initialize and configure mouthLabel
        mouthLabel = UILabel()
        mouthLabel.translatesAutoresizingMaskIntoConstraints = true
        mouthLabel.textColor = .white
        mouthLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        mouthLabel.textAlignment = .left
        mouthLabel.numberOfLines = 0 // Allow multiple lines
        mouthLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        // Initialize and configure eyeLabel
        eyeLabel = UILabel()
        eyeLabel.translatesAutoresizingMaskIntoConstraints = true
        eyeLabel.textColor = .white
        eyeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        eyeLabel.textAlignment = .left
        eyeLabel.numberOfLines = 0 // Allow multiple lines
        eyeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        // Initialize and configure dmLabel (for dynamic movement scores)
        dmLabel = UILabel()
        dmLabel.translatesAutoresizingMaskIntoConstraints = true
        dmLabel.textColor = .white
        dmLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dmLabel.textAlignment = .center
        dmLabel.numberOfLines = 0 // Allow multiple lines
        dmLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // a) horizontal stack for the top two
        let topRow = UIStackView(arrangedSubviews: [mouthLabel, eyeLabel])
        topRow.axis         = .horizontal
        topRow.spacing      = 8
        topRow.distribution = .fillEqually

        // b) vertical stack that contains that row above + the dmLabel
        let container = UIStackView(arrangedSubviews: [topRow, dmLabel])
        container.axis         = .vertical
        container.spacing      = 12
        container.alignment    = .center
        container.distribution = .fillProportionally
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        NSLayoutConstraint.activate([
          container.topAnchor.constraint(    equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
          container.leadingAnchor.constraint(equalTo: view.leadingAnchor,                    constant: 20),
          container.trailingAnchor.constraint(equalTo: view.trailingAnchor,                   constant: -20),
        ])
            
        
//        // Initialize and add pickerView
//        pickerView = UIPickerView()
//        pickerView.translatesAutoresizingMaskIntoConstraints = false
//        pickerView.delegate = self
//        pickerView.dataSource = self
//        self.view.addSubview(pickerView)
//
//        // Constraints for pickerView
//        NSLayoutConstraint.activate([
//                pickerView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
//                pickerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//                pickerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
//            ])
//
//        let saveButton = UIButton(type: .system)
//        saveButton.setTitle("Save Record", for: .normal)
//        saveButton.addTarget(self, action: #selector(saveRecord), for: .touchUpInside)
//        saveButton.frame = CGRect(x: 20, y: 50, width: 100, height: 50)
//        self.view.addSubview(saveButton)
        
//        let showRecordsButton = UIButton(type: .system)
//        showRecordsButton.setTitle("Show Records", for: .normal)
//        showRecordsButton.addTarget(self, action: #selector(showRecords), for: .touchUpInside)
//        showRecordsButton.frame = CGRect(x: 150, y: 50, width: 100, height: 50)
//        self.view.addSubview(showRecordsButton)
    }
    
    
//    @objc func saveRecord() {
//        let record = FaceRecord(userId: self.userId, timestamp: Date(), minLeftEyeClosure: minLeftEyeClosure, minRightEyeClosure: minRightEyeClosure)
//           records.append(record)
//           print("Record saved: \(records.last!)")
//       }
        
//    @objc func showRecords() {
//           performSegue(withIdentifier: "showRecords", sender: self)
//       }
//
//       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//           if segue.identifier == "showRecords",
//              let destinationVC = segue.destination as? RecordsViewController {
//               destinationVC.records = records
//           }
//       }
    
    func setupARSession() {
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Check if the device supports face tracking
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didAdd node: SCNNode,
                  for anchor: ARAnchor) {
        guard let faceAnchor   = anchor as? ARFaceAnchor,
              let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)
        else { return }

        let m = faceGeometry.firstMaterial!
        m.transparency    = 0.50 //to adjust mesh visibility
        m.diffuse.contents = UIColor.white
        m.fillMode        = .lines

        let meshNode = SCNNode(geometry: faceGeometry)
        node.addChildNode(meshNode)

        self.faceMeshNode  = meshNode
        meshNode.isHidden  = !isMeshEnabled

        faceGeometry.update(from: faceAnchor.geometry)
    }
    
    
    
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let faceAnchor = anchor as? ARFaceAnchor,
//              let faceGeometry = node.childNodes.first?.geometry as? ARSCNFaceGeometry else { return }
//
//        faceGeometry.update(from: faceAnchor.geometry)
//
////        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
//
//        // Extract the vertex source data
//        if let vertexSource = faceGeometry.sources.first(where: { $0.semantic == .vertex }) {
//            let vertexData = vertexSource.data
//            let vertexStride = vertexSource.dataStride
//            let vertexOffset = vertexSource.dataOffset
//
////            xData, at: 1094, stride: vertexStride, offset: vertexOffset),
////            let leftEyeBottomVertex = getVertexPosition(from: vertexData, at: 1107, stride: vertexStride, offset: vertexOffset),
////            let rightEyeTopVertex = getVertexPosition(from: vertexData, at: 1075, stride: vertexStride, offset: vertexOffset),
////            let rightEyeBottomVertex = getVertexPosition(from: vertexData, at: 1063
//            let mouth_indices = [249, 684, 188, 637]
////            let inside_mouth_indices = [249, 393, 250, 251, 252, 253, 254, 255, 256, 24, 691, 690, 689, 688, 687, 686, 685, 823, 684, 834, 740, 683, 682, 710, 725, 709, 700, 25, 265, 274, 290, 275, 247, 248, 305, 404]
//            let inside_mouth_indices = [249, 250, 252, 254, 256, 691, 689, 687, 685, 684, 740, 682, 725, 700, 274, 290, 247, 305]
//
//            let eye_indices = [1107, 1094, 1075, 1063]
////            for i in mouth_indices{
////                placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .blue)
////            }
//            if self.viewOption == "Smile" {
//                        for i in mouth_indices {
//                            self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .red)
//                        }
////                        for i in inside_mouth_indices {
////                            self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .red)
////                        }
//                        for i in eye_indices {
//                            self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .blue)
//                        }
//                    } else if self.viewOption == "Eye Closure" {
//                        for i in eye_indices {
//                            self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .red)
//                        }
//                        for i in mouth_indices {
//                            self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .blue)
//                        }
//                    }
//
//            guard let leftMouthVertex = getVertexPosition(from: vertexData, at: 249, stride: vertexStride, offset: vertexOffset),
//                  let rightMouthVertex = getVertexPosition(from: vertexData, at: 684, stride: vertexStride, offset: vertexOffset),
//                  let leftEyeTopVertex = getVertexPosition(from: vertexData, at: 1094, stride: vertexStride, offset: vertexOffset),
//                  let leftEyeBottomVertex = getVertexPosition(from: vertexData, at: 1107, stride: vertexStride, offset: vertexOffset),
//                  let rightEyeTopVertex = getVertexPosition(from: vertexData, at: 1075, stride: vertexStride, offset: vertexOffset),
//                  let rightEyeBottomVertex = getVertexPosition(from: vertexData, at: 1063, stride: vertexStride, offset: vertexOffset) else { return }
//
//            // Convert the y-coordinates to centimeters
//            let leftMouthHeightCM = leftMouthVertex.y * 100
//            let rightMouthHeightCM = rightMouthVertex.y * 100
//
//            // Convert the x-coordinates to centimeters
//            let leftMouthWidthCM = abs(leftMouthVertex.x * 100)
//            let rightMouthWidthCM = abs(rightMouthVertex.x * 100)
//
//            var inside_mouth_nodes: [SCNVector3] = []
//
//            for index in inside_mouth_indices {
//                if let position = getVertexPosition(from: vertexData, at: index, stride: vertexStride, offset: vertexOffset) {
//                    inside_mouth_nodes.append(position)
//                }
//            }
////            let insideMouthArea = calculatePolygonArea(vertices: inside_mouth_nodes) * 10000
////            print(insideMouthArea)
//
//            // Calculate the height difference
//            let heightDifference = abs(leftMouthHeightCM - rightMouthHeightCM)
//            currHeightDifference = heightDifference
//
//            // Calculate the width difference
//            let widthDifference = abs(leftMouthWidthCM - rightMouthWidthCM)
//            currWidthDifference = widthDifference
//
//            // Update the label with the height difference
//            //                DispatchQueue.main.async {
//            //                    self.symmetryLabel.text = String(format: "Smile Height Difference: %.2f cm", heightDifference)
//            //                    self.xLabel.text = String(format: "Smile Width Difference: %.2f cm", widthDifference)
//            //                }
//
//            // Update maximum height and width differences
//            maxHeightDifference = max(maxHeightDifference, heightDifference)
//            maxWidthDifference = max(maxWidthDifference, widthDifference)
//
//            let leftEyeHeight = abs(leftEyeTopVertex.y - leftEyeBottomVertex.y) * 100
//            let rightEyeHeight = abs(rightEyeTopVertex.y - rightEyeBottomVertex.y) * 100
//
//            minLeftEyeClosure = min(minLeftEyeClosure, leftEyeHeight)
//            minRightEyeClosure = min(minRightEyeClosure, rightEyeHeight)
//
//            saveMinEyeClosure(minLeft: minLeftEyeClosure, minRight: minRightEyeClosure)
//
//            // Update the label with the current and maximum differences
//            DispatchQueue.main.async {
//                //                    self.symmetryLabel.text = String(format: "Height Diff: %.2f cm\nX Diff: %.2f cm\nMax Height Diff: %.2f cm\nMax X Diff: %.2f cm\nResting Height Diff: %.2f cm\nResting X Diff: %.2fcm", heightDifference,widthDifference, self.maxHeightDifference, self.maxWidthDifference, self.savedHeightDifference, self.savedWidthDifference)
//                //                    self.symmetryLabel.sizeToFit()
//                switch self.viewOption {
//                case "Smile":
////                    for i in mouth_indices {
////                                        if let dotNode = self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .red) {
////                                            node.addChildNode(dotNode)
////                                        }
////                                    }
////                    for i in eye_indices {
////                                        if let dotNode = self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .blue) {
////                                            node.addChildNode(dotNode)
////                                        }
////                                    }
//                    self.updateSmileSymmetryLabel(left_x: leftMouthWidthCM, right_x: rightMouthWidthCM, left_y: leftMouthHeightCM, right_y: rightMouthHeightCM, area: 0.0)
//                case "Eye Closure":
////                    for i in eye_indices {
////                                        if let dotNode = self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .red) {
////                                            node.addChildNode(dotNode)
////                                        }
////                                    }
////                    for i in mouth_indices {
////                                        if let dotNode = self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .blue) {
////                                            node.addChildNode(dotNode)
////                                        }
////                                    }
//                    self.updateEyeSymmetryLabel(left_eye_height: leftEyeHeight, right_eye_height: rightEyeHeight, min_left_eye_height: self.minLeftEyeClosure, min_right_eye_height: self.minRightEyeClosure)
//                default:
//                    break
//                }
//            }
//
//
//        //        // Dispatch UI updates on the main thread
//        //        DispatchQueue.main.async {
//        //            self.updateSymmetryLabel(distance)
//        //        }
//    }
                                                         
//            placeDotOnVertex(at: 249, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
//            placeDotOnVertex(at: 684, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
            /*
             // Place a dot on the 20th vertex
             // upper lip
             let indices = [249, 393, 250, 251, 252, 253, 254, 255, 256, 24, 691, 690, 689, 688, 687, 685, 684]
             // let indices = [1..<200]
             for i in indices{
             //for i in 800..<1200 {
             placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             placeDotOnVertexMirror(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             }
             
             //lower lip
             let ll_indices = [404, 305, 248, 247, 275, 290, 274, 265, 25, 700, 725, 710, 682, 683, 740, 834]
             for i in ll_indices{
             placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             placeDotOnVertexMirror(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             }
             
             let le_indices = Array(1085...1108)
             for i in le_indices{
             placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             placeDotOnVertexMirror(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             }
             let re_indices = Array(1061...1084)
             for i in re_indices{
             placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             placeDotOnVertexMirror(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             }
             let nose_bottom = [139, 313, 312, 308, 87, 441, 77, 76, 324, 4, 759, 525, 869, 536, 743, 747, 748, 588]
             for i in nose_bottom{
             placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             placeDotOnVertexMirror(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             }
             let fr = [639, 826, 634, 550, 726, 744, 748]
             let fl = [190, 396, 185, 101, 291, 309, 313]
             for i in fr{
             placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             placeDotOnVertexMirror(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             }
             for i in fl{
             placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             placeDotOnVertexMirror(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node)
             }*/
//            guard let leftMouthVertex = getVertexPosition(from: vertexData, at: 249, stride: vertexStride, offset: vertexOffset) else { return }
//            guard let rightMouthVertex = getVertexPosition(from: vertexData, at: 684, stride: vertexStride, offset: vertexOffset) else { return }
            //            let distance = Double(simd_distance(SIMD3<Float>(leftMouthVertex), SIMD3<Float>(rightMouthVertex)))
            //            let symmetryScore = calculateSymmetry(faceGeometry: faceGeometry)
            // Dispatch UI updates on the main thread
            //            DispatchQueue.main.async {
            //                self.updateSymmetryLabel(symmetryScore)
            //            }
            
//            if let vertexSource = faceGeometry.sources.first(where: { $0.semantic == .vertex }) {
//                let vertexData = vertexSource.data
//                let vertexStride = vertexSource.dataStride
//                let vertexOffset = vertexSource.dataOffset
                
                
//    }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.childNodes.first?.geometry as? ARSCNFaceGeometry else { return }
            
            //  append one row of all 1220 (x,y,z) (for machine learning (landmarks) CSV)
               if let lmHandle = landmarkFileHandle {
                   frameCounter += 1
                   let verts = faceAnchor.geometry.vertices  // [SIMD3<Float>], count = 1220
                   var line = "\(frameCounter)"
                   for v in verts {
                       line += ",\(v.x),\(v.y),\(v.z)"
                   }
                   line += "\n"
                   if let data = line.data(using: .utf8) {
                       lmHandle.write(data)
                   }
               }

            self.updateFaceGeometry(faceAnchor: faceAnchor, faceGeometry: faceGeometry, node: node)
        }
        func updateFaceGeometry(faceAnchor: ARFaceAnchor, faceGeometry: ARSCNFaceGeometry, node: SCNNode) {
            faceGeometry.update(from: faceAnchor.geometry)
            let vertsfornose = faceAnchor.geometry.vertices
            
            
            if let vertexSource = faceGeometry.sources.first(where: { $0.semantic == .vertex }) {
                let vertexData = vertexSource.data
                let vertexStride = vertexSource.dataStride
                let vertexOffset = vertexSource.dataOffset
                
        //test for left right mouth area modifications
                
                //defining noseTip and noseBridge
                let noseTip    = vertsfornose[9]
                let noseBridge = vertsfornose[15]
                
                //Creating plane from noseTip and noseBridge
                //  compute “ridge” vector pointing from tip → bridge
                   let ridgeVector = simd_normalize(noseBridge - noseTip)

                   // choosing face-down direction (negative Y in ARKit face-local)
                   let down = simd_float3(0, -1, 0)

                   // plane normal = cross(ridge, down) gives a vector pointing to one side
                   //     (and is perpendicular to the sagittal plane)
                   let planeNormal = simd_normalize(simd_cross(ridgeVector, down))
                
                
//                let mouthIndices = [638, 189] // , 188, 637]
                let mouthIndices = [190, 639, 290, 725] //  [172, 621] // [190, 639]
                let midlineIndices = [16, 8, 22] //midline (used to be eye)
                let lowerlipIndices = [25]
                //replace above with 25 and then make it white
                //lip outline for test values: 21,28,541,543,545,557,556,553,635,826,92,94,96,108,107,104,186,396,697,706,722,713,571,569,566,837,262,271,287,278,122,120,117,407
                let righteyeIndices = [1081, 1082, 1083, 1084, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070, 1071, 1072, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080]
                let lefteyeIndices = [1089, 1088, 1087, 1086, 1085, 1108, 1107, 1106, 1105, 1104, 1103, 1102, 1101, 1100, 1099, 1098, 1097, 1096, 1095, 1094, 1093, 1092, 1091, 1090]
                let chinIndices = [984,983] // 984 and 983 for vertical to lower lip
                let insideMouthIndices =  [24, 256, 255, 254, 253, 252, 251, 250, 393, 249, 404, 305, 248, 247, 275, 290, 274, 265, 25, 700, 709, 725, 710, 682, 683, 740, 834, 684, 823, 685, 686, 687, 688, 689, 690, 691]
                // 24,256, 255, 254, 253, 252, 251, 250, 393, 249, 404, 305, 248, 247, 275, 290, 274, 265, 25, 700, 709, 725, 720, 682, 683, 740, 834, 684, 823, 685, 686, 687, 688, 689, 690, 691
                let leftMouthIndices = [24,256, 255, 254, 253, 252, 251, 250, 393, 249, 404, 305, 248, 247, 275, 290, 274, 265, 25]
                let rightMouthIndices = [24, 691, 690, 689, 688, 687, 686, 685, 823, 684, 834, 740, 683, 682, 710, 725, 709, 700, 25]
                
                // 1) Compute centroid (for sorting for mouth areas)
                let allVerts = insideMouthIndices.map { vertsfornose[$0] }
                let centroidSimd = allVerts.reduce(simd_float3(0,0,0), +)
                                  / Float(insideMouthIndices.count)
                let centroid = SCNVector3(centroidSimd.x,
                                          centroidSimd.y,
                                          centroidSimd.z)

                // 2) Identify two midline landmarks
                let dotPairs = insideMouthIndices.map { idx in
                  let p = vertsfornose[idx]
                  let d = simd_dot(planeNormal, p - noseTip)
                  return (idx: idx, d: d)
                }
                let mids = dotPairs
                  .sorted { abs($0.d) < abs($1.d) }
                  .prefix(2)
                  .map { $0.idx }

                // 3) Half-space filter & include the mids
                var rightIndices = insideMouthIndices.filter { idx in
                  let d = simd_dot(planeNormal, vertsfornose[idx] - noseTip)
                  return d <= 0 || mids.contains(idx)
                }
                var leftIndices  = insideMouthIndices.filter { idx in
                  let d = simd_dot(planeNormal, vertsfornose[idx] - noseTip)
                  return d >= 0 || mids.contains(idx)
                }

                // 4) Sort each side _around_ the centroid (so it’s a proper loop)
                func sortAroundCentroid(_ idxs: [Int]) -> [Int] {
                  return idxs.sorted { iA, iB in
                    let a = vertsfornose[iA], b = vertsfornose[iB]
                    let θa = atan2(a.y - centroidSimd.y, a.x - centroidSimd.x)
                    let θb = atan2(b.y - centroidSimd.y, b.x - centroidSimd.x)
                    return θa < θb
                  }
                }
                rightIndices = sortAroundCentroid(rightIndices)
                leftIndices  = sortAroundCentroid(leftIndices)

                // 5) Map to SCNVector3 and measure
                let rightSCN = rightIndices.map { i in
                  let v = vertsfornose[i]; return SCNVector3(v.x, v.y, v.z)
                }
                let leftSCN  = leftIndices.map { i in
                  let v = vertsfornose[i]; return SCNVector3(v.x, v.y, v.z)
                }
                
                // Retrieve chin vertex position
                guard let chinVertex = getVertexPosition(from: vertexData, at: 1047, stride: vertexStride, offset: vertexOffset) else {
                    print("Chin vertex not found")
                    return
                }
                //self.placeDotOnVertex(at: 1047, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .white)

                // Store the chin position for later use
                self.chinPosition = chinVertex
                
//                if self.viewOption == "Smile" {
//                    for i in mouthIndices {
//                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .white)
//                    }
////                    for i in insideMouthIndices {
////                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .white)
////                    }
//                    for i in eyeIndices {
//                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .gray)
//                    }
//                } else if self.viewOption == "Eye Closure" {
////                    for i in insideMouthIndices {
////                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .gray)
////                    }
//                    for i in eyeIndices {
//                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .white)
//                    }
//                    for i in mouthIndices {
//                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .gray)
//                    }
//                }
                // 188, 637
                guard let rightMouthVertex = getVertexPosition(from: vertexData, at: 639, stride: vertexStride, offset: vertexOffset),  // 827
                      let leftMouthVertex = getVertexPosition(from: vertexData, at: 190, stride: vertexStride, offset: vertexOffset), // 397
                      let leftLowerLipVertex = getVertexPosition(from: vertexData, at: 290, stride: vertexStride, offset: vertexOffset),
                      let rightLowerLipVertex = getVertexPosition(from: vertexData, at: 725, stride: vertexStride, offset: vertexOffset),
                      let leftChinVertex = getVertexPosition(from: vertexData, at: 984, stride: vertexStride, offset: vertexOffset),
                      let rightChinVertex = getVertexPosition(from: vertexData, at: 983, stride: vertexStride, offset: vertexOffset),
                      let lowerLipMidlineVertex = getVertexPosition(from: vertexData, at: 25, stride: vertexStride, offset: vertexOffset), //lowerlipvertex for Commisure Position to Lower Lip Measurement
                      let nosebridgeVertex = getVertexPosition(from: vertexData, at: 15, stride: vertexStride, offset: vertexOffset), //nose bridge vertex for x-axis of lip movement
                      let midchinVertex = getVertexPosition(from: vertexData, at: 35, stride: vertexStride, offset: vertexOffset), // chin midline
                      let midlineTopVertex = getVertexPosition(from: vertexData, at: 21, stride: vertexStride, offset: vertexOffset), //MidLip Top
                      let mindlineBottomVertex = getVertexPosition(from: vertexData, at: 28, stride: vertexStride, offset: vertexOffset), //Midlip Bottom
                      let R1TLVertex = getVertexPosition(from: vertexData, at: 541, stride: vertexStride, offset: vertexOffset), //Left 1 Top Lip
                      let R2TLVertex = getVertexPosition(from: vertexData, at: 543, stride: vertexStride, offset: vertexOffset), //Left 2 Top Lip
                      let R3TLVertex = getVertexPosition(from: vertexData, at: 545, stride: vertexStride, offset: vertexOffset), //Left 3 Top Lip
                      let R4TLVertex = getVertexPosition(from: vertexData, at: 557, stride: vertexStride, offset: vertexOffset), //Left 4 Top Lip
                      let R5TLVertex = getVertexPosition(from: vertexData, at: 556, stride: vertexStride, offset: vertexOffset), //Left 5 Top Lip
                      let R6TLVertex = getVertexPosition(from: vertexData, at: 553, stride: vertexStride, offset: vertexOffset), //Left 6 Top Lip
                      let R7TLVertex = getVertexPosition(from: vertexData, at: 635, stride: vertexStride, offset: vertexOffset), //Left 7 Top Lip
                      let R8TLVertex = getVertexPosition(from: vertexData, at: 826, stride: vertexStride, offset: vertexOffset), //Left 8 Top Lip
                      let L1TLVertex = getVertexPosition(from: vertexData, at: 92, stride: vertexStride, offset: vertexOffset), //Right 1 Top Lip
                      let L2TLVertex = getVertexPosition(from: vertexData, at: 94, stride: vertexStride, offset: vertexOffset), //Right 2 Top Lip
                      let L3TLVertex = getVertexPosition(from: vertexData, at: 96, stride: vertexStride, offset: vertexOffset), //Right 3 Top Lip
                      let L4TLVertex = getVertexPosition(from: vertexData, at: 108, stride: vertexStride, offset: vertexOffset), //Right 4 Top Lip
                      let L5TLVertex = getVertexPosition(from: vertexData, at: 107, stride: vertexStride, offset: vertexOffset), //Right 5 Top Lip
                      let L6TLVertex = getVertexPosition(from: vertexData, at: 104, stride: vertexStride, offset: vertexOffset), //Right 6 Top Lip
                      let L7TLVertex = getVertexPosition(from: vertexData, at: 186, stride: vertexStride, offset: vertexOffset), //Right 7 Top Lip
                      let L8TLVertex = getVertexPosition(from: vertexData, at: 396, stride: vertexStride, offset: vertexOffset), //Right 8 Top Lip
                      let R1BLVertex = getVertexPosition(from: vertexData, at: 697, stride: vertexStride, offset: vertexOffset), //Left 1 Top Lip
                      let R2BLVertex = getVertexPosition(from: vertexData, at: 706, stride: vertexStride, offset: vertexOffset), //Left 2 Top Lip
                      let R3BLVertex = getVertexPosition(from: vertexData, at: 722, stride: vertexStride, offset: vertexOffset), //Left 3 Top Lip
                      let R4BLVertex = getVertexPosition(from: vertexData, at: 713, stride: vertexStride, offset: vertexOffset), //Left 4 Top Lip
                      let R5BLVertex = getVertexPosition(from: vertexData, at: 571, stride: vertexStride, offset: vertexOffset), //Left 5 Top Lip
                      let R6BLVertex = getVertexPosition(from: vertexData, at: 569, stride: vertexStride, offset: vertexOffset), //Left 6 Top Lip
                      let R7BLVertex = getVertexPosition(from: vertexData, at: 566, stride: vertexStride, offset: vertexOffset), //Left 7 Top Lip
                      let R8BLVertex = getVertexPosition(from: vertexData, at: 837, stride: vertexStride, offset: vertexOffset), //Left 8 Top Lip
                      let L1BLVertex = getVertexPosition(from: vertexData, at: 262, stride: vertexStride, offset: vertexOffset), //Right 1 Top Lip
                      let L2BLVertex = getVertexPosition(from: vertexData, at: 271, stride: vertexStride, offset: vertexOffset), //Right 2 Top Lip
                      let L3BLVertex = getVertexPosition(from: vertexData, at: 287, stride: vertexStride, offset: vertexOffset), //Right 3 Top Lip
                      let L4BLVertex = getVertexPosition(from: vertexData, at: 278, stride: vertexStride, offset: vertexOffset), //Right 4 Top Lip
                      let L5BLVertex = getVertexPosition(from: vertexData, at: 122, stride: vertexStride, offset: vertexOffset), //Right 5 Top Lip
                      let L6BLVertex = getVertexPosition(from: vertexData, at: 120, stride: vertexStride, offset: vertexOffset), //Right 6 Top Lip
                      let L7BLVertex = getVertexPosition(from: vertexData, at: 117, stride: vertexStride, offset: vertexOffset), //Right 7 Top Lip
                      let L8BLVertex = getVertexPosition(from: vertexData, at: 407, stride: vertexStride, offset: vertexOffset), //Right 8 Top Lip
                      let leftEyeInsideVertex = getVertexPosition(from: vertexData, at: 358, stride: vertexStride, offset: vertexOffset), //Left Eye Inside
                      let leftEyeOutsideVertex = getVertexPosition(from: vertexData, at: 1101, stride: vertexStride, offset: vertexOffset), //Left Eye Outside
                      let rightEyeInsideVertex = getVertexPosition(from: vertexData, at: 789, stride: vertexStride, offset: vertexOffset), //Right Eye Inside
                      let rightEyeOutsideVertex = getVertexPosition(from: vertexData, at: 1069, stride: vertexStride, offset: vertexOffset), //Right Eye Outside
                      let leftEyeTopVertex = getVertexPosition(from: vertexData, at: 1094, stride: vertexStride, offset: vertexOffset), // 1094
                      let leftEyeBottomVertex = getVertexPosition(from: vertexData, at: 1108, stride: vertexStride, offset: vertexOffset), // 1107
                      let rightEyeTopVertex = getVertexPosition(from: vertexData, at: 1076, stride: vertexStride, offset: vertexOffset), //1075
                      let rightEyeBottomVertex = getVertexPosition(from: vertexData, at: 1062, stride: vertexStride, offset: vertexOffset) else { return } // 1063
                    
                      let adjlowerlipmidlineVertex = SCNVector3(nosebridgeVertex.x, mindlineBottomVertex.y, mindlineBottomVertex.z)
                      let adjtoplipmidlineVertex = SCNVector3(nosebridgeVertex.x, midlineTopVertex.y, midlineTopVertex.z)
                
                
                var leftMouthNodes: [SCNVector3] = []
                    for index in leftMouthIndices {
                        if let position = getVertexPosition(from: vertexData, at: index, stride: vertexStride, offset: vertexOffset) {
                            leftMouthNodes.append(position)
                   }
               }
                var rightMouthNodes: [SCNVector3] = []
                    for index in rightMouthIndices {
                        if let position = getVertexPosition(from: vertexData, at: index, stride: vertexStride, offset: vertexOffset) {
                            rightMouthNodes.append(position)
                   }
               }
                
                var insideMouthNodes: [SCNVector3] = []
                    for index in insideMouthIndices {
                        if let position = getVertexPosition(from: vertexData, at: index, stride: vertexStride, offset: vertexOffset) {
                       insideMouthNodes.append(position)
                   }
               }
                
                var insiderighteyeNodes: [SCNVector3] = []
                            for index in righteyeIndices {
                                if let position = getVertexPosition(from: vertexData, at: index, stride: vertexStride, offset: vertexOffset) {
                                    insiderighteyeNodes.append(position)
                                }
                            }

                var insidelefteyeNodes: [SCNVector3] = []
                    for index in lefteyeIndices {
                                if let position = getVertexPosition(from: vertexData, at: index, stride: vertexStride, offset: vertexOffset) {
                                    insidelefteyeNodes.append(position)
                                }
                            }
                
                
                let leftMouthHeightCM = (leftMouthVertex.y - chinVertex.y) * 1000 // leftMouthVertex.y * 1000 + 5
                let rightMouthHeightCM = (rightMouthVertex.y - chinVertex.y) * 1000 // rightMouthVertex.y * 100 + 5
                
                let leftMouthWidthCM = abs(leftMouthVertex.x * 1000)
                let rightMouthWidthCM = abs(rightMouthVertex.x * 1000)
                
                let CommissureWidth = (abs(leftMouthVertex.x) + abs(rightMouthVertex.x)) * 1000  //CommissureWidth
                self.maxCommissureWidth = max(self.maxCommissureWidth, CommissureWidth)
                self.minCommissureWidth = min(self.minCommissureWidth, CommissureWidth)

                let LeftMouthVertical = (leftLowerLipVertex.y - leftChinVertex.y) * 1000 //Left Lip to Chin Verticle
                self.maxLeftMouthVertical = max(self.maxLeftMouthVertical, LeftMouthVertical)
                self.minLeftMouthVertical = min(self.minLeftMouthVertical, LeftMouthVertical)

                let RightMouthVertical = (rightLowerLipVertex.y - rightChinVertex.y) * 1000 //Right Lip to Chin Verticle
                self.maxRightMouthVertical = max(self.maxRightMouthVertical, RightMouthVertical)
                self.minRightMouthVertical = min(self.minRightMouthVertical, RightMouthVertical)
                
                let LeftCommPosLowLip = (sqrt(pow((leftMouthVertex.y - lowerLipMidlineVertex.y),2)+pow((leftMouthVertex.x-midchinVertex.x),2))) * 1000 //Left Hypotenuse Commissure Position to Lower Lip Midline, using x axis measured to chin y-axis for midline instead of lower lip midline
                self.maxLeftCommPosLowLip = max(self.maxLeftCommPosLowLip, LeftCommPosLowLip)
                self.minLeftCommPosLowLip = min(self.minLeftCommPosLowLip, LeftCommPosLowLip)

                let RightCommPosLowLip = (sqrt(pow((rightMouthVertex.y - lowerLipMidlineVertex.y),2)+pow((rightMouthVertex.x-midchinVertex.x),2))) * 1000 //Right Hypotenuse Commissure Position to Lower Lip Midline, using x axis measured to chin y-axis for midline instead of lower lip midline
                self.maxRightCommPosLowLip = max(self.maxRightCommPosLowLip, RightCommPosLowLip)
                self.minRightCommPosLowLip = min(self.minRightCommPosLowLip, RightCommPosLowLip)
                
                self.maxLeftMouthCorner_x = max(self.maxLeftMouthCorner_x, leftMouthWidthCM)
                self.maxLeftMouthCorner_y = max(self.maxLeftMouthCorner_y, leftMouthHeightCM)
                self.minLeftMouthCorner_x = min(self.minLeftMouthCorner_x, leftMouthWidthCM)
                self.minLeftMouthCorner_y = min(self.minLeftMouthCorner_y, leftMouthHeightCM)
                
                self.maxRightMouthCorner_x = max(self.maxRightMouthCorner_x, rightMouthWidthCM)
                self.maxRightMouthCorner_y = max(self.maxRightMouthCorner_y, rightMouthHeightCM)
                self.minRightMouthCorner_x = min(self.minRightMouthCorner_x, rightMouthWidthCM)
                self.minRightMouthCorner_y = min(self.minRightMouthCorner_y, rightMouthHeightCM)
                
//                let heightDifference = abs(leftMouthHeightCM - rightMouthHeightCM)
//                self.currHeightDifference = heightDifference
                
//                let widthDifference = abs(leftMouthWidthCM - rightMouthWidthCM)
//                self.currWidthDifference = widthDifference
                
//                self.maxHeightDifference = max(self.maxHeightDifference, heightDifference)
//                self.maxWidthDifference = max(self.maxWidthDifference, widthDifference)
                
                let leftEyeHeight = abs(leftEyeTopVertex.y - leftEyeBottomVertex.y) * 1000
                let rightEyeHeight = abs(rightEyeTopVertex.y - rightEyeBottomVertex.y) * 1000
                
               // let leftEyeHeight = (sqrt((pow((leftEyeTopVertex.y - leftEyeBottomVertex.y),2)+pow((leftEyeTopVertex.x - leftEyeBottomVertex.x),2)))) * 1000 // eye height hyp.
              //  let rightEyeHeight = (sqrt((pow((rightEyeTopVertex.y - rightEyeBottomVertex.y),2)+pow((rightEyeTopVertex.x - rightEyeBottomVertex.x),2)))) * 1000 // eye height hyp.

                self.minLeftEyeClosure = min(self.minLeftEyeClosure, leftEyeHeight)
                self.minRightEyeClosure = min(self.minRightEyeClosure, rightEyeHeight)
                self.maxLeftEye = max(self.maxLeftEye, leftEyeHeight)
                self.maxRightEye = max(self.maxRightEye, rightEyeHeight)
                
                let LeftEyeWidth = abs(leftEyeOutsideVertex.x - leftEyeInsideVertex.x) * 1000
                self.maxLeftEyeWidth = max(self.maxLeftEyeWidth, LeftEyeWidth)
                self.minLeftEyeWidth = min(self.maxLeftEyeWidth, LeftEyeWidth)
                
                let RightEyeWidth = abs(rightEyeOutsideVertex.x - rightEyeInsideVertex.x) * 1000
                self.maxRightEyeWidth = max(self.maxRightEyeWidth, RightEyeWidth)
                self.minRightEyeWidth = min(self.maxRightEyeWidth, RightEyeWidth)
                
                //AN Test using Sym Distance for Lip "quadrant" Calculations
                
                    //Right Top Lip XYZ Measurement
                let RightTopLipMes = ((adjtoplipmidlineVertex.distance(to: R1TLVertex)) + (R1TLVertex.distance(to: R2TLVertex)) + (R2TLVertex.distance(to: R3TLVertex)) + (R3TLVertex.distance(to: R4TLVertex)) + (R4TLVertex.distance(to: R5TLVertex)) + (R5TLVertex.distance(to: R6TLVertex)) + (R6TLVertex.distance(to: R7TLVertex)) + (R7TLVertex.distance(to: R8TLVertex)) + (R8TLVertex.distance(to: rightMouthVertex))) * 1000
                self.maxRightTopLipMes = max(self.maxRightTopLipMes, RightTopLipMes)
                self.minRightTopLipMes = min(self.minRightTopLipMes, RightTopLipMes)
                
                    //Left Top Lip XYZ Measurement
                let LeftTopLipMes = ((adjtoplipmidlineVertex.distance(to: L1TLVertex)) + (L1TLVertex.distance(to: L2TLVertex)) + (L2TLVertex.distance(to: L3TLVertex)) + (L3TLVertex.distance(to: L4TLVertex)) + (L4TLVertex.distance(to: L5TLVertex)) + (L5TLVertex.distance(to: L6TLVertex)) + (L6TLVertex.distance(to: L7TLVertex)) + (L7TLVertex.distance(to: L8TLVertex)) + (L8TLVertex.distance(to: leftMouthVertex))) * 1000
                self.maxLeftTopLipMes = max(self.maxLeftTopLipMes, LeftTopLipMes)
                self.minLeftTopLipMes = min(self.minLeftTopLipMes, LeftTopLipMes)
                
                    //Right Bottom Lip XYZ Measurement
                let RightBotLipMes = ((adjlowerlipmidlineVertex.distance(to: R1BLVertex)) + (R1BLVertex.distance(to: R2BLVertex)) + (R2BLVertex.distance(to: R3BLVertex)) + (R3BLVertex.distance(to: R4BLVertex)) + (R4BLVertex.distance(to: R5BLVertex)) + (R5BLVertex.distance(to: R6BLVertex)) + (R6BLVertex.distance(to: R7BLVertex)) + (R7BLVertex.distance(to: R8BLVertex)) + (R8BLVertex.distance(to: rightMouthVertex))) * 1000
                self.maxRightBotLipMes = max(self.maxRightBotLipMes, RightBotLipMes)
                self.minRightBotLipMes = min(self.minRightBotLipMes, RightBotLipMes)
                
                    //Left Bottom Lip XYZ Measurement
                let LeftBotLipMes = ((adjlowerlipmidlineVertex.distance(to: L1BLVertex)) + (L1BLVertex.distance(to: L2BLVertex)) + (L2BLVertex.distance(to: L3BLVertex)) + (L3BLVertex.distance(to: L4BLVertex)) + (L4BLVertex.distance(to: L5BLVertex)) + (L5BLVertex.distance(to: L6BLVertex)) + (L6BLVertex.distance(to: L7BLVertex)) + (L7BLVertex.distance(to: L8BLVertex)) + (L8BLVertex.distance(to: leftMouthVertex))) * 1000
                self.maxLeftBotLipMes = max(self.maxLeftBotLipMes, LeftBotLipMes)
                self.minLeftBotLipMes = min(self.minLeftBotLipMes, LeftBotLipMes)
                
                let insideRightEyeArea = calculatePolygonArea(vertices: insiderighteyeNodes) * 1000000
                self.maxRightEyeArea = max(self.maxRightEyeArea, insideRightEyeArea)
                self.minRightEyeArea = min(self.minRightEyeArea, insideRightEyeArea)

                let insideLeftEyeArea = calculatePolygonArea(vertices: insidelefteyeNodes) * 1000000
                self.maxLeftEyeArea = max(self.maxLeftEyeArea, insideLeftEyeArea)
                self.minLeftEyeArea = min(self.minLeftEyeArea, insideLeftEyeArea)
                
                let insideMouthArea = calculatePolygonArea(vertices: insideMouthNodes) * 1000000
                self.maxDentalShow = max(self.maxDentalShow, insideMouthArea)
                self.minDentalShow = min(self.minDentalShow, insideMouthArea)
                
                //test calculations for new left right mouth area calculations
                
                let rightMouthArea = calculatePolygonArea(vertices: rightSCN) * 1000000
                let leftMouthArea  = calculatePolygonArea(vertices: leftSCN) * 1000000
                
               // let rightMouthArea = calculatePolygonArea(vertices: rightMouthNodes) * 1000000
                self.maxRightMouthArea = max(self.maxRightMouthArea, rightMouthArea)
                self.minRightMouthArea = min(self.minRightMouthArea, rightMouthArea)
                
               // let leftMouthArea = calculatePolygonArea(vertices: leftMouthNodes) * 1000000
                self.maxLeftMouthArea = max(self.maxLeftMouthArea, leftMouthArea)
                self.minLeftMouthArea = min(self.minLeftMouthArea, leftMouthArea)
                
                // 1️⃣2️⃣ – (optional) visualize each half in a different color (for testing mouth area)
                //    node.childNode(withName: "rightMouth", recursively: false)?.removeFromParentNode()
                //    let rightNode = makeLocalQuadNodeSCN(rightSCN)
                //    rightNode.name = "rightMouth"
                //    rightNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.4)
                //    node.addChildNode(rightNode)

                 //   node.childNode(withName:  "leftMouth", recursively: false)?.removeFromParentNode()
                 //   let leftNode  = makeLocalQuadNodeSCN(leftSCN)
                 //   leftNode.name  = "leftMouth"
                 //   leftNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.4)
                //    node.addChildNode(leftNode)
               
                
                //Symmetry Scores - AN Test - Facial Palsy Patients - no longer used

                //Symmetry Score for Commissure to Midline of Lower Lip
                let FPsymComLowLip = (1-(abs(LeftCommPosLowLip-RightCommPosLowLip)/max(LeftCommPosLowLip,RightCommPosLowLip)))*100
                self.maxFPsymComLowLip = max(self.maxFPsymComLowLip, FPsymComLowLip)
                self.minFPsymComLowLip = min(self.minFPsymComLowLip, FPsymComLowLip)

                //Symmetry Score for Lip to Chin Vertical Distance
                let FPsymMouthVertical = (1-(abs(LeftMouthVertical-RightMouthVertical)/max(LeftMouthVertical,RightMouthVertical)))*100
                self.maxFPsymMouthVertical = max(self.maxFPsymMouthVertical, FPsymMouthVertical)
                self.minFPsymMouthVertical = min(self.minFPsymMouthVertical, FPsymMouthVertical)

                //Symmetry Score for Eye Height
                let FPsymEyeHeight = (1-(abs(leftEyeHeight-rightEyeHeight)/max(leftEyeHeight,rightEyeHeight)))*100
                self.maxFPsymEyeHeight = max(self.maxFPsymEyeHeight, FPsymEyeHeight)
                self.minFPsymEyeHeight = min(self.minFPsymEyeHeight, FPsymEyeHeight)
                
                //Symmetry Scores - AN Test - Unaffected Patients - no longer used

                //Symmetry Score for Commissure to Midline of Lower Lip
                let NPsymComLowLip = (1-(abs(LeftCommPosLowLip-RightCommPosLowLip)/((LeftCommPosLowLip + RightCommPosLowLip)/2)))*100
                self.maxNPsymComLowLip = max(self.maxNPsymComLowLip, FPsymComLowLip)
                self.minNPsymComLowLip = min(self.minNPsymComLowLip, FPsymComLowLip)

                //Symmetry Score for Lip to Chin Vertical Distance
                let NPsymMouthVertical = (1-(abs(LeftMouthVertical-RightMouthVertical)/((LeftMouthVertical + RightMouthVertical)/2)))*100
                self.maxNPsymMouthVertical = max(self.maxNPsymMouthVertical, NPsymMouthVertical)
                self.minNPsymMouthVertical = min(self.minNPsymMouthVertical, NPsymMouthVertical)

                //Symmetry Score for Eye Height
                let NPsymEyeHeight = (1-(abs(leftEyeHeight-rightEyeHeight)/((leftEyeHeight + rightEyeHeight)/2)))*100
                self.maxNPsymEyeHeight = max(self.maxNPsymEyeHeight, NPsymEyeHeight)
                self.minNPsymEyeHeight = min(self.minNPsymEyeHeight, NPsymEyeHeight)
                
                //Logging variables for CSV
                currentinsideMouthArea = insideMouthArea
                currentCommissureWidth = CommissureWidth
                currentLeftMouthVertical = LeftMouthVertical
                currentRightMouthVertical = RightMouthVertical
                currentRightTopLipMes = RightTopLipMes
                currentLeftTopLipMes = LeftTopLipMes
                currentRightBotLipMes = RightBotLipMes
                currentLeftBotLipMes = LeftBotLipMes
                currentleftEyeHeight = leftEyeHeight
                currentrightEyeHeight = rightEyeHeight
                currentinsideRightEyeArea = insideRightEyeArea
                currentinsideLeftEyeArea = insideLeftEyeArea
                currentRightEyeWidth = RightEyeWidth
                currentLeftEyeWidth = LeftEyeWidth
                currentLeftMouthArea = leftMouthArea
                currentRightMouthArea = rightMouthArea
                    
                    // 1) Remove last frame’s dots
                    dotNodes.forEach { $0.removeFromParentNode() }
                    dotNodes.removeAll()
                    
                    // 2) If toggle is OFF, skip drawing dots
                    if isDotsEnabled {
                        for i in mouthIndices {
                            let dot = placeDotOnVertex(at: i,
                                                       with: vertexData,
                                                       stride: vertexStride,
                                                       offset: vertexOffset,
                                                       on: node,
                                                       color: .white)
                            dotNodes.append(dot)
                        }
                        
                        for i in chinIndices {
                            let dot = placeDotOnVertex(at: i,
                                                       with: vertexData,
                                                       stride: vertexStride,
                                                       offset: vertexOffset,
                                                       on: node,
                                                       color: .white)
                            dotNodes.append(dot)
                        }
                        
                        for i in midlineIndices {
                            let dot = placeDotOnVertex(at: i,
                                                       with: vertexData,
                                                       stride: vertexStride,
                                                       offset: vertexOffset,
                                                       on: node,
                                                       color: .white)
                            dotNodes.append(dot)
                        }
                        
                        for i in lowerlipIndices {
                            let dot = placeDotOnVertex(at: i,
                                                       with: vertexData,
                                                       stride: vertexStride,
                                                       offset: vertexOffset,
                                                       on: node,
                                                       color: .white)
                            dotNodes.append(dot)
                        }
                    }
                    
                    
                    DispatchQueue.main.async {
                        self.updateMouthLabel(
                            left_x: leftMouthWidthCM,
                            min_left_x: self.minLeftMouthCorner_x,
                            max_left_x: self.maxLeftMouthCorner_x,
                            right_x: rightMouthWidthCM,
                            min_right_x: self.minRightMouthCorner_x,
                            max_right_x: self.maxRightMouthCorner_x,
                            left_y: leftMouthHeightCM,
                            min_left_y: self.minLeftMouthCorner_y,
                            max_left_y: self.maxLeftMouthCorner_y,
                            right_y: rightMouthHeightCM,
                            min_right_y: self.minRightMouthCorner_y,
                            max_right_y: self.maxRightMouthCorner_y,
                            area: insideMouthArea,
                            min_area: self.minDentalShow,
                            max_area: self.maxDentalShow,
                            cwdistance: CommissureWidth,
                            min_cwdistance: self.minCommissureWidth,
                            max_cwdistance: self.maxCommissureWidth,
                            left_mouth_vertical: LeftMouthVertical,
                            min_left_mouth_vertical: self.minLeftMouthVertical,
                            max_left_mouth_vertical: self.maxLeftMouthVertical,
                            right_mouth_vertical: RightMouthVertical,
                            min_right_mouth_vertical: self.minRightMouthVertical,
                            max_right_mouth_vertical: self.maxRightMouthVertical,
                            left_commissure_hypotenuse: LeftCommPosLowLip,
                            min_left_commissure_hypotenuse: self.minLeftCommPosLowLip,
                            max_left_commissure_hypotenuse: self.maxLeftCommPosLowLip,
                            right_commissure_hypotenuse: RightCommPosLowLip,
                            min_right_commissure_hypotenuse: self.minRightCommPosLowLip,
                            max_right_commissure_hypotenuse: self.maxRightCommPosLowLip,
                            fp_sym_com_low_lip: FPsymComLowLip,
                            min_fp_sym_com_low_lip: self.minFPsymComLowLip,
                            max_fp_sym_com_low_lip: self.maxFPsymComLowLip,
                            np_sym_com_low_lip: NPsymComLowLip,
                            min_np_sym_com_low_lip: self.minNPsymComLowLip,
                            max_np_sym_com_low_lip: self.maxNPsymComLowLip,
                            fp_sym_mouth_vertical: FPsymMouthVertical,
                            min_fp_sym_mouth_vertical: self.minFPsymMouthVertical,
                            max_fp_sym_mouth_vertical: self.maxFPsymMouthVertical,
                            np_sym_mouth_vertical: NPsymMouthVertical,
                            min_np_sym_mouth_vertical: self.minNPsymMouthVertical,
                            max_np_sym_mouth_vertical: self.maxNPsymMouthVertical,
                            right_top_lip_mes: RightTopLipMes,
                            min_right_top_lip_mes: self.minRightTopLipMes,
                            max_right_top_lip_mes: self.maxRightTopLipMes,
                            left_top_lip_mes: LeftTopLipMes,
                            min_left_top_lip_mes: self.minLeftTopLipMes,
                            max_left_top_lip_mes: self.maxLeftTopLipMes,
                            right_bot_lip_mes: RightBotLipMes,
                            min_right_bot_lip_mes: self.minRightBotLipMes,
                            max_right_bot_lip_mes: self.maxRightBotLipMes,
                            left_bot_lip_mes: LeftBotLipMes,
                            min_left_bot_lip_mes: self.minLeftBotLipMes,
                            max_left_bot_lip_mes: self.maxLeftBotLipMes,
                            left_mouth_area: leftMouthArea,
                            min_left_mouth_area: self.minLeftMouthArea,
                            max_left_mouth_area: self.maxLeftMouthArea,
                            right_mouth_area: rightMouthArea,
                            min_right_mouth_area: self.minRightMouthArea,
                            max_right_mouth_area: self.maxRightMouthArea
                        )
                            
                        self.updateEyeLabel(
                            left_eye_height: leftEyeHeight,
                            min_left_eye_height: self.minLeftEyeClosure,
                            max_left_eye_height: self.maxLeftEye,
                            right_eye_height: rightEyeHeight,
                            min_right_eye_height: self.minRightEyeClosure,
                            max_right_eye_height: self.maxRightEye,
                            right_eye_area: insideRightEyeArea,
                            min_right_eye_area: self.minRightEyeArea,
                            max_right_eye_area: self.maxRightEyeArea,
                            left_eye_area: insideLeftEyeArea,
                            min_left_eye_area: self.minLeftEyeArea,
                            max_left_eye_area: self.maxLeftEyeArea,
                            fp_sym_eye_height: FPsymEyeHeight,
                            min_fp_sym_eye_height: self.minFPsymEyeHeight,
                            max_fp_sym_eye_height: self.maxFPsymEyeHeight,
                            np_sym_eye_height: NPsymEyeHeight,
                            min_np_sym_eye_height: self.minNPsymEyeHeight,
                            max_np_sym_eye_height: self.maxNPsymEyeHeight,
                            right_eye_width: RightEyeWidth,
                            min_right_eye_width: self.minRightEyeWidth,
                            max_right_eye_width: self.maxRightEyeWidth,
                            left_eye_width: LeftEyeWidth,
                            min_left_eye_width: self.minLeftEyeWidth,
                            max_left_eye_width: self.maxLeftEyeWidth
                        )
                        //                    switch self.viewOption {
                        //                    case "Smile":
                        //                        self.updateSmileSymmetryLabel(
                        //                            left_x: leftMouthWidthCM,
                        //                            min_left_x: self.minLeftMouthCorner_x,
                        //                            max_left_x: self.maxLeftMouthCorner_x,
                        //                            right_x: rightMouthWidthCM,
                        //                            min_right_x: self.minRightMouthCorner_x,
                        //                            max_right_x: self.maxRightMouthCorner_x,
                        //                            left_y: leftMouthHeightCM,
                        //                            min_left_y: self.minLeftMouthCorner_y,
                        //                            max_left_y: self.maxLeftMouthCorner_y,
                        //                            right_y: rightMouthHeightCM,
                        //                            min_right_y: self.minRightMouthCorner_y,
                        //                            max_right_y: self.maxRightMouthCorner_y,
                        //                            area: insideMouthArea,
                        //                            max_area: self.maxDentalShow
                        //                        )
                        //                    case "Eye Closure":
                        //                        self.updateEyeSymmetryLabel(
                        //                            left_eye_height: leftEyeHeight,
                        //                            min_left_eye_height: self.minLeftEyeClosure,
                        //                            max_left_eye_height: self.maxLeftEye,
                        //                            right_eye_height: rightEyeHeight,
                        //                            min_right_eye_height: self.minRightEyeClosure,
                        //                            max_right_eye_height: self.maxRightEye
                        //                        )
                        //
                        //                    default:
                        //                        break
                        //                    }
                    }
               
                //Dynamic Movement Calculations
                        if let neutral = neutralExpression {
                            currentpctDMLeftEyeHeight = (abs(currentleftEyeHeight-neutral.leftDMEyeHeight)/neutral.leftDMEyeHeight)*100
                            currentpctDMRightEyeHeight = (abs(currentrightEyeHeight-neutral.rightDMEyeHeight)/neutral.rightDMEyeHeight)*100
                            
                            currentpctDMLeftEyeArea = (abs(currentinsideLeftEyeArea-neutral.leftDMEyeArea)/neutral.leftDMEyeArea)*100
                            currentpctDMRightEyeArea = (abs(currentinsideRightEyeArea-neutral.rightDMEyeArea)/neutral.rightDMEyeArea)*100
                            
                            currentpctDMLeftLLMovement = (abs(currentLeftBotLipMes-neutral.leftDMLLMovement)/neutral.leftDMLLMovement)*100
                            currentpctDMRightLLMovement = (abs(currentRightBotLipMes-neutral.rightDMLLMovement)/neutral.rightDMLLMovement)*100
                            
                            currentpctDMLeftMouthArea = (abs(currentLeftMouthArea-neutral.leftDMMouthArea)/neutral.leftDMMouthArea)*100
                            currentpctDMRightMouthArea = (abs(currentRightMouthArea-neutral.rightDMMouthArea)/neutral.rightDMMouthArea)*100
                            
                        } else {
                            currentpctDMLeftEyeHeight  = 0
                            currentpctDMRightEyeHeight = 0
                            currentpctDMLeftEyeArea  = 0
                            currentpctDMRightEyeArea = 0
                            currentpctDMLeftLLMovement = 0
                            currentpctDMRightLLMovement = 0
                            currentpctDMLeftMouthArea = 0
                            currentpctDMRightMouthArea = 0
                }
                    
                   }
                    
                        DispatchQueue.main.async {
                            self.updatedmLabel(
                                pct_dm_left_eye_height: self.currentpctDMLeftEyeHeight,
                                pct_dm_right_eye_height: self.currentpctDMRightEyeHeight,
                                pct_dm_left_eye_area: self.currentpctDMLeftEyeArea,
                                pct_dm_right_eye_area: self.currentpctDMRightEyeArea,
                                pct_dm_left_ll_movement: self.currentpctDMLeftLLMovement,
                                pct_dm_right_ll_movement: self.currentpctDMRightLLMovement,
                                pct_dm_left_mouth_area: self.currentpctDMLeftMouthArea,
                                pct_dm_right_mouth_area: self.currentpctDMRightMouthArea,
                        )
                    }
                }
        
    
    func calculatePolygonArea(vertices: [SCNVector3]) -> Float {
            var area: Float = 0.0
            let n = vertices.count
            
            for i in 0..<n {
                let j = (i + 1) % n
                area += vertices[i].x * vertices[j].y
                area -= vertices[i].y * vertices[j].x
            }
            area = abs(area) / 2.0
            return area
        }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    func saveMinEyeClosure(minLeft: Float, minRight: Float) {
        let record = FaceRecord(userId: userId, timestamp: Date(), minLeftEyeClosure: minLeft, minRightEyeClosure: minRight)

        // Retrieve existing records
        var records = loadEyeClosureRecords()
        records.append(record)

        // Save updated records
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "FaceRecords")
        }
    }

    func loadEyeClosureRecords() -> [FaceRecord] {
        if let data = UserDefaults.standard.data(forKey: "FaceRecords"),
           let records = try? JSONDecoder().decode([FaceRecord].self, from: data) {
            return records
        }
        return []
    }
        
        func requestPhotoLibraryPermissions() {
            PHPhotoLibrary.requestAuthorization { status in
                if status != .authorized {
                    print("Photo library access not authorized")
                }
            }
        }
        
        
        //    func setupCaptureSession() {
        //        captureSession = AVCaptureSession()
        //        captureSession.sessionPreset = .high
        //
        //        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
        //            fatalError("No front video device available")
        //        }
        //
        //        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
        //            fatalError("Cannot create video input")
        //        }
        //
        //        if captureSession.canAddInput(videoInput) {
        //            captureSession.addInput(videoInput)
        //        } else {
        //            fatalError("Cannot add video input")
        //        }
        //
        //        photoOutput = AVCapturePhotoOutput()
        //
        //        if captureSession.canAddOutput(photoOutput) {
        //            captureSession.addOutput(photoOutput)
        //        } else {
        //            fatalError("Cannot add photo output")
        //        }
        //
        //        captureSession.startRunning()
        //    }
        
        
        
        
        //    func captureFrame() {
        //        let photoSettings: AVCapturePhotoSettings
        //        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
        //            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        //        } else {
        //            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        //        }
        //        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        //    }
        
        //    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        //        if let error = error {
        //            print("Error capturing photo: \(error.localizedDescription)")
        //            return
        //        }
        //
        //        guard let imageData = photo.fileDataRepresentation() else {
        //            print("Error getting image data")
        //            return
        //        }
        //
        //        // Process the image data (e.g., save it to the photo library, display it, etc.)
        //    }
        
    @discardableResult
    func placeDotOnVertex(
        at index: Int,
        with vertexData: Data,
        stride vertexStride: Int,
        offset vertexOffset: Int,
        on node: SCNNode,
        color: UIColor
    ) -> SCNNode {
        // compute byteIndex & vertexPosition as before
        var position = SCNVector3Zero
        vertexData.withUnsafeBytes { buffer in
            let byteIndex = vertexStride * index + vertexOffset
            guard byteIndex + MemoryLayout<Float>.size * 3 <= buffer.count else {
                fatalError("Vertex index out of range")
            }
            let ptr = buffer.baseAddress!.advanced(by: byteIndex).assumingMemoryBound(to: Float.self)
            position = SCNVector3(ptr[0], ptr[1], ptr[2])
        }

        // create the dot node here
        let sphere = SCNSphere(radius: 0.001)
        sphere.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position

        // add it to the face‐mesh parent
        node.addChildNode(sphereNode)

        // return it so the caller can store it in dotNodes
        return sphereNode
    }
    
//    func placeDotOnVertex(at index: Int, with vertexData: Data, stride: Int, offset: Int, on node: SCNNode, color: UIColor) {
//        // Calculate the byte index for the desired vertex
//        let byteIndex = stride * index + offset
//
//        // Ensure the byte index + size of three floats does not exceed the buffer size
//        guard byteIndex + MemoryLayout<Float>.size * 3 <= vertexData.count else {
//            print("Vertex index out of range")
//            return
//        }
//
//        // Extract the relevant subdata
//        let subdata = vertexData[byteIndex..<byteIndex + MemoryLayout<Float>.size * 3]
//
//        // Convert subdata to an array of Floats
//        var vertexArray = [Float](repeating: 0, count: 3)
//        _ = vertexArray.withUnsafeMutableBytes { vertexArrayBuffer in
//            subdata.copyBytes(to: vertexArrayBuffer)
//        }
//
//        // Create the vertex position
//        let vertexPosition = SCNVector3(x: vertexArray[0], y: vertexArray[1], z: vertexArray[2])
//
//        // Add or update the dot at the vertex position
//        addOrUpdateDot(at: vertexPosition, at: index, on: node, color: color)
//    }
        
        func placeDotOnVertexMirror(at index: Int, with vertexData: Data, stride: Int, offset: Int, on node: SCNNode) {
            vertexData.withUnsafeBytes { buffer in
                // Calculate the byte index for the desired vertex
                let byteIndex = stride * index + offset
                
                // Ensure the byte index + size of three floats does not exceed the buffer size
                guard byteIndex + MemoryLayout<Float>.size * 3 <= buffer.count else {
                    print("Vertex index out of range")
                    return
                }
                
                // Access the vertex position directly
                let vertexPointer = buffer.baseAddress!.advanced(by: byteIndex).assumingMemoryBound(to: Float.self)
                let vertexPosition = SCNVector3(x: -vertexPointer[0], y: vertexPointer[1], z: vertexPointer[2])
                
                // Add or update the dot at the vertex position
                addOrUpdateMirrorDot(at: vertexPosition, at: index, on: node)
            }
        }
        
    func addOrUpdateDot(at position: SCNVector3, at index: Int, on node: SCNNode?, color: UIColor){
            guard let node = node else {
                print("Node is nil")
                return
            }
            let dotName = "vertexDot\(index)"  // Unique name for each dot
            let dotGeometry = SCNSphere(radius: 0.001) // Small sphere, adjust size as needed
            
            // Ensure that firstMaterial is initialized
            if dotGeometry.firstMaterial == nil {
                dotGeometry.firstMaterial = SCNMaterial()
            }
            
            dotGeometry.firstMaterial?.diffuse.contents = color
            dotGeometry.firstMaterial?.transparency = 1
            // Check if a dot node for this vertex already exists; update it or create a new one
//            let dotNode: SCNNode
            if let existingDotNode = node.childNode(withName: dotName, recursively: false) {
                existingDotNode.geometry = dotGeometry
                existingDotNode.position = position
            } else {
                let dotNode = SCNNode(geometry: dotGeometry)
                dotNode.name = dotName
                dotNode.position = position
                node.addChildNode(dotNode)
            }
            
            // Set the position of the dot node
//            dotNode.position = position
        }
        func removeNodes(nodes: [SCNNode]) {
            for node in nodes {
                node.removeFromParentNode()
            }
        }
        
        func addOrUpdateMirrorDot(at position: SCNVector3, at index: Int, on node: SCNNode) {
            let dotName = "vertexMirrorDot\(index)"  // Unique name for each dot
            let dotGeometry = SCNSphere(radius: 0.001) // Small sphere, adjust size as needed
            dotGeometry.firstMaterial?.diffuse.contents = UIColor.blue
            dotGeometry.firstMaterial?.transparency = 0.5
            // Check if a dot node for this vertex already exists; update it or create a new one
            let dotNode: SCNNode
            if let existingDotNode = node.childNode(withName: dotName, recursively: false) {
                dotNode = existingDotNode
                dotNode.geometry = dotGeometry
            } else {
                dotNode = SCNNode(geometry: dotGeometry)
                dotNode.name = dotName
                node.addChildNode(dotNode)
            }
            
            // Set the position of the dot node
            dotNode.position = position
        }
        
        //    func getAllVerticesOptimized(faceGeometry: ARFaceGeometry) -> [SIMD3<Float>] {
        //        let vertexCount = faceGeometry.vertexCount
        //        let verticesBuffer = faceGeometry.vertices
        //        let bufferPointer = verticesBuffer.contents()
        //
        //        // Prepare an array to store all vertex data
        //        var vertices = [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 0), count: vertexCount)
        //
        //        // Use memcpy to copy all data at once from the vertices buffer to the vertices array
        //        memcpy(&vertices, bufferPointer, verticesBuffer.stride * vertexCount)
        //
        //        return vertices
        //    }
        
        //    // Helper function to process vertex data from the face mesh
        //    func processVertexData(_ data: Data, stride: Int, offset: Int) -> [SIMD3<Float>] {
        //        let count = data.count / stride
        //        var vertices = [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 0), count: count)
        //
        //        for i in 0..<count {
        //            let baseAddress = data.withUnsafeBytes { $0.baseAddress! }
        //            let byteOffset = stride * i + offset
        //            let vertexPointer = baseAddress.advanced(by: byteOffset).assumingMemoryBound(to: Float.self)
        //            vertices[i] = SIMD3<Float>(vertexPointer[0], vertexPointer[1], vertexPointer[2])
        //        }
        //
        //        return vertices
        //    }
        
        
        func symmetryAngle(pointLeft: SCNVector3, pointRight: SCNVector3) -> Double {
            let angleRadians = atan2(pointLeft.y, pointRight.x)
            
            // Convert to Degrees:
            var angleDegrees = angleRadians * 180.0 / .pi
            
            // Normalize to 0-180 degrees:
            if angleDegrees < 0 {
                angleDegrees += 180.0
            }
            
            let deviation = abs(45.0 - angleDegrees)
            
            // Normalize to a percentage (0-100):
            let symmetryPercentage = (1.0 - (deviation / 90.0)) * 100.0
            
            // Symmetry percentage will now be:
            //   - 100% for perfectly symmetrical points
            //   - 0% for points with maximum asymmetry (90 degrees from 45 degrees)
            return Double(symmetryPercentage)
        }
        //    func calculateSymmetry(faceGeometry: ARSCNFaceGeometry) -> Double {
        //        guard let vertexSource = faceGeometry.sources.first(where: { $0.semantic == .vertex }),
        //              let leftMouth = getVertexPosition(//...),
        //              let rightMouth = getVertexPosition(//...),
        //              let noseTip = getVertexPosition(//...) else {
        //            return 0.0
        //        }
        //
        //        // Calculate offsets from the nose tip:
        //        let leftMouthOffset = SCNVector3(leftMouth.x - noseTip.x, leftMouth.y - noseTip.y, 0)
        //        let rightMouthOffset = SCNVector3(rightMouth.x - noseTip.x, rightMouth.y - noseTip.y, 0)
        //
        //        let symmetryAngle = self.symmetryAngle(pointLeft: leftMouthOffset, pointRight: rightMouthOffset)
        //        return symmetryAngle
        //    }
        
        
        // Calculate symmetry (directly using ARKit mesh data)
        //    func calculateSymmetry(faceGeometry: ARSCNFaceGeometry) -> Double {
        //        guard let vertexSource = faceGeometry.sources.first(where: { $0.semantic == .vertex }),
        //              let leftMouth = getVertexPosition(from: vertexSource.data,
        //                                                 at: 249,
        //                                                 stride: vertexSource.dataStride,
        //                                                 offset: vertexSource.dataOffset),
        //              let rightMouth = getVertexPosition(from: vertexSource.data,
        //                                                  at: 684,
        //                                                  stride: vertexSource.dataStride,
        //                                                  offset: vertexSource.dataOffset),
        //              let nose = getVertexPosition(from: vertexSource.data,
        //                                                  at: 4,
        //                                                  stride: vertexSource.dataStride,
        //                                                  offset: vertexSource.dataOffset)
        //        // TODO get distance between leftMouth and nose and rightMouth and nose
        //        else {
        //            return 0.0
        //        }
        //
        ////        let symmetryAngle = self.symmetryAngle(pointLeft: leftMouth, pointRight: rightMouth)
        //        // Calculate offsets from the nose tip:
        //        let leftMouthOffset = SCNVector3(leftMouth.x - nose.x, leftMouth.y - nose.y, 0)
        //        let rightMouthOffset = SCNVector3(rightMouth.x - nose.x, rightMouth.y - nose.y, 0)
        //
        ////        let symmetryAngle = self.symmetryAngle(pointLeft: leftMouthOffset, pointRight: rightMouthOffset)
        //        return symmetryAngle
        //    }
        
    @IBAction func resetMaxValues(_ sender: UIBarButtonItem) {
//        maxHeightDifference = 0.0
//        maxWidthDifference = 0.0
        maxDentalShow = 0.0
        minDentalShow = .greatestFiniteMagnitude
        minLeftMouthCorner_x = .greatestFiniteMagnitude
        maxLeftMouthCorner_x = 0.0
        minLeftMouthCorner_y = .greatestFiniteMagnitude
        maxLeftMouthCorner_y = 0.0
        minRightMouthCorner_x = .greatestFiniteMagnitude
        maxRightMouthCorner_x = 0.0
        minRightMouthCorner_y = .greatestFiniteMagnitude
        maxRightMouthCorner_y = 0.0
        minCommissureWidth = .greatestFiniteMagnitude
        maxCommissureWidth = 0.0
        minLeftMouthVertical = .greatestFiniteMagnitude
        maxLeftMouthVertical = 0.0
        minRightMouthVertical = .greatestFiniteMagnitude
        maxRightMouthVertical = 0.0
        minLeftCommPosLowLip = .greatestFiniteMagnitude
        maxLeftCommPosLowLip = 0.0
        minRightCommPosLowLip = .greatestFiniteMagnitude
        maxRightCommPosLowLip = 0.0
        minFPsymComLowLip = .greatestFiniteMagnitude
        maxFPsymComLowLip = 0.0
        minFPsymMouthVertical = .greatestFiniteMagnitude
        maxFPsymMouthVertical = 0.0
        minNPsymComLowLip = .greatestFiniteMagnitude
        maxNPsymComLowLip = 0.0
        minNPsymMouthVertical = .greatestFiniteMagnitude
        maxNPsymMouthVertical = 0.0
        minRightTopLipMes = .greatestFiniteMagnitude
        maxRightTopLipMes = 0.0
        minLeftTopLipMes = .greatestFiniteMagnitude
        maxLeftTopLipMes = 0.0
        minRightBotLipMes = .greatestFiniteMagnitude
        maxRightBotLipMes = 0.0
        minLeftBotLipMes = .greatestFiniteMagnitude
        maxLeftBotLipMes = 0.0
        minLeftMouthArea = .greatestFiniteMagnitude
        maxLeftMouthArea = 0.0
        minRightMouthArea = .greatestFiniteMagnitude
        maxRightMouthArea = 0.0
        neutralExpression   = nil
        setNeutralButton.setTitle("Set Neutral Expression", for: .normal)
        
        
        
        
    //    var currHeightDifference: Float = 0.0
    //    var currWidthDifference: Float = 0.0
    //    var savedHeightDifference: Float = 0.0
    //    var savedWidthDifference: Float = 0.0

        maxLeftEye = 0.0
        maxRightEye = 0.0
        minRightEyeClosure = .greatestFiniteMagnitude
        minLeftEyeClosure = .greatestFiniteMagnitude
        minLeftEyeArea = .greatestFiniteMagnitude
        maxLeftEyeArea = 0.0
        minRightEyeArea = .greatestFiniteMagnitude
        maxRightEyeArea = 0.0
        minFPsymEyeHeight = .greatestFiniteMagnitude
        maxFPsymEyeHeight = 0.0
        minNPsymEyeHeight = .greatestFiniteMagnitude
        maxNPsymEyeHeight = 0.0
        minRightEyeWidth = .greatestFiniteMagnitude
        maxRightEyeWidth = 0.0
        minLeftEyeWidth = .greatestFiniteMagnitude
        maxLeftEyeWidth = 0.0
        
        DispatchQueue.main.async {
            self.symmetryLabel.text = "Values have been reset"
            self.symmetryLabel.sizeToFit() // Adjust the label size based on content
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Option A: Clear the text
            self.symmetryLabel.text = ""
            self.symmetryLabel.sizeToFit()
            
            // Option B: Alternatively, reset to default metrics or previous state
            // self.symmetryLabel.text = "Default Metrics Here"
            // self.symmetryLabel.sizeToFit()
        }
    }
    
//    @objc func resetMaxValues() {
//            maxHeightDifference = 0.0
//            maxWidthDifference = 0.0
//            DispatchQueue.main.async {
//                self.symmetryLabel.text = "Values have been reset"
//                self.symmetryLabel.sizeToFit() // Adjust the label size based on content
//            }
//        }
        
        @objc func saveRestingValues() {
            return
//            savedHeightDifference = currHeightDifference
//            savedWidthDifference = currWidthDifference
            //            DispatchQueue.main.async {
            //                self.symmetryLabel.text = String(format: "Height Diff: --\nMax Height Diff: %.2f cm\nX Diff: --\nMax X Diff: %.2f cm\nSaved Height Diff: %.2f cm\nSaved X Diff: %.2f cm", self.maxHeightDifference, self.maxXDifference, self.savedHeightDifference, self.savedXDifference)
            //                self.symmetryLabel.sizeToFit() // Adjust the label size based on content
            //            }
        }
        
//        func getVertexPosition(from vertexData: Data, at index: Int, stride: Int, offset: Int) -> SCNVector3? {
//            return vertexData.withUnsafeBytes { buffer -> SCNVector3? in
//                // Calculate the byte index for the desired vertex
//                let byteIndex = stride * index + offset
//
//                // Ensure the byte index + size of three floats does not exceed the buffer size
//                guard byteIndex + MemoryLayout<Float>.size * 3 <= buffer.count else {
//                    print("Vertex index out of range")
//                    return nil
//                }
//
//                // Access the vertex position directly
//                let vertexPointer = buffer.baseAddress!.advanced(by: byteIndex).assumingMemoryBound(to: Float.self)
//                return SCNVector3(x: vertexPointer[0], y: vertexPointer[1], z: vertexPointer[2])
//            }
//        }
    
    func getVertexPosition(from vertexData: Data, at index: Int, stride: Int, offset: Int) -> SCNVector3? {
        let totalBytes = vertexData.count
        let vertexSize = MemoryLayout<Float>.size * 3
        let startByte = stride * index + offset

        guard startByte + vertexSize <= totalBytes else {
            print("Vertex index out of range")
            return nil
        }

        let x = vertexData[startByte..<startByte + 4].withUnsafeBytes { $0.load(as: Float.self) }
        let y = vertexData[startByte + 4..<startByte + 8].withUnsafeBytes { $0.load(as: Float.self) }
        let z = vertexData[startByte + 8..<startByte + 12].withUnsafeBytes { $0.load(as: Float.self) }

        return SCNVector3(x: x, y: y, z: z)
    }

        
        //    func calculateSymmetry(faceAnchor: ARFaceAnchor) -> Double {
        //        //        let leftEye = faceAnchor.leftEyeTransform.columns.3
        //        //        let rightEye = faceAnchor.rightEyeTransform.columns.3
        //        //        let nose = faceAnchor.transform.columns.3
        //        //
        //        //        // Calculate horizontal distances from the nose (midline)
        //        //        let leftEyeDistance = abs(leftEye.x - nose.x)
        //        //        let rightEyeDistance = abs(rightEye.x - nose.x)
        //        //
        //        //        // Symmetry metric could be the difference between these distances
        //        //        let symmetryScore = abs(leftEyeDistance - rightEyeDistance)
        //        //
        //        //        return symmetryScore
        //        //---------
        ////        let faceGeometry = faceAnchor.geometry
        ////        let vertexCount = faceGeometry.vertices.count
        ////
        ////        // Get the pointer to the vertices
        ////        let vertices = faceGeometry.vertices
        ////
        ////        // Assuming vertices are symmetrically distributed and indexed from the center outwards
        ////        let midIndex = vertexCount / 2
        ////        var sumSquaredDifferences: Double = 0
        ////        var count: Int = 0
        ////
        ////        for i in 0..<midIndex {
        ////            // Corresponding vertex index on the opposite side
        ////            let oppositeIndex = vertexCount - 1 - i
        ////
        ////            // Read vertices directly from the memory
        ////            let vertexLeft = vertices[i]
        ////            let vertexRight = vertices[oppositeIndex]
        ////
        ////            // Calculate squared distance in the x-axis (horizontal plane symmetry)
        ////            let diffX = vertexLeft.x + vertexRight.x  // Using '+' because vertices on the right will have negative x values
        ////            let squaredDistance = Double(diffX * diffX)
        ////
        ////            sumSquaredDifferences += squaredDistance
        ////            count += 1
        ////        }
        ////
        ////        // Calculate mean squared distance
        ////        let meanSquaredDistance = sumSquaredDifferences / Double(count)
        ////
        ////        // Return the eFACE score, could be the root of the mean squared distance for a more interpretable score
        ////        let symmetryScore = sqrt(meanSquaredDistance)
        ////        return symmetryScore
        //        //---------
        //        // Blend shapes dictionary
        //        let blendShapes = faceAnchor.blendShapes
        //
        //        // Retrieve specific blend shape coefficients
        //        guard let mouthSmileLeft = blendShapes[.mouthSmileLeft]?.doubleValue,
        //              let mouthSmileRight = blendShapes[.mouthSmileRight]?.doubleValue,
        //              let eyeBlinkLeft = blendShapes[.eyeBlinkLeft]?.doubleValue,
        //              let eyeBlinkRight = blendShapes[.eyeBlinkRight]?.doubleValue
        //        else {
        //            return 0.0
        //        }
        //
        //        // Calculate asymmetry scores for mouth and eyes
        //        let mouthAsymmetry = abs(mouthSmileLeft - mouthSmileRight)
        //        let eyeAsymmetry = abs(eyeBlinkLeft - eyeBlinkRight)
        //
        //        // Average the asymmetry scores (you can weight them differently if needed)
        //        let totalAsymmetry = (mouthAsymmetry + eyeAsymmetry) / 2.0
        //
        //        return totalAsymmetry
        //    }
        
        //    Height Diff: %.2f cm\nX Diff: %.2f cm\nMax Height Diff: %.2f cm\nMax X Diff: %.2f cm\nResting Height Diff: %.2f cm\nResting X Diff: %.2fcm", heightDifference,widthDifference, self.maxHeightDifference, self.maxWidthDifference, self.savedHeightDifference, self.savedWidthDifference)
        //    self.symmetryLabel.sizeToFit()
        //
    func updateSmileSymmetryLabel(
        left_x: Float, min_left_x: Float, max_left_x: Float,
        right_x: Float, min_right_x: Float, max_right_x: Float,
        left_y: Float, min_left_y: Float, max_left_y: Float,
        right_y: Float, min_right_y: Float, max_right_y: Float,
        area: Float, max_area: Float
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Define tab stops at desired positions
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .right, location: 150), // Adjust this value as needed
            NSTextTab(textAlignment: .right, location: 300), // Adjust this value as needed
            NSTextTab(textAlignment: .right, location: 450), // Adjust this value as needed
            NSTextTab(textAlignment: .right, location: 600)  // Adjust this value as needed
        ]
        paragraphStyle.defaultTabInterval = 150 // Adjust as needed
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // Create attributed string with tab stops
        let attributedString = NSMutableAttributedString(
            string: """
                             \t\tCurrent\tMin\tMax
            Left Lip Corner Width\t\(String(format: "%.2f", left_x)) mm\t\(String(format: "%.2f", min_left_x)) mm\t\(String(format: "%.2f", max_left_x)) mm
            Right Lip Corner Width\t\(String(format: "%.2f", right_x)) mm\t\(String(format: "%.2f", min_right_x)) mm\t\(String(format: "%.2f", max_right_x)) mm
            Left Lip Corner Elevation\t\(String(format: "%.2f", left_y)) mm\t\(String(format: "%.2f", min_left_y)) mm\t\(String(format: "%.2f", max_left_y)) mm
            Right Lip Corner Elevation\t\(String(format: "%.2f", right_y)) mm\t\(String(format: "%.2f", min_right_y)) mm\t\(String(format: "%.2f", max_right_y)) mm
            """,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white]
        )
        // Dental Show Area\t\t\(String(format: "%.2f", area)) cm² \t\t\(String(format: "%.2f", max_area)) cm²
        // Apply to label
        symmetryLabel.attributedText = attributedString
        symmetryLabel.sizeToFit()
        // Add semi-transparent black background
        symmetryLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
        
    func updateEyeSymmetryLabel(left_eye_height: Float, min_left_eye_height: Float, max_left_eye_height: Float, right_eye_height: Float, min_right_eye_height: Float, max_right_eye_height: Float) {
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Define tab stops at desired positions
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .right, location: 150), // Adjust this value as needed
            NSTextTab(textAlignment: .right, location: 300), // Adjust this value as needed
            NSTextTab(textAlignment: .right, location: 450) // Adjust this value as needed
        ]
        paragraphStyle.defaultTabInterval = 150 // Adjust as needed
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // Create attributed string with tab stops
        let attributedString = NSMutableAttributedString(
            string: """
                             \t\tCurrent\tMin\tMax
            Left Eye Height           \t\(String(format: "%.2f", left_eye_height)) mm\t\(String(format: "%.2f", min_left_eye_height)) mm\t\(String(format: "%.2f", max_left_eye_height)) mm
            Right Eye Height          \t\(String(format: "%.2f", right_eye_height)) cm\t\(String(format: "%.2f", min_right_eye_height)) mm\t\(String(format: "%.2f", max_right_eye_height)) mm
            """,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white]
        )
        
        // Apply to label
        symmetryLabel.attributedText = attributedString
        symmetryLabel.sizeToFit()
        
        // Add semi-transparent black background
        symmetryLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    func updateMouthLabel(
        left_x: Float, min_left_x: Float, max_left_x: Float,
        right_x: Float, min_right_x: Float, max_right_x: Float,
        left_y: Float, min_left_y: Float, max_left_y: Float,
        right_y: Float, min_right_y: Float, max_right_y: Float,
        area: Float, min_area: Float, max_area: Float,
        cwdistance: Float, min_cwdistance: Float, max_cwdistance: Float,
        left_mouth_vertical: Float, min_left_mouth_vertical: Float, max_left_mouth_vertical: Float,
        right_mouth_vertical: Float, min_right_mouth_vertical: Float, max_right_mouth_vertical: Float,
        left_commissure_hypotenuse: Float, min_left_commissure_hypotenuse: Float, max_left_commissure_hypotenuse: Float,
        right_commissure_hypotenuse: Float, min_right_commissure_hypotenuse: Float, max_right_commissure_hypotenuse: Float,
        fp_sym_com_low_lip: Float, min_fp_sym_com_low_lip: Float, max_fp_sym_com_low_lip: Float,
        np_sym_com_low_lip: Float, min_np_sym_com_low_lip: Float, max_np_sym_com_low_lip: Float,
        fp_sym_mouth_vertical: Float, min_fp_sym_mouth_vertical: Float, max_fp_sym_mouth_vertical: Float,
        np_sym_mouth_vertical: Float, min_np_sym_mouth_vertical: Float, max_np_sym_mouth_vertical: Float,
        right_top_lip_mes: Float, min_right_top_lip_mes: Float, max_right_top_lip_mes: Float,
        left_top_lip_mes: Float, min_left_top_lip_mes: Float, max_left_top_lip_mes: Float,
        right_bot_lip_mes: Float, min_right_bot_lip_mes: Float, max_right_bot_lip_mes: Float,
        left_bot_lip_mes: Float, min_left_bot_lip_mes: Float, max_left_bot_lip_mes: Float,
        left_mouth_area: Float, min_left_mouth_area: Float, max_left_mouth_area: Float,
        right_mouth_area: Float, min_right_mouth_area: Float, max_right_mouth_area: Float
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Define tab stops at desired positions
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: 170),
            NSTextTab(textAlignment: .right, location: 300),
            NSTextTab(textAlignment: .right, location: 380),
            NSTextTab(textAlignment: .right, location: 450)
        ]
        paragraphStyle.defaultTabInterval = 100
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributedString = NSMutableAttributedString(
            string: """
                Mouth Metrics:
                        \tCurrent\tMin\tMax
                L Hemi Dental Show\t\(String(format: "%.1f", left_mouth_area)) mm²\t\(String(format: "%.1f", min_left_mouth_area)) mm²\t\(String(format: "%.1f", max_left_mouth_area)) mm² \t
                R Hemi Dental Show\t\(String(format: "%.1f", right_mouth_area)) mm²\t\(String(format: "%.1f", min_right_mouth_area)) mm²\t\(String(format: "%.1f", max_right_mouth_area)) mm² \t
                L Comm. Pos. Lower Lip\t\(String(format: "%.1f", left_bot_lip_mes)) mm\t\(String(format: "%.1f",min_left_bot_lip_mes)) mm\t\(String(format: "%.1f", max_left_bot_lip_mes)) mm \t
                R Comm. Pos. Lower Lip\t\(String(format: "%.1f", right_bot_lip_mes)) mm\t\(String(format: "%.1f",min_right_bot_lip_mes)) mm\t\(String(format: "%.1f", max_right_bot_lip_mes)) mm \t
            """,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white]
        )
        //old values that were displayed:
        //  L Comm to Top Lip Mid.\t\(String(format: "%.1f", left_top_lip_mes)) mm\t\(String(format: "%.1f",min_left_top_lip_mes)) mm\t\(String(format: "%.1f", max_left_top_lip_mes)) mm \t
        //  R Comm to Top Lip Mid.\t\(String(format: "%.1f", right_top_lip_mes)) mm\t\(String(format: "%.1f",min_right_top_lip_mes)) mm\t\(String(format: "%.1f", max_right_top_lip_mes)) mm \t
        //  L Low Lip Height\t\(String(format: "%.1f", left_mouth_vertical)) mm\t\(String(format: "%.1f",min_left_mouth_vertical)) mm\t\(String(format: "%.1f", max_left_mouth_vertical)) mm \t
       //   R Low Lip Height\t\(String(format: "%.1f", right_mouth_vertical)) mm\t\(String(format: "%.1f",min_right_mouth_vertical)) mm\t\(String(format: "%.1f", max_right_mouth_vertical)) mm \t
        
        // Apply to mouthLabel
        mouthLabel.attributedText = attributedString
        mouthLabel.sizeToFit()
    }

    func updateEyeLabel(
        left_eye_height: Float,
        min_left_eye_height: Float,
        max_left_eye_height: Float,
        right_eye_height: Float,
        min_right_eye_height: Float,
        max_right_eye_height: Float,
        right_eye_area: Float,
        min_right_eye_area: Float,
        max_right_eye_area: Float,
        left_eye_area: Float,
        min_left_eye_area: Float,
        max_left_eye_area: Float,
        fp_sym_eye_height: Float,
        min_fp_sym_eye_height: Float,
        max_fp_sym_eye_height: Float,
        np_sym_eye_height: Float,
        min_np_sym_eye_height: Float,
        max_np_sym_eye_height: Float,
        right_eye_width: Float,
        min_right_eye_width: Float,
        max_right_eye_width: Float,
        left_eye_width: Float,
        min_left_eye_width: Float,
        max_left_eye_width: Float
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Define tab stops at desired positions
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: 130),
            NSTextTab(textAlignment: .right, location: 270),
            NSTextTab(textAlignment: .right, location: 350),
            NSTextTab(textAlignment: .right, location: 450)
        ]
        paragraphStyle.defaultTabInterval = 100
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // Create attributed string with tab stops
        let attributedString = NSMutableAttributedString(
            string: """
                Eye Metrics:
                                         \tCurrent\tMin\tMax
                L Pal. Fis. Height    \t\(String(format: "%.1f", left_eye_height)) mm\t\(String(format: "%.1f", min_left_eye_height)) mm\t\(String(format: "%.1f", max_left_eye_height)) mm \t
                R Pal. Fis. Height.    \t\(String(format: "%.1f", right_eye_height)) mm\t\(String(format: "%.1f", min_right_eye_height)) mm\t\(String(format: "%.1f", max_right_eye_height)) mm \t
                L Pal. Fis. Area\t\(String(format: "%.1f", left_eye_area)) mm²\t\(String(format: "%.1f", min_left_eye_area)) mm²\t\(String(format: "%.1f", max_left_eye_area)) mm² \t
                R Pal. Fis. Area\t\(String(format: "%.1f", right_eye_area)) mm²\t\(String(format: "%.1f", min_right_eye_area)) mm²\t\(String(format: "%.1f", max_right_eye_area)) mm² \t
            """,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white]
        )
        
        // Apply to eyeLabel
        eyeLabel.attributedText = attributedString
        eyeLabel.sizeToFit()
        
        // Ensure background color is set (if not already)
        eyeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    func updatedmLabel(
        pct_dm_left_eye_height: Float,
        pct_dm_right_eye_height: Float,
        pct_dm_left_eye_area: Float,
        pct_dm_right_eye_area: Float,
        pct_dm_left_ll_movement: Float,
        pct_dm_right_ll_movement: Float,
        pct_dm_left_mouth_area: Float,
        pct_dm_right_mouth_area: Float,
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Define tab stops at desired positions
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: 150),
            NSTextTab(textAlignment: .right, location: 300),
            NSTextTab(textAlignment: .right, location: 450),
            NSTextTab(textAlignment: .right, location: 550)
        ]
        paragraphStyle.defaultTabInterval = 100
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // Create attributed string with tab stops
        let attributedString = NSMutableAttributedString(
            string: """
            Dynamic Movement Scores:
                        \t\tLeft\tRight\t
                        Eye Height\t\t\(String(format: "%.0f", pct_dm_left_eye_height)) %\t\(String(format: "%.0f", pct_dm_right_eye_height)) % 
                        Eye Area\t\t\(String(format: "%.0f", pct_dm_left_eye_area)) %\t\(String(format: "%.0f", pct_dm_right_eye_area)) % 
                        Lower Lip Movement\t\(String(format: "%.0f", pct_dm_left_ll_movement)) %\t\(String(format: "%.0f", pct_dm_right_ll_movement)) % 
                        Mouth Area\t\t\(String(format: "%.0f", pct_dm_left_mouth_area)) %\t\(String(format: "%.0f", pct_dm_right_mouth_area)) % 
            """,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white]
        )
        
        // Apply to dmLabel
        dmLabel.attributedText = attributedString
        dmLabel.sizeToFit()
    }
        
    @IBAction func toggleRecording(_ sender: UIButton) {
        print("help me")
        if isRecording {
            stopRecording()
            sender.setTitle("Start Recording", for: .normal)
//            sender.backgroundColor = .green
        } else {
            startRecording()
            sender.setTitle("Stop Recording", for: .normal)
//            sender.backgroundColor = .red
        }
    }
//    @objc func toggleRecording(sender: UIButton) {
//            if isRecording {
//                stopRecording()
//                sender.setTitle("Start Recording", for: .normal)
//                sender.backgroundColor = .green
//            } else {
//                startRecording()
//                sender.setTitle("Stop Recording", for: .normal)
//                sender.backgroundColor = .red
//            }
//        }
        
        @objc func startRecording() {
            guard !isRecording else { return }
            screenRecorder.isMicrophoneEnabled = true
            screenRecorder.startRecording { [weak self] error in
                if let error = error {
                    print("Error starting screen recording: \(error.localizedDescription)")
                } else {
                    self?.isRecording = true
                    
                    DispatchQueue.main.async {
                                        self?.beginCSVLogging()
                                    }
                }
            }
        }
    
        
        @objc func stopRecording() {
            guard isRecording else { return }
            screenRecorder.stopRecording { [weak self] previewController, error in
                if let error = error {
                    print("Error stopping screen recording: \(error.localizedDescription)")
                } else {
                    self?.isRecording = false
                    self?.endCSVLogging()
                    if let previewController = previewController {
                        previewController.previewControllerDelegate = self
                        // Ensure popover presentation on iPad
                        if let popoverPresentationController = previewController.popoverPresentationController {
                            popoverPresentationController.sourceView = self?.view
                            popoverPresentationController.sourceRect = CGRect(x: self?.view.bounds.midX ?? 0, y: self?.view.bounds.midY ?? 0, width: 0, height: 0)
                            popoverPresentationController.permittedArrowDirections = []
                        }
                        self?.present(previewController, animated: true, completion: nil)
                    }
                }
            }
        }
    // Called once when recording starts: CSV Logging
      private func beginCSVLogging() {
          // Build a unique file URL in Documents
          let fm        = FileManager.default
          let docs      = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
          let isoFormatter = ISO8601DateFormatter()
          isoFormatter.timeZone = TimeZone.current      // ← use local time zone
          isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          let timestamp = isoFormatter.string(from: Date())
          // 3.1a Read the user’s inputs
          let last  = lastNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)  ?? "UnknownLast"
          let first = firstNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "UnknownFirst"
          let dob   = dobField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)       ?? "UnknownDOB"
          let mrn   = mrnField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)       ?? "UnknownMRN"
          
             // Build a safe filename:
             //    "LastName, FirstName, MRN, DOB, 2025-07-03T10:00:00-07:00.csv"
             let filename = "\(last), \(first), \(mrn), \(dob), \(timestamp).csv"
               .replacingOccurrences(of: "/", with: "-") // sanitize slashes in DOB
             let url = docs.appendingPathComponent(filename)
          
          // Write header row
          let header = """
                frame,\
                videotime,\
                TotalMouthArea,\
                CommissureToCommisureWidth,\
                LeftMouthVerticalMes,\
                RightMouthVerticalMes,\
                LeftTopLipMeasurement,\
                RightTopLipMeasurement,\
                LeftBottomLipMeasurement,\
                RightBottomLipMeasurement,\
                LeftEyeHeightMeasurement,\
                RightEyeHeightMeasurement,\
                LeftEyeArea,\
                RightEyeArea,\
                LeftEyeWidthMeasurement,\
                RightEyeWidthMeasurement,\
                LeftMouthArea,\
                RightMouthArea,\
                LeftDynEyeHeight, \
                RightDynEyeHeight, \
                LeftDynEyeArea, \
                RightDynEyeArea, \
                LeftDynLLMov, \
                RightDynLLMov, \
                LeftDynMouthArea, \
                RightDynMouthArea,\n
                """
          do {
              try header.write(to: url, atomically: true, encoding: .utf8)
          } catch {
              print("⚠️ Failed to write CSV header:", error)
              return
          }
          
          // Open a handle for appending (iOS-version safe)
          do {
              let handle: FileHandle
              if #available(iOS 13.0, *) {
                  // Modern API
                  handle = try FileHandle(forWritingTo: url)
              } else {
                  // Fallback for earlier iOS
                  guard let h = FileHandle(forWritingAtPath: url.path) else {
                      print("⚠️ Could not open CSV file at path \(url.path)")
                      return
                  }
                  handle = h
              }
              handle.seekToEndOfFile()
              csvFileURL    = url
              csvFileHandle = handle
          } catch {
              print("⚠️ Could not open CSV file handle:", error)
              return
          }
          
          let landmarkFilename = "landmarks-\(timestamp).csv"
            let landmarkURL = docs.appendingPathComponent(landmarkFilename)
            // create an empty file
            FileManager.default.createFile(atPath: landmarkURL.path, contents: nil, attributes: nil)
          
            // open handle (iOS-version safe)
            #if swift(>=5.1)
            if #available(iOS 13.0, *) {
                landmarkFileHandle = try? FileHandle(forWritingTo: landmarkURL)
            } else {
                landmarkFileHandle = FileHandle(forWritingAtPath: landmarkURL.path)
            }
            #else
            landmarkFileHandle = FileHandle(forWritingAtPath: landmarkURL.path)
            #endif
            landmarkFileHandle?.seekToEndOfFile()
            landmarkCsvFileURL = landmarkURL

            // Now reset counters & start your timer
            secondsElapsed = 0
            frameCounter   = 0     // for the landmark rows

          // reset our second counter here
          secondsElapsed = 0
          
          // Start a 1-second timer to log data points
          dataTimer = Timer.scheduledTimer(
            timeInterval: (1/15),
              target:      self,
              selector:    #selector(logDataPoint),
              userInfo:   nil,
              repeats:     true
          )
      }
      
    @objc private func logDataPoint() {
        guard let handle = csvFileHandle else { return }

        // 1) Frame counter
        secondsElapsed += 1
        
        let videotime = Double(secondsElapsed) / 15 //adjust to xFPS

        // 2) Gather your existing measurements
        let TotalMouthArea               = currentinsideMouthArea
        let CommissureToCommisureWidth   = currentCommissureWidth
        let LeftMouthVerticalMes         = currentLeftMouthVertical
        let RightMouthVerticalMes        = currentRightMouthVertical
        let LeftTopLipMeasurement        = currentLeftTopLipMes
        let RightTopLipMeasurement       = currentRightTopLipMes
        let LeftBottomLipMeasurement     = currentLeftBotLipMes
        let RightBottomLipMeasurement    = currentRightBotLipMes
        let LeftEyeHeightMeasurement     = currentleftEyeHeight
        let RightEyeHeightMeasurement    = currentrightEyeHeight
        let LeftEyeArea                  = currentinsideLeftEyeArea
        let RightEyeArea                 = currentinsideRightEyeArea
        let LeftEyeWidthMeasurement      = currentLeftEyeWidth
        let RightEyeWidthMeasurement     = currentRightEyeWidth
        let LeftMouthArea                = currentLeftMouthArea
        let RightMouthArea               = currentRightMouthArea

        // 3) Declare your delta-variables **before** the if/else
        var LeftDynEyeHeight: Float
        var RightDynEyeHeight: Float
        var LeftDynEyeArea: Float
        var RightDynEyeArea: Float
        var LeftDynLLMov: Float
        var RightDynLLMov: Float
        var LeftDynMouthArea: Float
        var RightDynMouthArea: Float

        // 4) Assign to them based on whether neutralExpression exists
        if let neutral = neutralExpression {
            LeftDynEyeHeight   = currentpctDMLeftEyeHeight
            RightDynEyeHeight  = currentpctDMRightEyeHeight
            LeftDynEyeArea     = currentpctDMLeftEyeArea
            RightDynEyeArea    = currentpctDMRightEyeArea
            LeftDynLLMov       = currentpctDMLeftLLMovement
            RightDynLLMov      = currentpctDMRightLLMovement
            LeftDynMouthArea   = currentpctDMLeftMouthArea
            RightDynMouthArea  = currentpctDMRightMouthArea
        } else {
            // no baseline → use NaN, used for when neutral expression is not set
            LeftDynEyeHeight   = Float.nan
            RightDynEyeHeight  = Float.nan
            LeftDynEyeArea     = Float.nan
            RightDynEyeArea    = Float.nan
            LeftDynLLMov       = Float.nan
            RightDynLLMov      = Float.nan
            LeftDynMouthArea   = Float.nan
            RightDynMouthArea  = Float.nan
        }

        // 5) Build and write the CSV line
        let line = """
        \(secondsElapsed),\
        \(videotime),\
        \(TotalMouthArea),\
        \(CommissureToCommisureWidth),\
        \(LeftMouthVerticalMes),\
        \(RightMouthVerticalMes),\
        \(LeftTopLipMeasurement),\
        \(RightTopLipMeasurement),\
        \(LeftBottomLipMeasurement),\
        \(RightBottomLipMeasurement),\
        \(LeftEyeHeightMeasurement),\
        \(RightEyeHeightMeasurement),\
        \(LeftEyeArea),\
        \(RightEyeArea),\
        \(LeftEyeWidthMeasurement),\
        \(RightEyeWidthMeasurement),\
        \(LeftMouthArea),\
        \(RightMouthArea),\
        \(LeftDynEyeHeight),\
        \(RightDynEyeHeight),\
        \(LeftDynEyeArea),\
        \(RightDynEyeArea),\
        \(LeftDynLLMov),\
        \(RightDynLLMov),\
        \(LeftDynMouthArea),\
        \(RightDynMouthArea)\n
        """

        if let data = line.data(using: .utf8) {
            handle.write(data)
        }
    }
        

      
      // Called once when recording ends
      private func endCSVLogging() {
          // Stop the timer
          dataTimer?.invalidate()
          dataTimer = nil
          
          // Close the file handle
          csvFileHandle?.closeFile()
          csvFileHandle = nil
          
          // close landmarks CSV
            landmarkFileHandle?.closeFile()
            landmarkFileHandle = nil
      }

    //export CSV button (two CSVs being exported)
    @IBAction func exportCSVPressed(_ sender: Any) {
        // Unwrap both CSV file URLs
        guard let metricsURL   = csvFileURL,
              let landmarksURL = landmarkCsvFileURL else {
            let alert = UIAlertController(
                title: "No Data",
                message: "No CSV files available to export.",
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Present the “Save to…” document picker with both files
        let picker = UIDocumentPickerViewController(
            forExporting: [metricsURL, landmarksURL],
            asCopy: true
        )
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        present(picker, animated: true)
    }
        
//        @objc func startRecordingTapped() {
//            startRecording()
//        }
//
//        @objc func stopRecordingTapped() {
//            stopRecording()
//        }
        
        
        
        func saveVideoToPhotos(url: URL) {
            guard videoWriterFinished else {
                print("Video writer has not finished yet")
                return
            }
            
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    print("Error: Photo library access not authorized")
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    if success {
                        print("Video saved to Photos library")
                    } else if let error = error {
                        print("Error saving video to Photos library: \(error)")
                    }
                }
            }
        }
        
    }
    
    //extension ViewController: AVCapturePhotoCaptureDelegate {
    //    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    //        guard let pixelBuffer = photo.pixelBuffer else {
    //            print("Error capturing photo: \(String(describing: error))")
    //            return
    //        }
    //
    //        let frameTime = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 600)
    //        videoWriterAdaptor?.append(pixelBuffer, withPresentationTime: frameTime)
    //    }
    //}
    extension ViewController: RPPreviewViewControllerDelegate {
        func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
            previewController.dismiss(animated: true, completion: nil)
        }
        
        func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
            if activityTypes.contains("com.apple.UIKit.activity.SaveToCameraRoll") {
                print("Video saved to Photos library")
            }
        }
    }

struct FaceRecord: Codable {
    let userId: String
    let timestamp: Date
    let minLeftEyeClosure: Float
    let minRightEyeClosure: Float
}

extension SCNVector3 {
  // Straight-line distance between two SCNVector3: used for lip measuerments (essentially 3D Py. Theorem.)
  func distance(to v: SCNVector3) -> Float {
    let dx = x - v.x
    let dy = y - v.y
    let dz = z - v.z
    return sqrt(dx*dx + dy*dy + dz*dz)
  }
}
