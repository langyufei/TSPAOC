//
//  TSPSolver.m
//  TSPAOC
//
//  Created by YUFEI LANG on 12/17/18.
//  Copyright © 2018 The Casey Group. All rights reserved.
//

#import "TSPSolver.h"
#import <UIKit/UIKit.h>

@implementation TSPSolver

- (void)performAOCOptimizationWithCities:(NSArray<id<TSPCityProtocol>> *)cities
                                progress:(nullable BOOL(^)(NSInteger triedNum, double totalQuantity))progressHandler
                                complete:(void(^)(NSArray<NSNumber *> *idxInOrgAry, double totalQuantity))completeHandler {
    [self performAOCOptimizationWithCities:cities startPointIdx:-1 endPointIdx:-1 maxSameResultTryTime:0 progress:progressHandler complete:completeHandler];
}

- (void)performAOCOptimizationWithCities:(NSArray<id<TSPCityProtocol>> *)cities
                           startPointIdx:(int)startPtIdx // pass -1 if not required
                             endPointIdx:(int)endPtIdx  // pass -1 if not required
                                progress:(nullable BOOL(^)(NSInteger triedNum, double totalQuantity))progressHandler
                                complete:(void(^)(NSArray<NSNumber *> *idxInOrgAry, double totalQuantity))completeHandler {
    [self performAOCOptimizationWithCities:cities startPointIdx:startPtIdx endPointIdx:endPtIdx maxSameResultTryTime:0 progress:progressHandler complete:completeHandler];
}

- (void)performAOCOptimizationWithCities:(NSArray<id<TSPCityProtocol>> *)cities
                           startPointIdx:(int)startPtIdx // pass -1 if not required
                             endPointIdx:(int)endPtIdx  // pass -1 if not required
                    maxSameResultTryTime:(int)maxSameResTryTime
                                progress:(nullable BOOL(^)(NSInteger triedNum, double totalQuantity))progressHandler
                                complete:(void(^)(NSArray<NSNumber *> *idxInOrgAry, double totalQuantity))completeHandler {
    int numOfCity = (int)cities.count;
    
    // error check: start or end index should be within the 'cities' boundary
    if (startPtIdx >= 0 && startPtIdx >= numOfCity) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completeHandler(@[], -1.0);
        });
        return;
    }
    if (endPtIdx >= 0 && endPtIdx >= numOfCity) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completeHandler(@[], -1.0);
        });
        return;
    }
    // if caller provides only end point, consider using result of reverse
    // array of path that starts with the provided end point [yufei Dec 20'18]
    if (startPtIdx < 0 && endPtIdx >= 0) {
        [self performAOCOptimizationWithCities:cities
                                 startPointIdx:endPtIdx
                                   endPointIdx:startPtIdx
                          maxSameResultTryTime:maxSameResTryTime
                                      progress:progressHandler
                                      complete:^(NSArray<NSNumber *> * _Nonnull idxInOrgAry, double totalQuantity) {
                                          NSArray *reversedAry = [[idxInOrgAry reverseObjectEnumerator] allObjects];
                                          completeHandler(reversedAry, totalQuantity);
        }];
        return;
    }
    
    if (numOfCity < 1) { // nothing to optimize
        dispatch_async(dispatch_get_main_queue(), ^{
            completeHandler(@[], -1.0);
        });
    }
    else if (numOfCity == 1) { // no need to optimize
        dispatch_async(dispatch_get_main_queue(), ^{
            completeHandler(@[@(1)], 0.0);
        });
    }
    else if (numOfCity == 2) { // no need to optimize but need to consider start and/or end point
        NSMutableArray<NSNumber *> *res = [NSMutableArray array];
        // add the 1st index, use 'startPtIdx' if supplied
        NSNumber *firstIdx = (startPtIdx >= 0) ? @(startPtIdx) : @(0);
        [res addObject:firstIdx];
        // add the 2nd index, use the other index that's different than 1st
        NSNumber *secondIdx = ([firstIdx compare:@(0)] == NSOrderedSame) ? @(1) : @(0);
        [res addObject:secondIdx];
        // if 'endPointIdx' is supplied and it's not equal to 2nd index in result arrray(round trip) then
        // add the 3rd index which is the same as 1st element in result array(or the 'endPointIdx' itself)
        if (endPtIdx >= 0 && [secondIdx compare:@(endPtIdx)] != NSOrderedSame) {
            [res addObject:@(endPtIdx)];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __block double totalDistance = 0.0;
            [res enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx < res.count - 1) {
                    id<TSPCityProtocol> city1 = [cities objectAtIndex:obj.integerValue];
                    id<TSPCityProtocol> city2 = [cities objectAtIndex:(obj.integerValue + 1)];
                    totalDistance += [city1 quantityToCity:city2];
                }
            }];
            completeHandler(res, totalDistance);
        });
    }
    else
    {
        NSMutableArray<NSMutableArray<NSNumber *> *> *distanceMatrix = [self buildDistanceMatrix:cities];
        __block NSMutableArray *bestPath = [NSMutableArray arrayWithCapacity:numOfCity]; // 记录最近的那条路线
        for (NSInteger idx = 0; idx < numOfCity; idx++) {
            [bestPath addObject:@(-1)];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int numOfAnt = (int)numOfCity / 2;      // 蚂蚁的数量
            int initPheVal = 1;                     // 初始化的信息素的量
            double pheTbl[numOfCity][numOfCity];    // 每条路径上的信息素的量
            double addTbl[numOfCity][numOfCity];    // 代表相应路径上的信息素的增量
            double itaTbl[numOfCity][numOfCity];    // 'η'启发函数,yita[i][j]=1/graph[i][j]
            int visited[numOfAnt][numOfCity];       // 标记已经走过的城市
            int antPath[numOfAnt][numOfCity];       // map[K][N]记录第K只蚂蚁走的路线
            double solutions[numOfAnt];             // 记录某次循环中每只蚂蚁走的路线的距离
            double bestSolution = MAXFLOAT;
            double preBestSolution = MAXFLOAT;
            int maxLoopCnt = 2000;                  // 代表迭代次数,理论上迭代次数越多所求的解更接近最优解,最具有说服力
            BOOL isRound = (startPtIdx >=0 && endPtIdx >= 0 && startPtIdx == endPtIdx) ? YES : NO; // 查看是否是 round trip,也就是说起始点是同一个点
            __block BOOL shouldContinue = YES;      // caller can also control to termiate the loop
            double alpha = 2;                       // 信息素系数 'α'
            double vita = 2;                        // 启发因子系数 'β'
            double ro = 0.7;                        // 蒸发系数 'ρ'
            double Q = 5000;                        // 信息量
            
            int loopCnt = 0;
            int i, j, k, s;
            double drand, pheSum;
            
            for (i = 0; i < numOfCity; i++) {
                for (j = 0; j < numOfCity; j++) {
                    pheTbl[i][j] = initPheVal; // 信息素初始化
                    if(i != j) { // 期望值,与距离成反比
                        itaTbl[i][j] = 100.0 / [distanceMatrix[i][j] doubleValue];
                    }
                }
            }
            
            memset(antPath, -1, sizeof(antPath));   // 把蚂蚁走的路线置空(map进行清零操作)
            memset(visited, 0, sizeof(visited));    // 0表示未访问,1表示已访问
            int maxResTryCnt = maxSameResTryTime > 0 ? maxSameResTryTime : INT_MAX;
            int sameResTryCnt = 0;
            while(loopCnt++ <= maxLoopCnt && shouldContinue && sameResTryCnt <= maxResTryCnt) {
                for(k = 0; k < numOfAnt; k++) {
                    int antStartIdx = (k+loopCnt) % numOfCity; // 默认如若对起点无要求,给每只蚂蚁分配一个起点,并且保证起点在N个城市里
                    int antEndIdx = -1;             // 默认如若对终点无要求则用-1代表
                    
                    if (startPtIdx >= 0) {
                        antStartIdx = startPtIdx;
                    }
                    
                    if (endPtIdx >= 0) {
                        antEndIdx = endPtIdx;
                    }
                    
                    // 设置起点并且标记已访问
                    antPath[k][0] = antStartIdx;
                    visited[k][antStartIdx] = 1;
                    
                    // 设置终点并且标记已访问
                    if (endPtIdx >= 0) {
                        antPath[k][numOfCity-1] = endPtIdx;
                        // 将终点标记为已经访问
                        visited[k][antEndIdx] = 1;
                    }
                }
                s = 1;
                BOOL hasEndPt = (endPtIdx >= 0) && (endPtIdx != startPtIdx);
                int upperLimit = hasEndPt ? numOfCity - 1 : numOfCity;
                int maxProbabilityCnt = upperLimit - 1;
                while(s < upperLimit) {
                    for(k = 0; k < numOfAnt; k++) {
                        // could be -1 or the end point/index passed to this method
                        int antEndIdx = antPath[k][numOfCity - 1];
                        
                        pheSum = 0;
                        for(j = 0; j < numOfCity; j++) {
                            if(visited[k][j] == 0 && ((hasEndPt && (j == antEndIdx)) ? NO : YES)) {
                                pheSum += pow(pheTbl[antPath[k][s-1]][j], alpha) * pow(itaTbl[antPath[k][s-1]][j], vita);
                            }
                        }
                        
                        // calculate the probabilities using roulette wheel method [yufei Dec 19'18@18:37]
                        double probabilities[maxProbabilityCnt];
                        memset(probabilities, 0, sizeof(probabilities));
                        // list of indexes match 'probabilities' [yufei Dec 20'18@10:30]
                        NSMutableArray<NSNumber *> *chooices = [NSMutableArray arrayWithCapacity:maxProbabilityCnt];
                        
                        for(j = 0; j < numOfCity; j++) {
                            // dont calculate probability for visited cities and the start/end city, if required
                            // note that the start city is alwasy initialized [yufei Dec 20'18@10:35]
                            if(visited[k][j] == 0 && ((hasEndPt && (j == antEndIdx)) ? NO : YES)) {
                                double probability = pow(pheTbl[antPath[k][s-1]][j], alpha) * pow(itaTbl[antPath[k][s-1]][j], vita) / pheSum;
                                [chooices addObject:@(j)];
                                for (int cnt = 0; cnt < chooices.count; cnt++) {
                                    probabilities[cnt] = probabilities[cnt] + probability;
                                }
                            }
                        }
                        
                        // 生成一个小于1的随机数
                        drand = (double)(arc4random() % 100) / 100.0;
                        for (int idx = 0; idx < chooices.count; idx++) {
                            double lhProbability = (idx == 0) ? 1.0 : probabilities[idx];
                            // define the right most boundary to -1, which is definitely less than 'drand'
                            double rhProbability = (idx == (chooices.count - 1)) ? -1.0 : probabilities[idx + 1];
                            if (lhProbability >= drand && drand > rhProbability) {
                                int cityIdx = [chooices objectAtIndex:idx].intValue;
                                // 将走过的城市标记起来
                                visited[k][cityIdx] = 1;
                                // 记录城市的顺序
                                antPath[k][s] = cityIdx;
                                break;
                            }
                        }
                    }
                    s++;
                }
                memset(addTbl, 0, sizeof(addTbl));
                // 计算本次中的最短路径
                for(k = 0; k < numOfAnt; k++) {
                    // 蚂蚁k所走的路线的总长度
                    solutions[k] = [self totalPathDistanceWithMatrix:distanceMatrix path:antPath[k] isRoundTrip:isRound];
                    if(solutions[k] < bestSolution) {
                        preBestSolution = bestSolution;
                        bestSolution = solutions[k];
                        for(i = 0; i < numOfCity; ++i) {
                            [bestPath replaceObjectAtIndex:i withObject:@(antPath[k][i])];
                        }
                    }
                }
                for(k = 0; k < numOfAnt; k++) {
                    for(j = 0; j < numOfCity-1; j++) {
                        addTbl[antPath[k][j]][antPath[k][j+1]] += Q / solutions[k];
                    }
                    addTbl[numOfCity-1][0] += Q / solutions[k];
                }
                for(i = 0; i < numOfCity; i++) {
                    for(j = 0; j < numOfCity; j++) {
                        pheTbl[i][j] = pheTbl[i][j] * ro + addTbl[i][j];
                        if(pheTbl[i][j] < 0.0001) pheTbl[i][j] = 0.0001;// 设立一个下界
                        else if(pheTbl[i][j] > 20) pheTbl[i][j] = 20;   // 设立一个上界,防止启发因子的作用被淹没
                    }
                }
                memset(visited, 0, sizeof(visited));
                memset(antPath, -1, sizeof(antPath));
                
                if (progressHandler != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        shouldContinue = progressHandler(loopCnt, bestSolution);
                    });
                }
                
                sameResTryCnt += (preBestSolution == bestSolution ? 1 : 0);
                preBestSolution = bestSolution;
                NSLog(@"%d -> %f(pre: %f)", loopCnt, bestSolution, preBestSolution);
            }
            
            // call complete handler on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                completeHandler(bestPath, bestSolution);
            });
        });
    }
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)buildDistanceMatrix:(NSArray<id<TSPCityProtocol>> *)cities {
    // build a distance matrix using given cities [yufei Dec 18'18@11:39]
    NSMutableArray<NSMutableArray<NSNumber *> *> *distanceMatrix = [NSMutableArray array];
    for (NSInteger row = 0; row < cities.count; row++) {
        NSMutableArray<NSNumber *> *inner = [NSMutableArray array];
        id<TSPCityProtocol> rowCity = [cities objectAtIndex:row];
        for (NSInteger col = 0; col < cities.count; col++) {
            id<TSPCityProtocol> colCity = [cities objectAtIndex:col];
            // this could be distance or travel time etc. value depends on actual implementation [yufei Dec 18'18@11:39]
            double distance = [rowCity quantityToCity:colCity];
            [inner addObject:[NSNumber numberWithDouble:distance]];
        }
        [distanceMatrix addObject:inner];
    }
    return distanceMatrix;
}

- (double)totalPathDistanceWithMatrix:(NSMutableArray<NSMutableArray<NSNumber *> *> *)matrix path:(int *)p isRoundTrip:(BOOL)isRoundTrip {
    // calculate the total distance by given path('p' as int[]), distance can be found from 'matrix' [yufei Dec 18'18@11:51]
    double result = 0;
    int i = 0;
    for(i = 0; i < matrix.count - 1; i++) {
        int row = p[i];
        int col = p[i+1];
        result += matrix[row][col].doubleValue;
    }
    
    if (isRoundTrip) {
        // connect last elements to 1st if it's a round trip
        result += matrix[p[i]][p[0]].doubleValue;
    }
    
    return result;
}

@end

@implementation TSPSimpleCity

- (instancetype)initWithPointValue:(NSValue *)pointVal {
    if (self = [super init]) {
        _pointVal = [pointVal copy];
    }
    return self;
}
- (double)quantityToCity:(TSPSimpleCity *)anotherCity {
    CGPoint aPt = [self.pointVal CGPointValue];
    CGPoint bPt = [anotherCity.pointVal CGPointValue];
    if (aPt.x == bPt.x && aPt.y == bPt.y) { // same point
        return 0.0;
    } else {
        return fabs(sqrt(pow(bPt.x - aPt.x, 2) + pow(bPt.y - aPt.y, 2)));
    }
}

@end
