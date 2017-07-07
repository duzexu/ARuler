/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SceneKit node wrapper shows UI in the AR scene for placing virtual objects.
*/

import Foundation
import ARKit

class FocusSquare: SCNNode {
	
	/////////////////////////////////////////////////
	// Variables to configure the focus square
	
	// Original size of the focus square in m.
	private let focusSquareSize: Float = 0.17
	
	// Thickness of the focus square lines in m.
	private let focusSquareThickness: Float = 0.018
	
	// Scale factor for the focus square when it is closed, w.r.t. the original size.
	private let scaleForClosedSquare: Float = 0.97
	
	// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
	private let sideLengthForOpenSquareSegments: CGFloat = 0.2
	
	// Duration of the open/close animation
	private let animationDuration = 0.7
	
	// Color of the focus square
    private let focusSquareColor = #colorLiteral(red: 1, green: 0.8288275599, blue: 0, alpha: 1) // base yellow
	private let focusSquareColorLight = #colorLiteral(red: 1, green: 0.9312674403, blue: 0.4846551418, alpha: 1) // light yellow
    
    // For scale adapdation based on the camera distance, see the `scaleBasedOnDistance(camera:)` method.
	
	/////////////////////////////////////////////////
	
	var lastPositionOnPlane: SCNVector3?
	var lastPosition: SCNVector3?
	
	override init() {
		super.init()
		self.opacity = 0.0
		self.addChildNode(focusSquareNode())
		open()
		lastPositionOnPlane = nil
		lastPosition = nil
		recentFocusSquarePositions = []
		anchorsOfVisitedPlanes = []
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func update(for position: SCNVector3, planeAnchor: ARPlaneAnchor?, camera: ARCamera?) {
		lastPosition = position
		if let anchor = planeAnchor {
			close(flash: !anchorsOfVisitedPlanes.contains(anchor))
			lastPositionOnPlane = position
			anchorsOfVisitedPlanes.insert(anchor)
		} else {
			open()
		}
		updateTransform(for: position, camera: camera)
	}
	
	func hide() {
		if self.opacity == 1.0 {
			self.runAction(SCNAction.fadeOut(duration: 0.5))
		}
	}
	
	func unhide() {
		if self.opacity == 0.0 {
			self.runAction(SCNAction.fadeIn(duration: 0.5))
		}
	}
	
	// MARK: - Private
	
	private var isOpen = false
	// use average of recent positions to avoid jitter
	private var recentFocusSquarePositions = [SCNVector3]()
	
	private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
	
	private func updateTransform(for position: SCNVector3, camera: ARCamera?) {
		// add to list of recent positions
		recentFocusSquarePositions.append(position)
		
		// remove anything older than the last 8
		recentFocusSquarePositions.keepLast(8)
        
		// move to average of recent positions to avoid jitter
		if let average = recentFocusSquarePositions.average {
			self.position = average
			self.setUniformScale(scaleBasedOnDistance(camera: camera))
		}
		
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
			self.rotation = SCNVector4Make(0, 1, 0, angle)
		}
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
	
	private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
		if let camera = camera {
			let distanceFromCamera = (self.worldPosition - SCNVector3.positionFromTransform(camera.transform)).length()
			// This function reduces size changes of the focus square based on the distance by scaling it up if it far away,
			// and down if it is very close.
			// The values are adjusted such that scale will be 1 in 0.7 m distance (estimated distance when looking at a table),
			// and 1.2 in 1.5 m distance (estimated distance when looking at the floor).
			let newScale = distanceFromCamera < 0.7 ? (distanceFromCamera / 0.7) : (0.25 * distanceFromCamera + 0.825)
			
			return newScale
		}
		return 1.0
	}
	
	private func pulseAction() -> SCNAction {
		let pulseOutAction = SCNAction.fadeOpacity(to: 0.4, duration: 0.5)
		let pulseInAction = SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
		pulseOutAction.timingMode = .easeInEaseOut
		pulseInAction.timingMode = .easeInEaseOut
		
		return SCNAction.repeatForever(SCNAction.sequence([pulseOutAction, pulseInAction]))
	}
	
	private func stopPulsing(for node: SCNNode?) {
		node?.removeAction(forKey: "pulse")
		node?.opacity = 1.0
	}
	
	private var isAnimating: Bool = false
	
	private func open() {
		if isOpen || isAnimating {
			return
		}
		
		// Open animation
		SCNTransaction.begin()
		SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		SCNTransaction.animationDuration = animationDuration / 4
		entireSquare?.opacity = 1.0
		self.segments?[0].open(direction: .left, newLength: sideLengthForOpenSquareSegments)
		self.segments?[1].open(direction: .right, newLength: sideLengthForOpenSquareSegments)
		self.segments?[2].open(direction: .up, newLength: sideLengthForOpenSquareSegments)
		self.segments?[3].open(direction: .up, newLength: sideLengthForOpenSquareSegments)
		self.segments?[4].open(direction: .down, newLength: sideLengthForOpenSquareSegments)
		self.segments?[5].open(direction: .down, newLength: sideLengthForOpenSquareSegments)
		self.segments?[6].open(direction: .left, newLength: sideLengthForOpenSquareSegments)
		self.segments?[7].open(direction: .right, newLength: sideLengthForOpenSquareSegments)
		SCNTransaction.completionBlock = { self.entireSquare?.runAction(self.pulseAction(), forKey: "pulse") }
		SCNTransaction.commit()
		
		// Scale/bounce animation
		SCNTransaction.begin()
		SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		SCNTransaction.animationDuration = animationDuration / 4
		entireSquare?.setUniformScale(focusSquareSize)
		SCNTransaction.commit()
		
		isOpen = true
	}

	private func close(flash: Bool = false) {
		if !isOpen || isAnimating {
			return
		}
		
		isAnimating = true
		
		stopPulsing(for: entireSquare)
		
		// Close animation
		SCNTransaction.begin()
		SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		SCNTransaction.animationDuration = self.animationDuration / 2
		entireSquare?.opacity = 0.99
		SCNTransaction.completionBlock = {
			SCNTransaction.begin()
			SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
			SCNTransaction.animationDuration = self.animationDuration / 4
			self.segments?[0].close(direction: .right)
			self.segments?[1].close(direction: .left)
			self.segments?[2].close(direction: .down)
			self.segments?[3].close(direction: .down)
			self.segments?[4].close(direction: .up)
			self.segments?[5].close(direction: .up)
			self.segments?[6].close(direction: .right)
			self.segments?[7].close(direction: .left)
			SCNTransaction.completionBlock = { self.isAnimating = false }
			SCNTransaction.commit()
		}
		SCNTransaction.commit()
		
		// Scale/bounce animation
		entireSquare?.addAnimation(scaleAnimation(for: "transform.scale.x"), forKey: "transform.scale.x")
		entireSquare?.addAnimation(scaleAnimation(for: "transform.scale.y"), forKey: "transform.scale.y")
		entireSquare?.addAnimation(scaleAnimation(for: "transform.scale.z"), forKey: "transform.scale.z")
		
		// Flash
		if flash {
			let waitAction = SCNAction.wait(duration: animationDuration * 0.75)
			let fadeInAction = SCNAction.fadeOpacity(to: 0.25, duration: animationDuration * 0.125)
			let fadeOutAction = SCNAction.fadeOpacity(to: 0.0, duration: animationDuration * 0.125)
			fillPlane?.runAction(SCNAction.sequence([waitAction, fadeInAction, fadeOutAction]))
			
			let flashSquareAction = flashAnimation(duration: animationDuration * 0.25)
			segments?[0].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			segments?[1].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			segments?[2].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			segments?[3].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			segments?[4].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			segments?[5].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			segments?[6].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			segments?[7].runAction(SCNAction.sequence([waitAction, flashSquareAction]))
			
		}
		
		isOpen = false
	}
	
	private func flashAnimation(duration: TimeInterval) -> SCNAction {
		let action = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> Void in
			// animate color from HSB 48/100/100 to 48/30/100 and back
			let elapsedTimePercentage = elapsedTime / CGFloat(duration)
			let saturation = 2.8 * (elapsedTimePercentage - 0.5) * (elapsedTimePercentage - 0.5) + 0.3
			if let material = node.geometry?.firstMaterial {
				material.diffuse.contents = UIColor(hue: 0.1333, saturation: saturation, brightness: 1.0, alpha: 1.0)
			}
		}
		return action
	}
	
	private func scaleAnimation(for keyPath: String) -> CAKeyframeAnimation {
		let scaleAnimation = CAKeyframeAnimation(keyPath: keyPath)
		
		let easeOut = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		let easeInOut = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		let linear = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
		
		let fs = focusSquareSize
		let ts = focusSquareSize * scaleForClosedSquare
		let values = [fs, fs * 1.15, fs * 1.15, ts * 0.97, ts]
		let keyTimes: [NSNumber] = [0.00, 0.25, 0.50, 0.75, 1.00]
		let timingFunctions = [easeOut, linear, easeOut, easeInOut]
		
		scaleAnimation.values = values
		scaleAnimation.keyTimes = keyTimes
		scaleAnimation.timingFunctions = timingFunctions
		scaleAnimation.duration = animationDuration

		return scaleAnimation
	}
	
	private var segments: [FocusSquareSegment]? {
		guard let s1 = childNode(withName: "s1", recursively: true) as? FocusSquareSegment,
			let s2 = childNode(withName: "s2", recursively: true) as? FocusSquareSegment,
			let s3 = childNode(withName: "s3", recursively: true) as? FocusSquareSegment,
			let s4 = childNode(withName: "s4", recursively: true) as? FocusSquareSegment,
			let s5 = childNode(withName: "s5", recursively: true) as? FocusSquareSegment,
			let s6 = childNode(withName: "s6", recursively: true) as? FocusSquareSegment,
			let s7 = childNode(withName: "s7", recursively: true) as? FocusSquareSegment,
			let s8 = childNode(withName: "s8", recursively: true) as? FocusSquareSegment
			else {
				return nil
		}
		return [s1, s2, s3, s4, s5, s6, s7, s8]
	}
	
	private var fillPlane: SCNNode? {
		return childNode(withName: "fillPlane", recursively: true)
	}
	
	private var entireSquare: SCNNode? {
		return self.childNodes.first
	}
	
	private func focusSquareNode() -> SCNNode {
		/*
		The focus square consists of eight segments as follows, which can be individually animated.
		
		    s1  s2
		    _   _
		s3 |     | s4
		
		s5 |     | s6
		    -   -
		    s7  s8
		*/
		let sl: Float = 0.5  // segment length
		let st = focusSquareThickness
		let c: Float = focusSquareThickness / 2 // correction to align lines perfectly
		
		let s1 = FocusSquareSegment(name: "s1", width: sl, thickness: st, color: focusSquareColor)
		let s2 = FocusSquareSegment(name: "s2", width: sl, thickness: st, color: focusSquareColor)
		let s3 = FocusSquareSegment(name: "s3", width: sl, thickness: st, color: focusSquareColor, vertical: true)
		let s4 = FocusSquareSegment(name: "s4", width: sl, thickness: st, color: focusSquareColor, vertical: true)
		let s5 = FocusSquareSegment(name: "s5", width: sl, thickness: st, color: focusSquareColor, vertical: true)
		let s6 = FocusSquareSegment(name: "s6", width: sl, thickness: st, color: focusSquareColor, vertical: true)
		let s7 = FocusSquareSegment(name: "s7", width: sl, thickness: st, color: focusSquareColor)
		let s8 = FocusSquareSegment(name: "s8", width: sl, thickness: st, color: focusSquareColor)
		s1.position += SCNVector3Make(-(sl / 2 - c), -(sl - c), 0)
		s2.position += SCNVector3Make(sl / 2 - c, -(sl - c), 0)
		s3.position += SCNVector3Make(-sl, -sl / 2, 0)
		s4.position += SCNVector3Make(sl, -sl / 2, 0)
		s5.position += SCNVector3Make(-sl, sl / 2, 0)
		s6.position += SCNVector3Make(sl, sl / 2, 0)
		s7.position += SCNVector3Make(-(sl / 2 - c), sl - c, 0)
		s8.position += SCNVector3Make(sl / 2 - c, sl - c, 0)
		
		let fillPlane = SCNPlane(width: CGFloat(1.0 - st * 2 + c), height: CGFloat(1.0 - st * 2 + c))
		let material = SCNMaterial.material(withDiffuse: focusSquareColorLight, respondsToLighting: false)
		fillPlane.materials = [material]
		let fillPlaneNode = SCNNode(geometry: fillPlane)
		fillPlaneNode.name = "fillPlane"
		fillPlaneNode.opacity = 0.0
		
		let planeNode = SCNNode()
		planeNode.eulerAngles = SCNVector3Make(Float.pi / 2.0, 0, 0) // Horizontal
		planeNode.setUniformScale(focusSquareSize * scaleForClosedSquare)
		planeNode.addChildNode(s1)
		planeNode.addChildNode(s2)
		planeNode.addChildNode(s3)
		planeNode.addChildNode(s4)
		planeNode.addChildNode(s5)
		planeNode.addChildNode(s6)
		planeNode.addChildNode(s7)
		planeNode.addChildNode(s8)
		planeNode.addChildNode(fillPlaneNode)
		
		isOpen = false
		
		// Always render focus square on top
		planeNode.renderOnTop()
		
		return planeNode
	}
}

class FocusSquareSegment: SCNNode {
	
	enum Direction {
        case up
        case down
		case left
		case right
	}
	
	init(name: String, width: Float, thickness: Float, color: UIColor, vertical: Bool = false) {
		super.init()
		
		let material = SCNMaterial.material(withDiffuse: color, respondsToLighting: false)
		
		var plane: SCNPlane
		if vertical {
			plane = SCNPlane(width: CGFloat(thickness), height: CGFloat(width))
		} else {
			plane = SCNPlane(width: CGFloat(width), height: CGFloat(thickness))
		}
		plane.materials = [material]
		self.geometry = plane
		self.name = name
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func open(direction: Direction, newLength: CGFloat) {
		guard let p = self.geometry as? SCNPlane else {
			return
		}
		
		if direction == .left || direction == .right {
			p.width = newLength
		} else {
			p.height = newLength
		}
		
		switch direction {
		case .left:
			self.position.x -= Float(0.5 / 2 - p.width / 2)
		case .right:
			self.position.x += Float(0.5 / 2 - p.width / 2)
		case .up:
			self.position.y -= Float(0.5 / 2 - p.height / 2)
		case .down:
			self.position.y += Float(0.5 / 2 - p.height / 2)
		}
	}
	
	func close(direction: Direction) {
		guard let p = self.geometry as? SCNPlane else {
			return
		}
		
		var oldLength: CGFloat
		if direction == .left || direction == .right {
			oldLength = p.width
			p.width = 0.5
		} else {
			oldLength = p.height
			p.height = 0.5
		}
		
		switch direction {
		case .left:
			self.position.x -= Float(0.5 / 2 - oldLength / 2)
		case .right:
			self.position.x += Float(0.5 / 2 - oldLength / 2)
		case .up:
			self.position.y -= Float(0.5 / 2 - oldLength / 2)
		case .down:
			self.position.y += Float(0.5 / 2 - oldLength / 2)
		}
	}
}
