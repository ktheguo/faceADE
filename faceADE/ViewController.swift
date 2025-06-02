//
//  ViewController.swift
//  meFACE
//
//  Created by Katherine Guo on 4/23/24.
//

import UIKit
import ARKit
import AVFoundation
import Photos
import ReplayKit


class ViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewOption = pickerData[row]
        // Optionally, update the label immediately after selection
        // updateSymmetryLabel()
    }
    
    
    @IBOutlet weak var sceneView: ARSCNView!
    var faceGeometry: ARSCNFaceGeometry?
    var symmetryLabel: UILabel!
    
    var userId: String = "katherine" // Replace this with actual user ID logic
//    var maxHeightDifference: Float = 0.0
//    var maxWidthDifference: Float = 0.0
    var maxDentalShow: Float = 0.0
    var minLeftMouthCorner_x: Float = .greatestFiniteMagnitude
    var maxLeftMouthCorner_x: Float = 0.0
    var minLeftMouthCorner_y: Float = .greatestFiniteMagnitude
    var maxLeftMouthCorner_y: Float = 0.0
    var minRightMouthCorner_x: Float = .greatestFiniteMagnitude
    var maxRightMouthCorner_x: Float = 0.0
    var minRightMouthCorner_y: Float = .greatestFiniteMagnitude
    var maxRightMouthCorner_y: Float = 0.0
    
//    var currHeightDifference: Float = 0.0
//    var currWidthDifference: Float = 0.0
//    var savedHeightDifference: Float = 0.0
//    var savedWidthDifference: Float = 0.0
    var minLeftEyeClosure: Float = .greatestFiniteMagnitude
    var minRightEyeClosure: Float = .greatestFiniteMagnitude
    var maxLeftEye: Float = 0.0
    var maxRightEye: Float = 0.0
//    var records: [FaceRecord] = []

    
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
    
    var pickerView: UIPickerView!
    var pickerData: [String] = ["Smile", "Eye Closure"] // Example options
    var viewOption: String = "Smile" // Default selected option
    
    
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
        
        // Initialize the ARSCNView
//        sceneView = ARSCNView(frame: self.view.frame)
//        self.view.addSubview(sceneView)
        
        // Set the sceneView's delegate
        sceneView.delegate = self
        
        // Optional: Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        
        //        // Create and add a scene to the view
        //        sceneView.scene = SCNScene()
        //
        //        if let device = sceneView.device {
        //            faceGeometry = ARSCNFaceGeometry(device: device)
        //        }
        // Create the ARSCNFaceGeometry
        if let device = sceneView.device, let geom = ARSCNFaceGeometry(device: device) {
            faceGeometry = geom
            if let material = faceGeometry?.firstMaterial {
                material.diffuse.contents = UIColor.clear
//                material.transparency = 1
                material.fillMode = .lines // Optional: for a wireframe look
            }
        }
//        sceneView.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    sceneView.topAnchor.constraint(equalTo: view.topAnchor),
//                    sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                    sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//                    sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
//                ])
        
        

        
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
        
        // Initialize and add pickerView
        pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        pickerView.dataSource = self
        self.view.addSubview(pickerView)
        
        // Constraints for pickerView
        NSLayoutConstraint.activate([
                pickerView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
                pickerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                pickerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        
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
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!) else { return }
        
        // Set material properties
        let material = faceGeometry.firstMaterial!
        material.transparency = 0.2
        material.diffuse.contents = UIColor.white // Set a visible color to test visibility
        material.fillMode = .lines // Wireframe mode
        
        // Adjust lighting to enhance visibility
        //        material.lightingModel = .constant // Simplifies the lighting on the face mesh
        //        material.isDoubleSided = true // Ensures the mesh is visible from inside and outside
        
        let faceNode = SCNNode(geometry: faceGeometry)
        node.addChildNode(faceNode)
        
        // Update the geometry immediately after creating the node
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

            DispatchQueue.global(qos: .userInitiated).async {
                self.updateFaceGeometry(faceAnchor: faceAnchor, faceGeometry: faceGeometry, node: node)
            }
        }

        func updateFaceGeometry(faceAnchor: ARFaceAnchor, faceGeometry: ARSCNFaceGeometry, node: SCNNode) {
            faceGeometry.update(from: faceAnchor.geometry)
            
            if let vertexSource = faceGeometry.sources.first(where: { $0.semantic == .vertex }) {
                let vertexData = vertexSource.data
                let vertexStride = vertexSource.dataStride
                let vertexOffset = vertexSource.dataOffset
                
                let mouthIndices = [638, 189] // , 188, 637]
                let eyeIndices = [1107, 1094, 1075, 1063]
                let insideMouthIndices =  [249, 393, 250, 251, 252, 253, 254, 255, 256, 24, 691, 690, 689, 688, 687, 686, 685, 823, 684, 834, 740, 683, 682, 710, 725, 709, 700, 25, 265, 274, 290, 275, 247, 248, 305, 404]
                
                if self.viewOption == "Smile" {
                    for i in mouthIndices {
                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .white)
                    }
//                    for i in insideMouthIndices {
//                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .white)
//                    }
                    for i in eyeIndices {
                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .gray)
                    }
                } else if self.viewOption == "Eye Closure" {
//                    for i in insideMouthIndices {
//                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .gray)
//                    }
                    for i in eyeIndices {
                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .white)
                    }
                    for i in mouthIndices {
                        self.placeDotOnVertex(at: i, with: vertexData, stride: vertexStride, offset: vertexOffset, on: node, color: .gray)
                    }
                }
                
                guard let leftMouthVertex = getVertexPosition(from: vertexData, at: 188, stride: vertexStride, offset: vertexOffset),
                      let rightMouthVertex = getVertexPosition(from: vertexData, at: 637, stride: vertexStride, offset: vertexOffset),
                      let leftEyeTopVertex = getVertexPosition(from: vertexData, at: 1094, stride: vertexStride, offset: vertexOffset),
                      let leftEyeBottomVertex = getVertexPosition(from: vertexData, at: 1107, stride: vertexStride, offset: vertexOffset),
                      let rightEyeTopVertex = getVertexPosition(from: vertexData, at: 1075, stride: vertexStride, offset: vertexOffset),
                      let rightEyeBottomVertex = getVertexPosition(from: vertexData, at: 1063, stride: vertexStride, offset: vertexOffset) else { return }
                
                var insideMouthNodes: [SCNVector3] = []
               for index in insideMouthIndices {
                   if let position = getVertexPosition(from: vertexData, at: index, stride: vertexStride, offset: vertexOffset) {
                       insideMouthNodes.append(position)
                   }
               }
                
                let leftMouthHeightCM = leftMouthVertex.y * 100 + 5
                let rightMouthHeightCM = rightMouthVertex.y * 100 + 5
                
                let leftMouthWidthCM = abs(leftMouthVertex.x * 100)
                let rightMouthWidthCM = abs(rightMouthVertex.x * 100)
                
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
                
                let leftEyeHeight = abs(leftEyeTopVertex.y - leftEyeBottomVertex.y) * 100
                let rightEyeHeight = abs(rightEyeTopVertex.y - rightEyeBottomVertex.y) * 100
                
                self.minLeftEyeClosure = min(self.minLeftEyeClosure, leftEyeHeight)
                self.minRightEyeClosure = min(self.minRightEyeClosure, rightEyeHeight)
                self.maxLeftEye = max(self.maxLeftEye, leftEyeHeight)
                self.maxRightEye = max(self.maxRightEye, rightEyeHeight)
                
                let insideMouthArea = calculatePolygonArea(vertices: insideMouthNodes) * 10000
                self.maxDentalShow = max(self.maxDentalShow, insideMouthArea)
                
                DispatchQueue.main.async {
                    switch self.viewOption {
                    case "Smile":
                        self.updateSmileSymmetryLabel(
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
                            max_area: self.maxDentalShow
                        )
                    case "Eye Closure":
                        self.updateEyeSymmetryLabel(
                            left_eye_height: leftEyeHeight,
                            min_left_eye_height: self.minLeftEyeClosure,
                            max_left_eye_height: self.maxLeftEye,
                            right_eye_height: rightEyeHeight,
                            min_right_eye_height: self.minRightEyeClosure,
                            max_right_eye_height: self.maxRightEye
                        )

                    default:
                        break
                    }
                }
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
        
    func placeDotOnVertex(at index: Int, with vertexData: Data, stride: Int, offset: Int, on node: SCNNode, color: UIColor) {
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
                let vertexPosition = SCNVector3(x: vertexPointer[0], y: vertexPointer[1], z: vertexPointer[2])
                
                // Add or update the dot at the vertex position
                addOrUpdateDot(at: vertexPosition, at: index, on: node, color: color)
            }
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
            dotGeometry.firstMaterial?.transparency = 0.7
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
        minLeftMouthCorner_x = .greatestFiniteMagnitude
        maxLeftMouthCorner_x = 0.0
        minLeftMouthCorner_y = .greatestFiniteMagnitude
        maxLeftMouthCorner_y = 0.0
        minRightMouthCorner_x = .greatestFiniteMagnitude
        maxRightMouthCorner_x = 0.0
        minRightMouthCorner_y = .greatestFiniteMagnitude
        maxRightMouthCorner_y = 0.0
        
    //    var currHeightDifference: Float = 0.0
    //    var currWidthDifference: Float = 0.0
    //    var savedHeightDifference: Float = 0.0
    //    var savedWidthDifference: Float = 0.0

        maxLeftEye = 0.0
        maxRightEye = 0.0
        minRightEyeClosure = .greatestFiniteMagnitude
        minLeftEyeClosure = .greatestFiniteMagnitude
        
        DispatchQueue.main.async {
            self.symmetryLabel.text = "Values have been reset"
            self.symmetryLabel.sizeToFit() // Adjust the label size based on content
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
            Left Lip Corner Width\t\(String(format: "%.1f", left_x)) cm\t\(String(format: "%.1f", min_left_x)) cm\t\(String(format: "%.1f", max_left_x)) cm
            Right Lip Corner Width\t\(String(format: "%.1f", right_x)) cm\t\(String(format: "%.1f", min_right_x)) cm\t\(String(format: "%.1f", max_right_x)) cm
            Left Lip Corner Height\t\(String(format: "%.1f", left_y)) cm\t\(String(format: "%.1f", min_left_y)) cm\t\(String(format: "%.1f", max_left_y)) cm
            Right Lip Corner Height\t\(String(format: "%.1f", right_y)) cm\t\(String(format: "%.1f", min_right_y)) cm\t\(String(format: "%.1f", max_right_y)) cm
            """,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white]
        )
        // Dental Show Area\t\t\(String(format: "%.1f", area)) cm² \t\t\(String(format: "%.1f", max_area)) cm²
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
            Left Eye Height           \t\(String(format: "%.2f", left_eye_height)) cm\t\(String(format: "%.2f", min_left_eye_height)) cm\t\(String(format: "%.2f", max_left_eye_height)) cm
            Right Eye Height          \t\(String(format: "%.2f", right_eye_height)) cm\t\(String(format: "%.2f", min_right_eye_height)) cm\t\(String(format: "%.2f", max_right_eye_height)) cm
            """,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white]
        )
        
        // Apply to label
        symmetryLabel.attributedText = attributedString
        symmetryLabel.sizeToFit()
        
        // Add semi-transparent black background
        symmetryLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
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


