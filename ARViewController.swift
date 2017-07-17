//
//  ViewController.swift
//  ARDemo
//
//  Created by Ashis Laha on 26/06/17.
//  Copyright © 2017 Ashis Laha. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

/* AR contains   1. Tracking ( World Tracking - ARAnchor )
                 2. Scene Understanding [a. Plane detection (ARPlaneAnchor) b. Hit Testing (placing object)  c. Light Estimation ]
                 3. Rendering ( SCNNode -> ARAnchor )
 */

@available(iOS 11.0, *)
class ARViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var sectionCoordinates : [[(Double,Double)]]?
    var carLocation : (Double,Double)?
    
    private var worldSectionsPositions : [[(Float,Float,Float)]]? // (0,0,0) is the center of Co-ordinates
    private var carCoordinate = SCNVector3Zero
    
    private var overlayView : UIView!
    private let worldTrackingFactor : Float = 50000
    private var nodeNumber : Int = 1
    
    //MARK:- View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self           // ARSCNViewDelegate
        sceneView.session.delegate = self   // ARSessionDelegate
        sceneView.showsStatistics = true
        mapper()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal // Plane Detection
        configuration.isLightEstimationEnabled = true // light estimation
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        sceneView.scene = getScene() //SceneNodeCreator.sceneSetUp()
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //MARK:- Dismiss
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK:- Scene Set up
    
    private func getScene() -> SCNScene {
        let scene = SCNScene()
        if let worldSectionsPositions = worldSectionsPositions {
            for eachSection in worldSectionsPositions {
                for eachCoordinate in eachSection {
                    let position = SCNVector3Make(eachCoordinate.0, eachCoordinate.1, eachCoordinate.2)
                    scene.rootNode.addChildNode(SceneNodeCreator.getGeometryNode(type: .Capsule, position:position, text: "\(nodeNumber)"))
                    nodeNumber = nodeNumber + 1
                }
            }
            
            // add car location
            if let carLocation = carLocation, let sectionCoordinates = sectionCoordinates , let firstSection = sectionCoordinates.first, firstSection.count > 0 {
                if let referencePoint = firstSection.first {
                    let carRealCoordinate = calculateRealCoordinate(mapCoordinate: carLocation, referencePoint: referencePoint)
                    let position = SCNVector3Make(carRealCoordinate.0, carRealCoordinate.1, carRealCoordinate.2)
                    let planeNode = SceneNodeCreator.createPlane(position: position)
                    planeNode.scale = SCNVector3Make(10, 10, 10)
                    scene.rootNode.addChildNode(planeNode)
                }
            }
        }
        return scene
    }
    
    //MARK:- Coordinate Mapper
    
    private func mapper() {
        if let sectionCoordinates = sectionCoordinates , let firstSection = sectionCoordinates.first , firstSection.count > 0 {
            let referencePoint = firstSection[0]
            mapToWorldCoordinateMapper(referencePoint: referencePoint, sectionCoordinates: sectionCoordinates)
        }
    }
    
    private func mapToWorldCoordinateMapper(referencePoint : (Double,Double) , sectionCoordinates : [[(Double,Double)]]) {
        worldSectionsPositions = []
        for eachSection in sectionCoordinates { // Each Edge
            var worldTrackSection = [(Float,Float,Float)]()
            for eachCoordinate in eachSection { // Each Point
                worldTrackSection.append(calculateRealCoordinate(mapCoordinate: eachCoordinate,referencePoint: referencePoint))
            }
            worldSectionsPositions?.append(worldTrackSection)
        }
    }
    
    private func calculateRealCoordinate(mapCoordinate: (Double, Double), referencePoint: (Double, Double)) -> (Float,Float,Float) {
        var realCoordinate : (x:Float, y: Float, z:Float) = (Float(),Float(),Float())
        let lngDelta = Float(mapCoordinate.1 - referencePoint.1) * worldTrackingFactor
        let latDelta = Float(mapCoordinate.0 - referencePoint.0) * worldTrackingFactor
        realCoordinate.x = lngDelta // based on Longtitude
        realCoordinate.y = 0.0 // should be calculated based on altitude
        realCoordinate.z = -1.0 * sqrt(latDelta * latDelta + lngDelta * lngDelta) // -ve Z axis
        return realCoordinate
    }
    
    //MARK:- Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, options: nil)
        if let firstResult = hitTestResults.first {
            handleTouchEvent(node: firstResult.node)
        }
    }
    private func handleTouchEvent(node : SCNNode ) {
        let basicAnimation = CABasicAnimation(keyPath: "opacity")
        basicAnimation.duration = 1.0
        basicAnimation.fromValue = 1.0
        basicAnimation.toValue = 0.0
        node.addAnimation(basicAnimation, forKey: "opacity")
        //node.geometry?.firstMaterial?.emission.contents = UIColor.green
    }
}

// MARK:- Tracking
 
extension ARViewController : ARSCNViewDelegate , ARSessionDelegate {
    
    //MARK:- ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    
    // Tracking - Called when a new plane was detected
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        addPlaneGeometry(for: anchors)
    }
    func addPlaneGeometry(for anchors : [ARAnchor]) {
    }
    
    // Called when a plane’s transform or extent is updated
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        updatePlaneGeometry(forAnchors: anchors)
    }
    func updatePlaneGeometry(forAnchors: [ARAnchor]) {
    }
    
    // When a plane is removed
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        removePlaneGeometry(for: anchors)
    }
    func removePlaneGeometry(for anchors : [ARAnchor]) {
    }
    
    //MARK:- ARSCNViewDelegate  (Rendering)
    
    // ADD
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("Plane Detected : New Node is added")
        //let node = SceneNodeCreator.getGeometryNode(type: .Cone, position: SCNVector3Make(0, 0, 0),text: "Hello")
        return SCNNode() //node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    // UPDATE
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    // REMOVE
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    }
    
    // While Tracking State changes ( Not-running -> Normal <-> Limited ) ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(let reason) :
            if reason == .excessiveMotion {
                showAlert(header: "Tracking State Failure", message: "Excessive Motion")
            } else if reason == .insufficientFeatures {
                showAlert(header: "Tracking State Failure", message: "Insufficient Features")
            }
        case .normal, .notAvailable : break
        }
    }
    
    //MARK:- Hit-Test (Scene Understanding)
    
    func addAnchorPoint(frame : ARFrame) {
        let point = CGPoint(x: 0.5, y: 0.5)
        let results = frame.hitTest(point, types: [.existingPlane, .estimatedHorizontalPlane])
        if let closetPoint = results.first {
            let anchor = ARAnchor(transform: closetPoint.worldTransform)
            sceneView.session.add(anchor: anchor)
        }
    }
}

//MARK:- ERROR Handling

extension ARViewController {
    func session(_ session: ARSession, didFailWithError error: Error) {
       showAlert(header: "Session Failure", message: "Session Interrupted.")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        addOverlay()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        removeOverlay()
    }
    
    private func addOverlay() {
        overlayView = UIView(frame: sceneView.bounds)
        overlayView.backgroundColor = UIColor.brown.withAlphaComponent(0.5)
        self.sceneView.addSubview(overlayView)
    }
    
    private func removeOverlay() {
        if let overlayView = overlayView {
            overlayView.removeFromSuperview()
        }
    }
    
    func showAlert(header : String? = "Header", message : String? = "Message")  {
        
        let alertController = UIAlertController(title: header, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
