<p align="center">
  <img src="./Design/logo.png" width="100%"/>
</p>

# ARuler
Mesure distance using apple ARKit

[中文文档](./README.md)

## Preview
  <img src="./Design/preview_vertical.gif" width="320"/>
  
## Requirements
* Xcode 9
* iOS 11
* An iOS device with an A9 or better processor (iPhone 6s or superior, iPad Pro, iPad 2017)

You should mesure with enough light to detect feature point.

## Run
cd to the project folder and run `pod install`

## Instruction
This project use the methods below to determine start and end point. 

##### If detect a point on plane,return it

```
let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
    if let result = planeHitTestResults.first {

        let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
        let planeAnchor = result.anchor

        // Return immediately - this is the best possible outcome.
        return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
    }
```

##### Detect the point from current ARFrame's rawFeaturePoints

* Get feature points within the frustum combinate with axis that from camera location to screen perspective vanishing point,minimum distance which is 10cm and maximum distance with 3m.

```
let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 3.0)
```

* Fliter the points's discrepancy beyond 3σ.

```
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
        if (point-average).length()*100 > 3*σ {
            print(point,average)
        }
        return (point-average).length()*100 < 3*σ
    }
    return points
}
```

* Determain the plane base on the least-square method.

```
let detectPlane = planeDetectWithFeatureCloud(featureCloud: warpFeatures)
```

* Calculate the crossover point with the plane and the axis.

```
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
```

* If not meet the conditions,return average.
* If the frustum don't contain any point,return the point nearest to axis.

## Reference
Inspired by a [video](https://m.weibo.cn/1652421612/4122791333240092) from weibo

Some code adapted from[Apple ARKitDemo](https://developer.apple.com/sample-code/wwdc/2017/PlacingObjects.zip)

Plane fitting method refer to this [blog](http://blog.csdn.net/zhouyelihua/article/details/46122977)

## Communication
Any suggestion or bug please open an issue.

## License
ARuler is released under the GPL license.See [LICENSE](./LICENSE) for details.

