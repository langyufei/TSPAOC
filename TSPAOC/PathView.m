//
//  PathView.m
//  TSPAOC
//
//  Created by YUFEI LANG on 12/20/18.
//  Copyright © 2018 The Casey Group. All rights reserved.
//

#import "PathView.h"

@implementation PathView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawLinesAndPoints];
}

- (void)drawLinesAndPoints {
    if (self.cities.count <= 0) {
        return;
    }
    
    [self drawPoints:self.cities];
    [self drawLines:self.cities];
}

- (void)drawLines:(NSArray<TSPSimpleCity *> *)cities {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [cities enumerateObjectsUsingBlock:^(TSPSimpleCity * _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint p = [value.pointVal CGPointValue];
        if (idx == 0) {
            CGContextMoveToPoint(context, p.x, p.y);
        }
        CGContextAddLineToPoint(context, p.x, p.y);
    }];
    [[UIColor orangeColor] setStroke];
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawPoints:(NSArray<TSPSimpleCity *> *)cities {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [cities enumerateObjectsUsingBlock:^(TSPSimpleCity * _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint p = [value.pointVal CGPointValue];
        CGContextAddArc(context, p.x, p.y, 2.0, 0, 2 * M_PI, 0);
        [(idx == 0) ? [UIColor greenColor] : [UIColor orangeColor] setFill];
        CGContextDrawPath(context, kCGPathFill);
    }];
}

@end
