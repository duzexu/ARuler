<p align="center">
  <img src="./Design/logo.png" width="100%"/>
</p>

# ARuler
Mesure distance using apple ARKit

[ENGLISH README](./README_EN.md)

## 预览
  <img src="./Design/preview_vertical.gif" width="320"/>
  
## 运行
因为使用的opencv库有140m，超过了github的100m上传限制，所以使用了git-lfs，建议自己下载[opencv-3.2.0](http://opencv.org/releases.html)的包替换下

或者使用支持git-lfs的工具[Tower](https://www.git-tower.com/mac/)拉取代码

## 安装
因为ARKit使用限制，设备要求为6s以上，系统最低要求为iOS11，Xcode版本为9以上

测量时需保证光线充足

## 问题
<del>ARKit目前只能识别水平的平面，所以只能测量水平面的长度，不能测量垂直平面上的长度，不知道视频里的是怎么实现的，有知道的小伙伴可以一起交流一下</del>

去除了识别平面后才进行测量的逻辑，采用最近的特征点，可以测量垂直的物体啦

## 下一步
添加特征点的过滤，提高准确度

## 参考
看到微博上[AR虚拟尺子视频](https://m.weibo.cn/1652421612/4122791333240092)，就想试着模仿着实现一下

部分代码来自[苹果ARKitDemo](https://developer.apple.com/sample-code/wwdc/2017/PlacingObjects.zip)

## 建议
有任何建议或问题请提issue

## 开源协议
ARuler开源在 GPL 协议下，详细请查看 [LICENSE](./LICENSE) 文件


