//
//  ViewController.swift
//  ARuler
//
//  Created by duzexu on 2017/6/30.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var indicator: UIImageView!
    @IBOutlet var placeButton: UIButton!
    @IBOutlet var distanceLabel_Left: UILabel!
    @IBOutlet var distanceLabel_Center: UILabel!
    @IBOutlet var distanceLabel_Right: UILabel!
    @IBOutlet var debugButton: UIButton!
    @IBOutlet var trashButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    var line: LineNode?
    var lines: [LineNode] = []
    
    var showDebugVisuals: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        setupFocusSquare()
        
//        #if DEBUG
//            debugButton.isHidden = false
//            trashButton.isHidden = true
//        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartPlaneDetection()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    @IBAction func placeAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseOut], animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (value) in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseIn], animations: {
                sender.transform = CGAffineTransform.identity
            }) { (value) in
            }
        }
        sender.isSelected = !sender.isSelected;
        if line == nil {
            let startPos = worldPositionFromScreenPosition(indicator.center, objectPos: nil)
            if let p = startPos.position {
                line = LineNode(startPos: p, sceneV: sceneView)
            }
        }else{
            lines.append(line!)
            line = nil
        }
    }
    
    @IBAction func restartAction(_ sender: UIButton) {
        line?.removeFromParent()
        line = nil
        for node in lines {
            node.removeFromParent()
        }
        restartPlaneDetection()
    }
    
    @IBAction func debugAction(_ sender: UIButton) {
        showDebugVisuals = !showDebugVisuals
        if showDebugVisuals {
            planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints , ARSCNDebugOptions.showWorldOrigin]
        }else{
            planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        }
    }
    
    @IBAction func deleteAction(_ sender: UIButton) {
        if line != nil {
            line?.removeFromParent()
            line = nil
        }else{
            lines.last?.removeFromParent()
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.updateLine()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.updatePlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.removePlane(anchor: planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            break
        case .limited:
            break
        case .normal:
            break
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func updateLine() -> Void {
        let startPos = self.worldPositionFromScreenPosition(self.indicator.center, objectPos: nil)
        if let p = startPos.position {
            let camera = self.sceneView.session.currentFrame?.camera
            let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
            if cameraPos.distanceFromPos(pos: p) < 0.05 {
                if line == nil {
                    placeButton.isEnabled = false
                    indicator.tintColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                }
                return;
            }
            hideMessage()
            placeButton.isEnabled = true
            indicator.tintColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
            let length = self.line?.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera) ?? 0
            updateDistanceLabel(distance: length)
        }
    }
    
    func updateDistanceLabel(distance:Float) -> Void {
        let chi = NSAttributedString(string: Float.LengthUnit.Ruler.rate.1, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 12)])
        let cm = NSAttributedString(string: Float.LengthUnit.CentiMeter.rate.1, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 15)])
        let inch = NSAttributedString(string: Float.LengthUnit.Inch.rate.1, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 12)])
        var dis = String(format: "%.1f", arguments: [distance*Float.LengthUnit.Ruler.rate.0])
        var result = NSMutableAttributedString(string: dis, attributes:[NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 18)])
        result.append(chi)
        distanceLabel_Left.attributedText = result
        dis = String(format: "%.1f", arguments: [distance*Float.LengthUnit.CentiMeter.rate.0])
        result = NSMutableAttributedString(string: dis, attributes:[NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 25)])
        result.append(cm)
        distanceLabel_Center.attributedText = result
        dis = String(format: "%.1f", arguments: [distance*Float.LengthUnit.Inch.rate.0])
        result = NSMutableAttributedString(string: dis, attributes:[NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 18)])
        result.append(inch)
        distanceLabel_Right.attributedText = result
    }
    
    // MARK: - Planes
    
    var planes = [ARPlaneAnchor: Plane]()
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
        let plane = Plane(anchor, showDebugVisuals)
        
        planes[anchor] = plane
        node.addChildNode(plane)
        
        indicator.tintColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
    
    func restartPlaneDetection() {
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        indicator.tintColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        showMessage(NSLocalizedString("MOVE", comment: "User Tips"), autoHide: false)
    }
    
    func showMessage(_ msg:String ,autoHide:Bool = true) {
        UIView.animate(withDuration: 0.5) {
            self.messageLabel.text = msg
            self.messageLabel.alpha = 1
            self.distanceLabel_Left.alpha = 0
            self.distanceLabel_Center.alpha = 0
            self.distanceLabel_Right.alpha = 0
        }
        if autoHide {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(hideMessage), with: nil, afterDelay: 0.3)
        }
    }
    
    @objc func hideMessage() {
        UIView.animate(withDuration: 0.5) {
            self.messageLabel.alpha = 0
            self.distanceLabel_Left.alpha = 1
            self.distanceLabel_Center.alpha = 1
            self.distanceLabel_Right.alpha = 1
        }
    }
    
    // MARK: - Focus Square
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)
    }
    
    func updateFocusSquare() {
        if showDebugVisuals {
            focusSquare?.unhide()
        }else{
            focusSquare?.hide()
        }
        
        let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(self.sceneView.bounds.mid, objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.sceneView.session.currentFrame?.camera)
        }
    }
}

extension ViewController {
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {

            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor

            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 3.0)
        
        // 过滤特征点
        let featureCloud = sceneView.fliterWithFeatures(highQualityfeatureHitTestResults)
        
        if featureCloud.count >= 3 {
            let warpFeatures = featureCloud.map({ (feature) -> NSValue in
                return NSValue(scnVector3: feature)
            })
            
            // 根据特征点进行平面推定
            let detectPlane = planeDetectWithFeatureCloud(featureCloud: warpFeatures)
            
            var planePoint = SCNVector3Zero
            if detectPlane.x != 0 {
                planePoint = SCNVector3(detectPlane.w/detectPlane.x,0,0)
            }else if detectPlane.y != 0 {
                planePoint = SCNVector3(0,detectPlane.w/detectPlane.y,0)
            }else {
                planePoint = SCNVector3(0,0,detectPlane.w/detectPlane.z)
            }
            
            let ray = sceneView.hitTestRayFromScreenPos(position)
            let crossPoint = planeLineIntersectPoint(planeVector: SCNVector3(detectPlane.x,detectPlane.y,detectPlane.z), planePoint: planePoint, lineVector: ray!.direction, linePoint: ray!.origin)
            if crossPoint != nil {
                return (crossPoint, nil, false)
            }else{
                return (featureCloud.average!, nil, false)
            }
        }
        
        if !featureCloud.isEmpty {
            featureHitTestPosition = featureCloud.average
            highQualityFeatureHitTestResult = true
        }else if !highQualityfeatureHitTestResults.isEmpty {
            featureHitTestPosition = highQualityfeatureHitTestResults.map { (featureHitTestResult) -> SCNVector3 in
                return featureHitTestResult.position
            }.average
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if infinitePlane || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    
    func planeDetectWithFeatureCloud(featureCloud: [NSValue]) -> SCNVector4 {
        let result = PlaneDetector.detectPlane(withPoints: featureCloud)
        return result
    }
    
    /// 根据直线上的点和向量及平面上的点和法向量计算交点
    ///
    /// - Parameters:
    ///   - planeVector: 平面法向量
    ///   - planePoint: 平面上一点
    ///   - lineVector: 直线向量
    ///   - linePoint: 直线上一点
    /// - Returns: 交点
    func planeLineIntersectPoint(planeVector: SCNVector3 , planePoint: SCNVector3, lineVector: SCNVector3, linePoint: SCNVector3) -> SCNVector3? {
        let vpt = planeVector.x*lineVector.x + planeVector.y*lineVector.y + planeVector.z*lineVector.z
        if vpt != 0 {
            let t = ((planePoint.x-linePoint.x)*planeVector.x + (planePoint.y-linePoint.y)*planeVector.y + (planePoint.z-linePoint.z)*planeVector.z)/vpt
            let cross = SCNVector3Make(linePoint.x + lineVector.x*t, linePoint.y + lineVector.y*t, linePoint.z + lineVector.z*t)
            if (cross-linePoint).length() < 5 {
               return cross
            }
        }
        return nil
    }
}
