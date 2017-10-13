//
//  SCChartView.h
//  Test
//
//  Created by Shadow on 2017/3/6.
//  Copyright © 2017年 Shadow. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCChartView;
@protocol SCChartViewDataSource <NSObject>

@required

- (NSInteger)numberOfValuesInChartView:(SCChartView *)chartView;
- (CGFloat)valueAtIndex:(NSInteger)index inChartView:(SCChartView *)chartView;

@optional

- (CGFloat)maxValueInChartView:(SCChartView *)chartView;
- (CGFloat)minValueInChartView:(SCChartView *)chartView;

- (NSArray<NSNumber *> *)chartViewNeedShowYAxisWithValues:(SCChartView *)chartView;
- (NSString *)textForYAxisLabelInChartView:(SCChartView *)chartView forValue:(CGFloat)value;

- (NSString *)textForXAxisLabelInChartView:(SCChartView *)chartView atIndex:(NSInteger)index;
- (void)chartView:(SCChartView *)chartView willAddLabel:(UILabel *)label atIndex:(NSInteger)index;

/**
 Ignore When 'showKeyPoint' is YES.
 */
- (BOOL)chartView:(SCChartView *)chartView shouldShowKeyPointAtIndex:(NSInteger)index;

/**
 Implement if need fill.
 */
- (NSInteger)chartViewShouldFillPathToIndex:(SCChartView *)chartView;

- (BOOL)chartView:(SCChartView *)chartView shouldShowHighlightPointAtIndex:(NSInteger)index;

- (void)chartView:(SCChartView *)chartView didTapHighlightPointAtIndex:(NSInteger)index;

- (NSArray<NSNumber *> *)chartViewNeedShowBaseLineWithValues:(SCChartView *)chartView;

@end

@interface SCChartView : UIView

@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, strong) UIColor *highlightPointColor;

@property (nonatomic, assign) BOOL showKeyPoint;
@property (nonatomic, strong) UIColor *keyPointColor;
@property (nonatomic, assign) CGFloat keyPointRadius;
@property (nonatomic, strong) UIImage *keyPointImage;

/**
 Only available when 'keyPointImage' is not empty.
 */
@property (nonatomic, assign) BOOL showKeyPointLine;

@property (nonatomic, strong) UIFont *axisFont;
@property (nonatomic, strong) UIColor *axisColor;

@property (nonatomic, weak) id<SCChartViewDataSource> dataSource;

- (void)reloadChart;

@end
