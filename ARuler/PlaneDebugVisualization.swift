/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SceneKit node wrapper shows debug info for AR detected planes.
*/

import Foundation
import ARKit

class PlaneDebugVisualization: SCNNode {
	
	var planeAnchor: ARPlaneAnchor
	
	var planeGeometry: SCNPlane
	var planeNode: SCNNode
	
	init(anchor: ARPlaneAnchor) {
		
		self.planeAnchor = anchor
		
        let grid = UIImage(named: "Models.scnassets/plane_grid.png")
		self.planeGeometry = createPlane(size: CGSize(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z)),
		                                 contents: grid)
		self.planeNode = SCNNode(geometry: planeGeometry)
		self.planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
		
		super.init()
		
		let originVisualizationNode = createAxesNode(quiverLength: 0.1, quiverThickness: 1.0)
		self.addChildNode(originVisualizationNode)
		self.addChildNode(planeNode)
		
		self.position = SCNVector3(anchor.center.x, -0.002, anchor.center.z) // 2 mm below the origin of plane.
		
		adjustScale()
	}
	
	func update(_ anchor: ARPlaneAnchor) {
		self.planeAnchor = anchor
		
		self.planeGeometry.width = CGFloat(anchor.extent.x)
		self.planeGeometry.height = CGFloat(anchor.extent.z)
		
		self.position = SCNVector3Make(anchor.center.x, -0.002, anchor.center.z)
		
		adjustScale()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func adjustScale() {
		let scaledWidth: Float = Float(planeGeometry.width / 2.4)
		let scaledHeight: Float = Float(planeGeometry.height / 2.4)
		
		let offsetWidth: Float = -0.5 * (scaledWidth - 1)
		let offsetHeight: Float = -0.5 * (scaledHeight - 1)
		
		let material = self.planeGeometry.materials.first
		var transform = SCNMatrix4MakeScale(scaledWidth, scaledHeight, 1)
		transform = SCNMatrix4Translate(transform, offsetWidth, offsetHeight, 0)
		material?.diffuse.contentsTransform = transform
		
	}
}
