/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility functions and type extensions used throughout the projects.
*/

import Foundation
import ARKit

// - MARK: UIImage extensions

extension UIImage {
	func inverted() -> UIImage? {
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        return UIImage(ciImage: ciImage.applyingFilter("CIColorInvert"))
    }
	
	static func composeButtonImage(from thumbImage: UIImage, alpha: CGFloat = 1.0) -> UIImage {
		let maskImage = #imageLiteral(resourceName: "buttonring")
		var thumbnailImage = thumbImage
		if let invertedImage = thumbImage.inverted() {
			thumbnailImage = invertedImage
		}
		
		// Compose a button image based on a white background and the inverted thumbnail image.
		UIGraphicsBeginImageContextWithOptions(maskImage.size, false, 0.0)
		let maskDrawRect = CGRect(origin: CGPoint.zero,
		                          size: maskImage.size)
		let thumbDrawRect = CGRect(origin: CGPoint((maskImage.size - thumbImage.size) / 2),
		                           size: thumbImage.size)
		maskImage.draw(in: maskDrawRect, blendMode: .normal, alpha: alpha)
		thumbnailImage.draw(in: thumbDrawRect, blendMode: .normal, alpha: alpha)
		let composedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return composedImage!
	}
}

// MARK: - Collection extensions
extension Array where Iterator.Element == CGFloat {
	var average: CGFloat? {
		guard !isEmpty else {
			return nil
		}
		
		var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
			var cur = cur
			cur += next
			return cur
		}
		let fcount = CGFloat(count)
		ret /= fcount
		return ret
	}
}

extension Array where Iterator.Element == SCNVector3 {
	var average: SCNVector3? {
		guard !isEmpty else {
			return nil
		}
		
		var ret = self.reduce(SCNVector3Zero) { (cur, next) -> SCNVector3 in
			var cur = cur
			cur.x += next.x
			cur.y += next.y
			cur.z += next.z
			return cur
		}
		let fcount = Float(count)
		ret.x /= fcount
		ret.y /= fcount
		ret.z /= fcount
		
		return ret
	}
}

extension RangeReplaceableCollection where IndexDistance == Int {
	mutating func keepLast(_ elementsToKeep: Int) {
		if count > elementsToKeep {
			self.removeFirst(count - elementsToKeep)
		}
	}
}

// MARK: - SCNNode extension

extension SCNNode {
	
	func setUniformScale(_ scale: Float) {
		self.scale = SCNVector3Make(scale, scale, scale)
	}
	
	func renderOnTop() {
		self.renderingOrder = 2
		if let geom = self.geometry {
			for material in geom.materials {
				material.readsFromDepthBuffer = false
			}
		}
		for child in self.childNodes {
			child.renderOnTop()
		}
	}
    
    func setPivot() {
        let minVec = self.boundingBox.min
        let maxVec = self.boundingBox.max
        let bound = SCNVector3Make( maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z);
        self.pivot = SCNMatrix4MakeTranslation(bound.x / 2, bound.y, bound.z / 2);
    }
}

// MARK: - SCNVector3 extensions

extension SCNVector3 {
	
	init(_ vec: vector_float3) {
		self.x = vec.x
		self.y = vec.y
		self.z = vec.z
	}
	
	func length() -> Float {
		return sqrtf(x * x + y * y + z * z)
	}
    
    func distanceFromPos(pos: SCNVector3) -> Float {
        let diff = SCNVector3(self.x - pos.x, self.y - pos.y, self.z - pos.z);
        return diff.length()
    }
	
	mutating func setLength(_ length: Float) {
		self.normalize()
		self *= length
	}
	
	mutating func setMaximumLength(_ maxLength: Float) {
		if self.length() <= maxLength {
			return
		} else {
			self.normalize()
			self *= maxLength
		}
	}
	
	mutating func normalize() {
		self = self.normalized()
	}
	
	func normalized() -> SCNVector3 {
		if self.length() == 0 {
			return self
		}
		
		return self / self.length()
	}
	
	static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
		return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
	}
	
	func friendlyString() -> String {
		return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)), \(String(format: "%.2f", z)))"
	}
	
	func dot(_ vec: SCNVector3) -> Float {
		return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
	}
	
	func cross(_ vec: SCNVector3) -> SCNVector3 {
		return SCNVector3(self.y * vec.z - self.z * vec.y, self.z * vec.x - self.x * vec.z, self.x * vec.y - self.y * vec.x)
	}
}

public let SCNVector3One: SCNVector3 = SCNVector3(1.0, 1.0, 1.0)

func SCNVector3Uniform(_ value: Float) -> SCNVector3 {
	return SCNVector3Make(value, value, value)
}

func SCNVector3Uniform(_ value: CGFloat) -> SCNVector3 {
	return SCNVector3Make(Float(value), Float(value), Float(value))
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
	left = left + right
}

func -= (left: inout SCNVector3, right: SCNVector3) {
	left = left - right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func /= (left: inout SCNVector3, right: Float) {
	left = left / right
}

func *= (left: inout SCNVector3, right: Float) {
	left = left * right
}

// MARK: - SCNMaterial extensions

extension SCNMaterial {
	
	static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
		let material = SCNMaterial()
		material.diffuse.contents = diffuse
		material.isDoubleSided = true
		if respondsToLighting {
			material.locksAmbientWithDiffuse = true
		} else {
			material.ambient.contents = UIColor.black
			material.lightingModel = .constant
			material.emission.contents = diffuse
		}
		return material
	}
}

// MARK: - CGPoint extensions

extension CGPoint {
	
	init(_ size: CGSize) {
		self.x = size.width
		self.y = size.height
	}
	
	init(_ vector: SCNVector3) {
		self.x = CGFloat(vector.x)
		self.y = CGFloat(vector.y)
	}
	
	func distanceTo(_ point: CGPoint) -> CGFloat {
		return (self - point).length()
	}
	
	func length() -> CGFloat {
		return sqrt(self.x * self.x + self.y * self.y)
	}
	
	func midpoint(_ point: CGPoint) -> CGPoint {
		return (self + point) / 2
	}
	
	func friendlyString() -> String {
		return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))"
	}
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
	left = left + right
}

func -= (left: inout CGPoint, right: CGPoint) {
	left = left - right
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x / right, y: left.y / right)
}

func * (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x * right, y: left.y * right)
}

func /= (left: inout CGPoint, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGPoint, right: CGFloat) {
	left = left * right
}

// MARK: - CGSize extensions

extension CGSize {
	
	init(_ point: CGPoint) {
		self.width = point.x
		self.height = point.y
	}
	
	func friendlyString() -> String {
		return "(\(String(format: "%.2f", width)), \(String(format: "%.2f", height)))"
	}
}

func + (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func += (left: inout CGSize, right: CGSize) {
	left = left + right
}

func -= (left: inout CGSize, right: CGSize) {
	left = left - right
}

func / (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width / right, height: left.height / right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width * right, height: left.height * right)
}

func /= (left: inout CGSize, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGSize, right: CGFloat) {
	left = left * right
}

// MARK: - CGRect extensions

extension CGRect {
	
	var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}

func rayIntersectionWithHorizontalPlane(rayOrigin: SCNVector3, direction: SCNVector3, planeY: Float) -> SCNVector3? {
	
	let direction = direction.normalized()
	
	// Special case handling: Check if the ray is horizontal as well.
	if direction.y == 0 {
		if rayOrigin.y == planeY {
			// The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
			// Therefore we simply return the ray origin.
			return rayOrigin
		} else {
			// The ray is parallel to the plane and never intersects.
			return nil
		}
	}
	
	// The distance from the ray's origin to the intersection point on the plane is:
	//   (pointOnPlane - rayOrigin) dot planeNormal
	//  --------------------------------------------
	//          direction dot planeNormal
	
	// Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
	let dist = (planeY - rayOrigin.y) / direction.y

	// Do not return intersections behind the ray's origin.
	if dist < 0 {
		return nil
	}
	
	// Return the intersection point.
	return rayOrigin + (direction * dist)
}

// MARK: - Float extensions
extension Float {
    enum LengthUnit: Int {
        case Meter = 0//米
        case CentiMeter //厘米
        case Foot //英尺
        case Inch //英寸
        case Ruler //尺
        
        var rate:(Float,String) {
            switch self {
            case .Meter:
                return (1.0, "m")
            case .CentiMeter:
                return (100.0, "cm")
            case .Foot:
                return (3.2808399, "ft")
            case .Inch:
                return (39.3700787, "in")
            case .Ruler:
                return (3.0, "尺")
            }
        }
    }
    
    static var unit: Array<LengthUnit> {
        return [.CentiMeter,.Meter,.Foot,.Inch,.Ruler]
    }
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "设备不支持"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "设备移动过快\n请缓慢移动"
            case .insufficientFeatures:
                return "特征点过少\n请保证摄像头不被遮挡和环境光线充足"
            case .initializing:
                return "AR正在初始化\n请左右移动设备获取更多特征点"
            }
        }
    }
}

extension ARError.Code {
    var presentationString: String {
        switch self {
        case .unsupportedConfiguration,.sensorUnavailable,.sensorFailed,.worldTrackingFailed:
            return "很遗憾，您当前的设备不支持"
        case .cameraUnauthorized:
            return "相机开启失败\n请到设置页面打开相机权限"
        }
    }
}

extension ARSCNView {
	
	struct HitTestRay {
		let origin: SCNVector3
		let direction: SCNVector3
	}
	
	func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
		
		guard let frame = self.session.currentFrame else {
			return nil
		}

		let cameraPos = SCNVector3.positionFromTransform(frame.camera.transform)

		// Note: z: 1.0 will unproject() the screen position to the far clipping plane.
		let positionVec = SCNVector3(x: Float(point.x), y: Float(point.y), z: 1.0)
		let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
		
		var rayDirection = screenPosOnFarClippingPlane - cameraPos
		rayDirection.normalize()
		
		return HitTestRay(origin: cameraPos, direction: rayDirection)
	}
	
	func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: SCNVector3) -> SCNVector3? {
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return nil
		}
		
		// Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
		if ray.direction.y > -0.03 {
			return nil
		}
		
		// Return the intersection of a ray from the camera through the screen position with a horizontal plane
		// at height (Y axis).
		return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
	}
	
    struct FeatureHitTestResult {
		let position: SCNVector3
		let distanceToRayOrigin: Float
		let featureHit: SCNVector3
		let featureDistanceToHitResult: Float
	}
	
	func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float,
	                         minDistance: Float = 0,
	                         maxDistance: Float = Float.greatestFiniteMagnitude,
	                         maxResults: Int = Int.max) -> [FeatureHitTestResult] {
		
		var results = [FeatureHitTestResult]()
		
		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return results
		}
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}
		
		let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
		let maxAngle = ((maxAngleInDeg / 180) * Float.pi)
		
		let points = features.__points
		
		for i in 0...features.__count {
			
			let feature = points.advanced(by: Int(i))
			let featurePos = SCNVector3(feature.pointee)
			
			let originToFeature = featurePos - ray.origin
			
			let crossProduct = originToFeature.cross(ray.direction)
			let featureDistanceFromResult = crossProduct.length()
			
			let hitTestResult = ray.origin + (ray.direction * ray.direction.dot(originToFeature))
			let hitTestResultDistance = (hitTestResult - ray.origin).length()
			
			if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
				// Skip this feature - it is too close or too far away.
				continue
			}
			
			let originToFeatureNormalized = originToFeature.normalized()
			let angleBetweenRayAndFeature = acos(ray.direction.dot(originToFeatureNormalized))
			
			if angleBetweenRayAndFeature > maxAngle {
				// Skip this feature - is is outside of the hit test cone.
				continue
			}

			// All tests passed: Add the hit against this feature to the results.
			results.append(FeatureHitTestResult(position: hitTestResult,
			                                    distanceToRayOrigin: hitTestResultDistance,
			                                    featureHit: featurePos,
			                                    featureDistanceToHitResult: featureDistanceFromResult))
		}
		
		// Sort the results by feature distance to the ray.
//        results = results.sorted(by: { (first, second) -> Bool in
//            return first.distanceToRayOrigin < second.distanceToRayOrigin
//        })
		
        if results.count < maxResults {
            return results
        }
        
		// Cap the list to maxResults.
		var cappedResults = [FeatureHitTestResult]()
		var i = 0
		while i < maxResults && i < results.count {
			cappedResults.append(results[i])
			i += 1
		}
		
		return cappedResults
	}
	
	func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
		
		var results = [FeatureHitTestResult]()
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}
		
		if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
			results.append(result)
		}
		return results
	}
	
	func hitTestFromOrigin(origin: SCNVector3, direction: SCNVector3) -> FeatureHitTestResult? {
		
		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return nil
		}
        
        let points = fliterWithFeatures(features.points)
        guard !points.isEmpty else {
            return nil
        }
        let point = points.average
        let originToFeature = point! - origin
        let hitTestResult = origin + (direction * direction.dot(originToFeature))
        let hitTestResultDistance = (hitTestResult - origin).length()
        return FeatureHitTestResult(position: hitTestResult,
                                    distanceToRayOrigin: hitTestResultDistance,
                                    featureHit: point!,
                                    featureDistanceToHitResult: hitTestResultDistance)
		
//        let points = features.__points
//
//        // Determine the point from the whole point cloud which is closest to the hit test ray.
//        var closestFeaturePoint = origin
//        var minDistance = Float.greatestFiniteMagnitude
//
//        for i in 0...features.__count {
//            let feature = points.advanced(by: Int(i))
//            let featurePos = SCNVector3(feature.pointee)
//
//            let originVector = origin - featurePos
//            let crossProduct = originVector.cross(direction)
//            let featureDistanceFromResult = crossProduct.length()
//
//            if featureDistanceFromResult < minDistance {
//                closestFeaturePoint = featurePos
//                minDistance = featureDistanceFromResult
//            }
//        }
//
//        // Compute the point along the ray that is closest to the selected feature.
//        let originToFeature = closestFeaturePoint - origin
//        let hitTestResult = origin + (direction * direction.dot(originToFeature))
//        let hitTestResultDistance = (hitTestResult - origin).length()
//
//        return FeatureHitTestResult(position: hitTestResult,
//                                    distanceToRayOrigin: hitTestResultDistance,
//                                    featureHit: closestFeaturePoint,
//                                    featureDistanceToHitResult: minDistance)
	}
    
    /// 去除偏差值大于 3σ 的值
    ///
    /// - Parameter features: 特征数据
    /// - Returns: 剔除后的数据
    func fliterWithFeatures(_ features:[FeatureHitTestResult]) -> [SCNVector3] {
        guard features.count >= 3 else {
            return features.map { (featureHitTestResult) -> SCNVector3 in
                return featureHitTestResult.position
            };
        }
        
        var points = features.map { (featureHitTestResult) -> SCNVector3 in
            return featureHitTestResult.position
        }
        // 平均值
        let average = points.average!
        // 方差
        let variance = sqrtf(points.reduce(0) { (sum, point) -> Float in
            var sum = sum
            sum += (point-average).length()*100*(point-average).length()*100
            return sum
            }/Float(points.count-1))
        // 标准差
        let standard = sqrtf(variance)
        let σ = variance/standard
        points = points.filter { (point) -> Bool in
            return (point-average).length()*100 < 3*σ
        }
        return points
    }
    
    func fliterWithFeatures(_ features:[vector_float3]) -> [SCNVector3] {
        guard features.count >= 3 else {
            return features.map { (feature) -> SCNVector3 in
                return SCNVector3.init(feature)
            };
        }
        
        var points = features.map { (feature) -> SCNVector3 in
            return SCNVector3.init(feature)
        }
        // 平均值
        let average = points.average!
        // 方差
        let variance = sqrtf(points.reduce(0) { (sum, point) -> Float in
            var sum = sum
            sum += (point-average).length()*100*(point-average).length()*100
            return sum
            }/Float(points.count-1))
        // 标准差
        let standard = sqrtf(variance)
        let σ = variance/standard
        points = points.filter { (point) -> Bool in
            return (point-average).length()*100 < 3*σ
        }
        return points
    }
}

// MARK: - Simple geometries

func createAxesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
	let quiverThickness = (quiverLength / 50.0) * quiverThickness
	let chamferRadius = quiverThickness / 2.0
	
	let xQuiverBox = SCNBox(width: quiverLength, height: quiverThickness, length: quiverThickness, chamferRadius: chamferRadius)
	xQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.red, respondsToLighting: false)]
	let xQuiverNode = SCNNode(geometry: xQuiverBox)
	xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)
	
	let yQuiverBox = SCNBox(width: quiverThickness, height: quiverLength, length: quiverThickness, chamferRadius: chamferRadius)
	yQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.green, respondsToLighting: false)]
	let yQuiverNode = SCNNode(geometry: yQuiverBox)
	yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)
	
	let zQuiverBox = SCNBox(width: quiverThickness, height: quiverThickness, length: quiverLength, chamferRadius: chamferRadius)
	zQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.blue, respondsToLighting: false)]
	let zQuiverNode = SCNNode(geometry: zQuiverBox)
	zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))
	
	let quiverNode = SCNNode()
	quiverNode.addChildNode(xQuiverNode)
	quiverNode.addChildNode(yQuiverNode)
	quiverNode.addChildNode(zQuiverNode)
	quiverNode.name = "Axes"
	return quiverNode
}

func createCrossNode(size: CGFloat = 0.01, color: UIColor = UIColor.green, horizontal: Bool = true, opacity: CGFloat = 1.0) -> SCNNode {
	
	// Create a size x size m plane and put a grid texture onto it.
	let planeDimension = size
	
	var fileName = ""
	switch color {
	case UIColor.blue:
		fileName = "crosshair_blue"
	case UIColor.yellow:
		fallthrough
	default:
		fileName = "crosshair_yellow"
	}
	
	let path = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "Models.scnassets")!
	let image = UIImage(contentsOfFile: path)
	
	let planeNode = SCNNode(geometry: createSquarePlane(size: planeDimension, contents: image))
	if let material = planeNode.geometry?.firstMaterial {
		material.ambient.contents = UIColor.black
		material.lightingModel = .constant
	}
	
	if horizontal {
		planeNode.eulerAngles = SCNVector3Make(Float.pi / 2.0, 0, Float.pi) // Horizontal.
	} else {
		planeNode.constraints = [SCNBillboardConstraint()] // Facing the screen.
	}
	
	let cross = SCNNode()
	cross.addChildNode(planeNode)
	cross.opacity = opacity
	return cross
}

func createSquarePlane(size: CGFloat, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size, height: size)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}

func createPlane(size: CGSize, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size.width, height: size.height)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}
