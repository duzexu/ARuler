//
//  PlaneDetector.m
//  ARuler
//
//  Created by duzexu on 2017/7/31.
//  Copyright © 2017年 duzexu. All rights reserved.
//

#import <opencv2/stitching.hpp>
#import <opencv2/opencv.hpp>
#import "PlaneDetector.h"

@implementation PlaneDetector

+ (SCNVector4)detectPlaneWithPoints:(NSArray *)points {
    CvMat*points_mat = cvCreateMat((int)points.count, 3, CV_32FC1);
    for (int i=0; i<points.count; i++) {
        NSValue *warp = points[i];
        SCNVector3 point = warp.SCNVector3Value;
        points_mat->data.fl[i*3+0] = point.x;
        points_mat->data.fl[i * 3 + 1] = point.y;
        points_mat->data.fl[i * 3 + 2] = point.z;
    }
    float plane[4] = { 0 };
    cvFitPlane(points_mat, plane);
    return SCNVector4Make(plane[0], plane[1], plane[2], plane[3]);
}

void cvFitPlane(const CvMat* points, float* plane){
    // Estimate geometric centroid.
    int nrows = points->rows;
    int ncols = points->cols;
    int type = points->type;
    CvMat* centroid = cvCreateMat(1, ncols, type);
    cvSet(centroid, cvScalar(0));
    for (int c = 0; c<ncols; c++){
        for (int r = 0; r < nrows; r++)
        {
            centroid->data.fl[c] += points->data.fl[ncols*r + c];
        }
        centroid->data.fl[c] /= nrows;
    }
    // Subtract geometric centroid from each point.
    CvMat* points2 = cvCreateMat(nrows, ncols, type);
    for (int r = 0; r<nrows; r++)
        for (int c = 0; c<ncols; c++)
            points2->data.fl[ncols*r + c] = points->data.fl[ncols*r + c] - centroid->data.fl[c];
    // Evaluate SVD of covariance matrix.
    CvMat* A = cvCreateMat(ncols, ncols, type);
    CvMat* W = cvCreateMat(ncols, ncols, type);
    CvMat* V = cvCreateMat(ncols, ncols, type);
    cvGEMM(points2, points, 1, NULL, 0, A, CV_GEMM_A_T);
    cvSVD(A, W, NULL, V, CV_SVD_V_T);
    // Assign plane coefficients by singular vector corresponding to smallest singular value.
    plane[ncols] = 0;
    for (int c = 0; c<ncols; c++){
        plane[c] = V->data.fl[ncols*(ncols - 1) + c];
        plane[ncols] += plane[c] * centroid->data.fl[c];
    }
    // Release allocated resources.
    cvReleaseMat(&centroid);
    cvReleaseMat(&points2);
    cvReleaseMat(&A);
    cvReleaseMat(&W);
    cvReleaseMat(&V);
}

@end
