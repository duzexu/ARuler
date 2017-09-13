<p align="center">
  <img src="./Design/logo.png" width="100%"/>
</p>

# ARuler
Mesure distance using apple ARKit

[ENGLISH README](./README_EN.md)

## 预览
  <img src="./Design/preview_vertical.gif" width="320"/>
  
## 运行
cd到工程目录下，运行`pod install`

## 安装
因为ARKit使用限制，设备要求为6s以上，系统最低要求为iOS11，Xcode版本为9以上

测量时需保证光线充足

## 问题
<del>ARKit目前只能识别水平的平面，所以只能测量水平面的长度，不能测量垂直平面上的长度，不知道视频里的是怎么实现的，有知道的小伙伴可以一起交流一下</del>

去除了识别平面后才进行测量的逻辑，采用最近的特征点，可以测量垂直的物体啦

## 说明
项目中确定起始和结束点的位置主要有以下几种

##### 如果存在检测到的平面，返回平面上一点

```
let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
    if let result = planeHitTestResults.first {

        let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
        let planeAnchor = result.anchor

        // Return immediately - this is the best possible outcome.
        return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
    }
```

##### 根据当前ARFrame中的rawFeaturePoints计算点

* 获取以摄像头和屏幕上一点对应的透视消失点为轴，角度为10度，最小距离为10cm，最大距离为三米组成的截锥体内的特征点

```
let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 3.0)
```

* 假设抽样的特征点符合正态分布，过滤偏差值大于 3σ 的值

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

* 根据过滤的点用[最小二乘法](https://wenku.baidu.com/view/c9d0713710661ed9ac51f305.html)进行平面推定

```
let detectPlane = planeDetectWithFeatureCloud(featureCloud: warpFeatures)
```

* 根据截锥体轴上的点和向量及平面上的点和法向量计算交点

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

* 如果直线和平面平行或不符合平面推定条件，返回点平均值
* 如果截锥体内没有符合的点，查找出距离轴最近的点

## 参考
看到微博上[AR虚拟尺子视频](https://m.weibo.cn/1652421612/4122791333240092)，就想试着模仿着实现一下

部分代码来自[苹果ARKitDemo](https://developer.apple.com/sample-code/wwdc/2017/PlacingObjects.zip)

平面拟合代码参考这篇[博客](http://blog.csdn.net/zhouyelihua/article/details/46122977)

## 建议
有任何建议或问题请提issue

## 开源协议
ARuler开源在 GPL 协议下，详细请查看 [LICENSE](./LICENSE) 文件


