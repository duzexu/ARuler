//
//  PlaneDetector.h
//  ARuler
//
//  Created by duzexu on 2017/7/31.
//  Copyright © 2017年 duzexu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface PlaneDetector : NSObject

+ (SCNVector4)detectPlaneWithPoints:(NSArray *)points;

@end
