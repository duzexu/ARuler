/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SceneKit node wrapper for plane geometry detected in AR.
*/

import Foundation
import ARKit

class Plane: SCNNode {
	
	var anchor: ARPlaneAnchor
	var occlusionNode: SCNNode?
	let occlusionPlaneVerticalOffset: Float = -0.01  // The occlusion plane should be placed 1 cm below the actual
													// plane to avoid z-fighting etc.
	
	var debugVisualization: PlaneDebugVisualization?
	
	var focusSquare: FocusSquare?
	
	init(_ anchor: ARPlaneAnchor, _ showDebugVisualization: Bool) {
		self.anchor = anchor
		
		super.init()
		
		self.showDebugVisualization(showDebugVisualization)
		
		if UserDefaults.standard.bool(for: .useOcclusionPlanes) {
			createOcclusionNode()
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func update(_ anchor: ARPlaneAnchor) {
		self.anchor = anchor
		debugVisualization?.update(anchor)
		if UserDefaults.standard.bool(for: .useOcclusionPlanes) {
			updateOcclusionNode()
		}
	}
	
	func showDebugVisualization(_ show: Bool) {
		if show {
			if debugVisualization == nil {
				DispatchQueue.global().async {
					self.debugVisualization = PlaneDebugVisualization(anchor: self.anchor)
					DispatchQueue.main.async {
						self.addChildNode(self.debugVisualization!)
					}
				}
			}
		} else {
			debugVisualization?.removeFromParentNode()
			debugVisualization = nil
		}
	}
	
	func updateOcclusionSetting() {
		if UserDefaults.standard.bool(for: .useOcclusionPlanes) {
			if occlusionNode == nil {
				createOcclusionNode()
			}
		} else {
			occlusionNode?.removeFromParentNode()
			occlusionNode = nil
		}
	}
	
	// MARK: Private
	
	private func createOcclusionNode() {
		// Make the occlusion geometry slightly smaller than the plane.
		let occlusionPlane = SCNPlane(width: CGFloat(anchor.extent.x - 0.05), height: CGFloat(anchor.extent.z - 0.05))
		let material = SCNMaterial()
		material.colorBufferWriteMask = []
		material.isDoubleSided = true
		occlusionPlane.materials = [material]
		
		occlusionNode = SCNNode()
		occlusionNode!.geometry = occlusionPlane
		occlusionNode!.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
		occlusionNode!.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
		
		self.addChildNode(occlusionNode!)
	}
	
	private func updateOcclusionNode() {
		guard let occlusionNode = occlusionNode, let occlusionPlane = occlusionNode.geometry as? SCNPlane else {
			return
		}
		occlusionPlane.width = CGFloat(anchor.extent.x - 0.05)
		occlusionPlane.height = CGFloat(anchor.extent.z - 0.05)
		
		occlusionNode.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
	}
}

