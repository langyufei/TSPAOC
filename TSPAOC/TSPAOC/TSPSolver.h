//
//  TSPSolver.h
//  TSPAOC
//
//  Created by YUFEI LANG on 12/17/18.
//  Copyright © 2018 The Casey Group. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TSPCityProtocol <NSObject>
// weight between cities, could be distance or travel time etc.
- (double)quantityToCity:(id<TSPCityProtocol>)anotherCity;
@end

@interface TSPSolver : NSObject

/**
 Solver uses 'TSPCityProtocol' to build distance matrix. You can provide a matrix if you already have one
 so that 'quantityToCity:'(from TSPCityProtocol) won't be called
 */
@property (strong, nonatomic) NSArray<NSArray<NSNumber *> *> *distanceMatrix;

/**
 Perform optimization with a list of cities(confirm to 'TSPCityProtocol' protocol)
 The order of cities to be visited can not be controled. The maximum tried time is 2,000
 */
- (void)performAOCOptimizationWithCities:(NSArray<id<TSPCityProtocol>> *)cities
                                progress:(nullable BOOL(^)(NSInteger triedNum, double totalQuantity))progressHandler
                                complete:(void(^)(NSArray<NSNumber *> *idxInOrgAry, double totalQuantity))completeHandler;

/**
 Perform optimization with a list of cities(confirm to 'TSPCityProtocol' protocol)
 You can optionally provide start or end point. The maximum tried time is 2,000
 
 @param cities list of cities
 @param startPtIdx an index within boundary(cities) specify a start point, pass -1 if no requirement
 @param endPtIdx an index within boundary(cities) specify a end point, pass -1 if no requirement, pass same value as 'startPtIdx' for a round trip
 */
- (void)performAOCOptimizationWithCities:(NSArray<id<TSPCityProtocol>> *)cities
                           startPointIdx:(int)startPtIdx // pass -1 if not required
                             endPointIdx:(int)endPtIdx  // pass -1 if not required
                                progress:(nullable BOOL(^)(NSInteger triedNum, double totalQuantity))progressHandler
                                complete:(void(^)(NSArray<NSNumber *> *idxInOrgAry, double totalQuantity))completeHandler;

/**
 Perform optimization with a list of cities(confirm to 'TSPCityProtocol' protocol)
 You can optionally provide start or end point. The maximum tried time is 2,000
 
 @param cities list of cities
 @param startPtIdx an index within boundary(cities) specify a start point, pass -1 if no requirement
 @param endPtIdx an index within boundary(cities) specify a end point, pass -1 if no requirement, pass same value as 'startPtIdx' for a round trip
 @param maxSameResTryTime the max try time solver should continue before stop when best solution remains the same. pass 0 if no requirement
 */
- (void)performAOCOptimizationWithCities:(NSArray<id<TSPCityProtocol>> *)cities
                           startPointIdx:(int)startPtIdx // pass -1 if not required
                             endPointIdx:(int)endPtIdx  // pass -1 if not required
                    maxSameResultTryTime:(int)maxSameResTryTime
                                progress:(nullable BOOL(^)(NSInteger triedNum, double totalQuantity))progressHandler
                                complete:(void(^)(NSArray<NSNumber *> *idxInOrgAry, double totalQuantity))completeHandler;

@end

@interface TSPSimpleCity : NSObject<TSPCityProtocol>
- (instancetype)initWithPointValue:(NSValue *)pointVal;
@property (strong, nonatomic) NSValue *pointVal;
@end

NS_ASSUME_NONNULL_END
