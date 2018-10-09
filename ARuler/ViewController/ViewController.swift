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
import PKHUD
import AwesomeIntroGuideView

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var indicator: UIImageView!
    @IBOutlet var placeButton: UIButton!
    @IBOutlet var distanceLabel_Center: UILabel!
    @IBOutlet var debugButton: UIButton!
    @IBOutlet var trashButton: UIButton!
    @IBOutlet var helpButton: UIButton!
    @IBOutlet var settingButton: UIButton!
    @IBOutlet var resetButton: UIButton!
    
    // MARK: - Guide
    let firstLaunchKey = "kUserDefault_AppIsFirstLaunch"
    var guideView: AwesomeIntroGuideView!
    
    var lengthUnit: Float.LengthUnit = .CentiMeter
    
    var line: LineNode?
    var cameraNode: SCNNode!
    var lines: [LineNode] = []
    
    // MARK: - Debug
    var planes = [ARPlaneAnchor: Plane]()
    var focusSquare: FocusSquare?
    var showDebugVisuals: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        setupFocusSquare()
        
        cameraNode = SCNNode()
        sceneView.scene.rootNode.addChildNode(cameraNode)
        
        #if DEBUG
            debugButton.isHidden = false
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        lengthUnit = Float.LengthUnit(rawValue: UserDefaults.standard.integer(forKey: SettingViewController.lengthUnitKey))!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let firstLaunch = UserDefaults.standard.bool(forKey: firstLaunchKey)
        if !firstLaunch {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            showGuideView()
        }else{
            restartSession()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}

// MARK: - Private Method
extension ViewController {
    func updateLineNode() -> Void {
        let startPos = self.worldPositionFromScreenPosition(self.indicator.center, objectPos: nil)
        if let p = startPos.position {
            let camera = self.sceneView.session.currentFrame?.camera
            let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
            if cameraPos.distanceFromPos(pos: p) < 0.05 && line == nil {
                updateView(state: false)
                return
            }
            updateView(state: true)
            let length = self.line?.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera) ?? 0
            distanceLabel_Center.text = String(format: "%.1f%@", arguments: [length*lengthUnit.rate.0,lengthUnit.rate.1])
        }
        
        guard self.sceneView.session.currentFrame != nil else {
            return
        }
        let camera = self.sceneView.session.currentFrame!.camera
        let cameraPos = SCNVector3.positionFromTransform(camera.transform)
        cameraNode.position = cameraPos
    }
    
    func restartSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        
        line?.removeFromParent()
        line = nil
        lines.forEach { (line) in
            line.removeFromParent()
        }
        lines.removeAll()
        
        updateView(state: false)
    }
    
    func updateView(state: Bool) {
        if state {
            placeButton.isEnabled = true
            indicator.tintColor = UIColor.fineColor
        }else{
            placeButton.isEnabled = false
            indicator.tintColor = UIColor.alertColor
        }
    }
    
    func buttonAnimated(btn: UIButton) -> Void {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseOut], animations: {
            btn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (value) in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseIn], animations: {
                btn.transform = CGAffineTransform.identity
            }) { (value) in
            }
        }
    }
    
    func showGuideView() -> Void {
        let marks = [["caption":"欢迎使用ARuler\n点击屏幕查看新手教程"],
                     ["caption":"左右移动手机来初始化测量\n点击屏幕查看下一步"],
                     ["rect":NSValue(cgRect:indicator.frame.insetBy(dx: -10, dy: -10)),"caption":"当指示器变绿时可以开始测量","shape":"circle"],
                     ["rect":NSValue(cgRect:indicator.frame.insetBy(dx: -10, dy: -10)),"caption":"将指示器的圆心对准要测量的起点","shape":"circle"],
                     ["rect":NSValue(cgRect:placeButton.frame.insetBy(dx: -10, dy: -10)),"caption":"点击这里设置测量起始点","shape":"circle"],
                     ["rect":NSValue(cgRect:distanceLabel_Center.frame.insetBy(dx: -10, dy: -10)),"caption":"移动设备\n实时查看测量结果","shape":"square"],
                     ["rect":NSValue(cgRect:placeButton.frame.insetBy(dx: -10, dy: -10)),"caption":"在点击这里设置测量终点","shape":"circle"],
                     ["rect":NSValue(cgRect:trashButton.frame.insetBy(dx: -10, dy: -10)),"caption":"点击这里删除上一个测量","shape":"circle"],
                     ["rect":NSValue(cgRect:resetButton.frame.insetBy(dx: -10, dy: -10)),"caption":"点击这里删除所有测量结果\n重新初始化测量","shape":"circle"],
                     ["rect":NSValue(cgRect:helpButton.frame.insetBy(dx: -10, dy: -10)),"caption":"点击这里查看帮助","shape":"circle"],
                     ["rect":NSValue(cgRect:settingButton.frame.insetBy(dx: -10, dy: -10)),"caption":"点击这里查看修改软件设置","shape":"circle"],
                     ["caption":"开始你的第一次测量吧"]]
        guideView = AwesomeIntroGuideView(frame: UIScreen.main.bounds, coachMarks:marks)
        guideView.loadType = .introLoad_Sync
        guideView.delegate = self
        self.navigationController?.view.addSubview(guideView)
        guideView.start()
    }
}

extension ViewController: AwesomeIntroGuideViewDelegate {
    func coachMarksViewDidCleanup(_ coachMarksView: AwesomeIntroGuideView) {
        restartSession()
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.updateLineNode()
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
        let tips = camera.trackingState.presentationString
        switch camera.trackingState {
        case .notAvailable:
            HUD.show(.label(tips))
        case .normal:
            HUD.hide()
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                HUD.flash(.label(tips),delay:0.5)
                break
            case .relocalizing, .insufficientFeatures,.initializing:
                HUD.show(.label(tips))
                break
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        let err = error as? ARError
        if err != nil {
            HUD.show(.label(err!.code.presentationString))
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}

// MARK: - Action
extension ViewController {
    @IBAction func placeAction(_ sender: UIButton) {
        buttonAnimated(btn: sender)
        sender.isSelected = !sender.isSelected;
        if line == nil {
            let startPos = worldPositionFromScreenPosition(indicator.center, objectPos: nil)
            if let p = startPos.position {
                line = LineNode(startPos: p, sceneV: sceneView, cameraNode: cameraNode)
            }
        }else{
            lines.append(line!)
            line = nil
        }
    }
    
    @IBAction func deleteAction(_ sender: UIButton) {
        buttonAnimated(btn: sender)
        if line != nil {
            line?.removeFromParent()
            line = nil
        }else{
            lines.last?.removeFromParent()
            if lines.last != nil {
                lines.removeLast()
            }
        }
    }
    
    @IBAction func restartAction(_ sender: UIButton) {
        buttonAnimated(btn: sender)
        restartSession()
    }
    
    @IBAction func debugAction(_ sender: UIButton) {
        showDebugVisuals = !showDebugVisuals
        if showDebugVisuals {
            planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints , SCNDebugOptions.showWorldOrigin]
        }else{
            planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        }
    }
}

// MARK: - Position Measure
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
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 50.0)
        
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

// MARK: - Debug
extension ViewController {
    // MARK: - Planes
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        let plane = Plane(anchor, showDebugVisuals)
        planes[anchor] = plane
        node.addChildNode(plane)
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
    
    // MARK: - Focus Square
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
