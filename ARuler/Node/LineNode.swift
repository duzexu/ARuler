//
//  LineNode.swift
//  ARuler
//
//  Created by duzexu on 2017/7/3.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class LineNode: NSObject {
    var startNode: SCNNode!
    var endNode: SCNNode!
    var lineNode: SCNNode?
    var textNode: SCNNode!
    var textWrapNode: SCNNode!
    
    let sceneView: ARSCNView?
    
    init(startPos: SCNVector3, sceneV: ARSCNView, cameraNode:SCNNode) {
        sceneView = sceneV
        
        let dot = SCNSphere(radius:1)
        dot.firstMaterial?.diffuse.contents = UIColor.white
        dot.firstMaterial?.lightingModel = .constant
        dot.firstMaterial?.isDoubleSided = true
        
        startNode = SCNNode(geometry: dot)
        startNode.scale = SCNVector3(1/400.0, 1/400.0, 1/400.0)
        startNode.position = startPos
        sceneView?.scene.rootNode.addChildNode(startNode)
        
        endNode = SCNNode(geometry: dot)
        endNode.scale = SCNVector3(1/400.0, 1/400.0, 1/400.0)
        
        lineNode = nil
        
        let text = SCNText (string: "--", extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 10)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.alignmentMode  = kCAAlignmentCenter
        text.truncationMode = kCATruncationMiddle
        text.firstMaterial?.isDoubleSided = true
        textNode = SCNNode(geometry: text)
        textNode.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        textNode.eulerAngles = SCNVector3Make(0, .pi, 0)
        
        textWrapNode = SCNNode()
        textWrapNode.addChildNode(textNode)
        let constraint = SCNLookAtConstraint(target: cameraNode)
        constraint.isGimbalLockEnabled = true
        textWrapNode.constraints = [constraint]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeFromParent()
    }
    
    public func updatePosition(pos: SCNVector3, camera: ARCamera?) -> Float {
        let posEnd = updateTransform(for: pos, camera: camera)
        
        if endNode.parent == nil {
            sceneView?.scene.rootNode.addChildNode(endNode)
        }
        endNode.position = posEnd
        
        let posStart = startNode.position
        let middle = SCNVector3((posStart.x+posEnd.x)/2.0, (posStart.y+posEnd.y)/2.0+0.002, (posStart.z+posEnd.z)/2.0)
        
        let text = textNode.geometry as! SCNText
        let length = posEnd.distanceFromPos(pos: startNode.position)
        text.string = String(format: "%.2fcm", length*Float.LengthUnit.CentiMeter.rate.0)
        textNode.setPivot()
        textWrapNode.position = middle
        
        if textWrapNode.parent == nil {
            sceneView?.scene.rootNode.addChildNode(textWrapNode)
        }
        
        lineNode?.removeFromParentNode()
        lineNode = lineBetweenNodeA(nodeA: startNode, nodeB: endNode)
        sceneView?.scene.rootNode.addChildNode(lineNode!)
        
        return length
    }
    
    func removeFromParent() -> Void {
        startNode.removeFromParentNode()
        endNode.removeFromParentNode()
        lineNode?.removeFromParentNode()
        textWrapNode.removeFromParentNode()
    }
    
    // MARK: - Private
    
    private func lineBetweenNodeA(nodeA: SCNNode, nodeB: SCNNode) -> SCNNode {
        let positions: [Float32] = [nodeA.position.x, nodeA.position.y, nodeA.position.z, nodeB.position.x, nodeB.position.y, nodeB.position.z]
        let positionData = NSData(bytes: positions, length: MemoryLayout<Float32>.size*positions.count)
        let indices: [Int32] = [0, 1]
        let indexData = NSData(bytes: indices, length: MemoryLayout<Int32>.size * indices.count)

        let source = SCNGeometrySource(data: positionData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: indices.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float32>.size, dataOffset: 0, dataStride: MemoryLayout<Float32>.size * 3)
        let element = SCNGeometryElement(data: indexData as Data, primitiveType: SCNGeometryPrimitiveType.line, primitiveCount: indices.count, bytesPerIndex: MemoryLayout<Int32>.size)

        let line = SCNGeometry(sources: [source], elements: [element])
        return SCNNode(geometry: line)
    }
    
    // use average of recent positions to avoid jitter
    private var recentFocusSquarePositions = [SCNVector3]()
    
    private func updateTransform(for position: SCNVector3, camera: ARCamera?) -> SCNVector3 {
        // add to list of recent positions
        recentFocusSquarePositions.append(position)
        
        // remove anything older than the last 8
        recentFocusSquarePositions.keepLast(8)
        
        // Correct y rotation of camera square
        if let camera = camera {
            let tilt = abs(camera.eulerAngles.x)
            let threshold1: Float = Float.pi / 2 * 0.65
            let threshold2: Float = Float.pi / 2 * 0.75
            let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
            var angle: Float = 0
            
            switch tilt {
            case 0..<threshold1:
                angle = camera.eulerAngles.y
            case threshold1..<threshold2:
                let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
                let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
                angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange
            default:
                angle = yaw
            }
            //textNode.runAction(SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0))
        }
        
        // move to average of recent positions to avoid jitter
        if let average = recentFocusSquarePositions.average {
            return average
        }
        
        return SCNVector3Zero
    }
    
    private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {
        // Normalize angle in steps of 90 degrees such that the rotation to the other angle is minimal
        var normalized = angle
        while abs(normalized - ref) > Float.pi / 4 {
            if angle > ref {
                normalized -= Float.pi / 2
            } else {
                normalized += Float.pi / 2
            }
        }
        return normalized
    }
}
