//
//  ViewController.m
//  TSPAOC
//
//  Created by YUFEI LANG on 12/17/18.
//  Copyright © 2018 The Casey Group. All rights reserved.
//

#import "ViewController.h"
#import "TSPSolver.h"
#import "PathView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *aocBtn;
@property (strong, nonatomic) PathView *pathView;
@property (strong, nonatomic) NSMutableArray<id<TSPCityProtocol>> *cities;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    //    TSPSimpleCity *a = [[TSPSimpleCity alloc] initWithCoordinate:CLLocationCoordinate2DMake(1, 1)];
    //    TSPSimpleCity *b = [[TSPSimpleCity alloc] initWithCoordinate:CLLocationCoordinate2DMake(2, 3)];
    //    TSPSimpleCity *c = [[TSPSimpleCity alloc] initWithCoordinate:CLLocationCoordinate2DMake(3, 5)];
    //    TSPSimpleCity *d = [[TSPSimpleCity alloc] initWithCoordinate:CLLocationCoordinate2DMake(4, 5)];
    //    TSPSimpleCity *e = [[TSPSimpleCity alloc] initWithCoordinate:CLLocationCoordinate2DMake(5, 3)];
    //    TSPSimpleCity *f = [[TSPSimpleCity alloc] initWithCoordinate:CLLocationCoordinate2DMake(5, 2)];
    //    TSPSimpleCity *g = [[TSPSimpleCity alloc] initWithCoordinate:CLLocationCoordinate2DMake(4, 1)];
    //    self.cities = @[g,e,a,b,d,f,c];
    self.cities = [NSMutableArray array];
    for (NSInteger cnt = 1; cnt <= 25; cnt++) {
        int x = arc4random()%300;
        int y = arc4random()%300;
        TSPSimpleCity *city = [[TSPSimpleCity alloc] initWithPointValue:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        [self.cities addObject:city];
    }
}

- (IBAction)aocBtnTapped:(UIButton *)sender {
    TSPSolver *tspSolver = [[TSPSolver alloc] init];
    NSDate *startDate = [NSDate date];
    [tspSolver performAOCOptimizationWithCities:self.cities startPointIdx:0 endPointIdx:0 maxSameResultTryTime:250 progress:^BOOL(NSInteger triedNum, double totalQuantity) {
        return triedNum > 500 ? NO : YES;
    } complete:^(NSArray<NSNumber *> * _Nonnull idxInOrgAry, double totalQuantity) {
        NSLog(@"%@", [NSString stringWithFormat:@"[t:%fs]optimization result: %@", [[NSDate date] timeIntervalSinceDate:startDate], idxInOrgAry]);
        if (self.pathView) {
            [self.pathView removeFromSuperview];
            self.pathView = nil;
        }
        self.pathView = [[PathView alloc] initWithFrame:CGRectMake(0, 0, 1., 1.)];
        self.pathView.translatesAutoresizingMaskIntoConstraints = NO;
        NSMutableArray<TSPSimpleCity *> *pts = [NSMutableArray array];
        [idxInOrgAry enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [pts addObject:[self.cities objectAtIndex:obj.integerValue]];
        }];
        [self.view addSubview:self.pathView];
        NSDictionary *views = @{@"pathView": self.pathView, @"aocBtn": self.aocBtn};
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pathView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-50-[pathView]-10-[aocBtn]" options:0 metrics:nil views:views]];
        [self.view layoutIfNeeded];
        self.pathView.cities = pts;
        [self.pathView setNeedsDisplay];
    }];
}

- (IBAction)aoc2BtnTapped:(id)sender {
    TSPSolver *tspSolver = [[TSPSolver alloc] init];
    NSDate *startDate = [NSDate date];
    [tspSolver performAOCOptimizationWithCities:self.cities startPointIdx:-1 endPointIdx:-1 maxSameResultTryTime:50 progress:^BOOL(NSInteger triedNum, double totalQuantity) {
        return triedNum > 500 ? NO : YES;
    } complete:^(NSArray<NSNumber *> * _Nonnull idxInOrgAry, double totalQuantity) {
        NSLog(@"%@", [NSString stringWithFormat:@"[t:%fs]optimization result: %@", [[NSDate date] timeIntervalSinceDate:startDate], idxInOrgAry]);
        if (self.pathView) {
            [self.pathView removeFromSuperview];
            self.pathView = nil;
        }
        self.pathView = [[PathView alloc] initWithFrame:CGRectMake(0, 0, 1., 1.)];
        self.pathView.translatesAutoresizingMaskIntoConstraints = NO;
        NSMutableArray<TSPSimpleCity *> *pts = [NSMutableArray array];
        [idxInOrgAry enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [pts addObject:[self.cities objectAtIndex:obj.integerValue]];
        }];
        [self.view addSubview:self.pathView];
        NSDictionary *views = @{@"pathView": self.pathView, @"aocBtn": self.aocBtn};
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pathView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-50-[pathView]-10-[aocBtn]" options:0 metrics:nil views:views]];
        [self.view layoutIfNeeded];
        self.pathView.cities = pts;
        [self.pathView setNeedsDisplay];
    }];
}

@end
