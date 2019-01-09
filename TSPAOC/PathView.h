//
//  PathView.h
//  TSPAOC
//
//  Created by YUFEI LANG on 12/20/18.
//  Copyright © 2018 The Casey Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSPSolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface PathView : UIView
@property (strong, nonatomic) NSArray<TSPSimpleCity *> *cities;
- (void)drawLinesAndPoints;
@end

NS_ASSUME_NONNULL_END
