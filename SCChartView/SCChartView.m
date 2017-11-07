//
//  SCChartView.m
//  Test
//
//  Created by Shadow on 2017/3/6.
//  Copyright © 2017年 Shadow. All rights reserved.
//

#import "SCChartView.h"
#import "SCChartHighlightPointView.h"

const CGFloat kSCChartViewBottomOffset = 25.f;

@interface SCChartView ()

@property (nonatomic, strong) UIView *canvas;
@property (nonatomic, strong) UIView *keyPointCanvas;

@property (nonatomic, strong) NSMutableArray *baseLineLayers;

@property (nonatomic, strong) CAShapeLayer *pathLayer;
@property (nonatomic, strong) CAShapeLayer *fillLayer;
@property (nonatomic, strong) CAShapeLayer *pointLayer;

@property (nonatomic, strong) NSMutableArray *xAxisLabels;
@property (nonatomic, strong) NSMutableArray *yAxisLabels;

@property (nonatomic, strong) NSMutableArray *values;
@property (nonatomic, strong) NSMutableArray *points;

@property (nonatomic, assign) CGFloat minValue;
@property (nonatomic, assign) CGFloat maxValue;

@end

@implementation SCChartView

#pragma mark - Override

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self prepare];
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithFrame:CGRectMake(0, 0, 100, 100)];
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self reloadChart];
}

#pragma mark - Public

- (void)reloadChart
{
    [self startDrawing];
}

#pragma mark - Inner

- (void)clear
{
    [self.yAxisLabels makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.yAxisLabels removeAllObjects];
    [self.xAxisLabels makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.xAxisLabels removeAllObjects];
    self.values = nil;
    self.points = nil;
    
    [self.baseLineLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.baseLineLayers removeAllObjects];
    
    [self.pathLayer removeFromSuperlayer];
    self.pathLayer = nil;
    [self.pointLayer removeFromSuperlayer];
    self.pointLayer = nil;
    [self.fillLayer removeFromSuperlayer];
    self.fillLayer = nil;
    
    while (self.keyPointCanvas.subviews.count) {
        UIView *view = self.keyPointCanvas.subviews.firstObject;
        [view removeFromSuperview];
    }
    
    while (self.keyPointCanvas.layer.sublayers.count) {
        CALayer *layer = self.keyPointCanvas.layer.sublayers.firstObject;
        [layer removeFromSuperlayer];
    }
}

- (void)prepare
{
    self.lineWidth = 2.f;
    self.themeColor = [UIColor orangeColor];
    self.keyPointColor = [UIColor blueColor];
    self.keyPointRadius = 3.f;
    
    self.highlightPointColor = [UIColor redColor];
    
    self.yAxisLabels = [NSMutableArray array];
    self.xAxisLabels = [NSMutableArray array];
    self.baseLineLayers = [NSMutableArray array];
    
    self.canvas = [[UIView alloc]initWithFrame:
                   CGRectMake(0,
                              0,
                              CGRectGetWidth(self.bounds),
                              CGRectGetHeight(self.bounds) - kSCChartViewBottomOffset)];
    self.canvas.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.canvas.backgroundColor = [UIColor clearColor];
    [self addSubview:self.canvas];
    
    self.keyPointCanvas = [[UIView alloc]initWithFrame:self.canvas.bounds];
    self.keyPointCanvas.backgroundColor = [UIColor clearColor];
    self.keyPointCanvas.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.canvas addSubview:self.keyPointCanvas];
}

#pragma mark - Draw

- (void)checkCanvasBounds
{
    if (![self shouldShowXAxis]) {
        if (!CGRectEqualToRect(self.bounds, self.canvas.bounds)) {
            self.canvas.frame = self.bounds;
        }
        
        return;
    }
    
    if (CGRectEqualToRect(self.bounds, self.canvas.bounds)) {
        self.canvas.frame = CGRectMake(0,
                                       0,
                                       CGRectGetWidth(self.bounds),
                                       CGRectGetHeight(self.bounds) - kSCChartViewBottomOffset);
    }
}

- (void)collectValues
{
    NSInteger valueCount = [self.dataSource numberOfValuesInChartView:self];
    
    if (valueCount <= 0) {
        return;
    }
    
    NSMutableArray *values = [NSMutableArray array];
    for (int i = 0; i < valueCount; i++) {
        CGFloat value = [self.dataSource valueAtIndex:i inChartView:self];
        [values addObject:@(value)];
    }
    
    if (values.count != valueCount) {
        return;
    }
    
    self.values = values;
}

- (void)detectMaxAndMinValue
{
    if ([self.dataSource respondsToSelector:@selector(maxValueInChartView:)]) {
        self.maxValue = [self.dataSource maxValueInChartView:self];
    } else {
        self.maxValue = [self pickMaxValueInArray:self.values];
    }
    
    if ([self.dataSource respondsToSelector:@selector(minValueInChartView:)]) {
        self.minValue = [self.dataSource minValueInChartView:self];
    } else {
        self.minValue = [self pickMinValueInArray:self.values];
    }
}

- (void)generatePoints
{
    NSMutableArray *points = [NSMutableArray array];
    
    CGFloat maxX = CGRectGetWidth(self.canvas.bounds);
    
    CGFloat stepX = 0;
    if (self.values.count - 1 != 0) {
        stepX = maxX / (self.values.count - 1);
    }
    
    for (int i = 0; i < self.values.count; i++) {
        //x
        CGFloat x = stepX * i;
        
        //y
        CGFloat value = [(NSNumber *)self.values[i] floatValue];
        CGFloat y = [self yPositionForValue:value];
        
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
    }
    
    self.points = points;
}

- (void)drawPath
{
    UIBezierPath *bezierPath = [self.class quadCurvedPathWithPoints:self.points];
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.frame = self.canvas.bounds;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = self.themeColor.CGColor;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinBevel;
    layer.lineWidth = self.lineWidth;
    layer.rasterizationScale = [UIScreen mainScreen].scale * 2;
    layer.shouldRasterize = YES;
    
    layer.path = bezierPath.CGPath;
    
    [self.canvas.layer insertSublayer:layer atIndex:0];
    
    self.pathLayer = layer;
}

- (void)drawKeyPointUsingLayer
{
    UIBezierPath *path = [self keyPointPath];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.frame = self.canvas.bounds;
    layer.fillColor = self.keyPointColor.CGColor;
    layer.strokeColor = [UIColor clearColor].CGColor;
    layer.lineCap = kCALineCapRound;
    layer.rasterizationScale = [UIScreen mainScreen].scale * 2;
    layer.shouldRasterize = YES;
    
    layer.path = path.CGPath;
    [self.keyPointCanvas.layer addSublayer:layer];
    
    self.pointLayer = layer;
}

- (void)drawKeyPointLineIfNeeded:(CGPoint)point
{
    if (!self.showKeyPointLine) {
        return;
    }
    
    CGFloat maxY = CGRectGetHeight(self.canvas.bounds);
    CALayer *lineLayer = [CALayer layer];
    lineLayer.frame = CGRectMake(point.x - self.lineWidth / 2, point.y, self.lineWidth, maxY - point.y);
    lineLayer.backgroundColor = [UIColor whiteColor].CGColor;
    
    [self.keyPointCanvas.layer addSublayer:lineLayer];
    
    CALayer *baseVerticalLineLayer = [CALayer layer];
    baseVerticalLineLayer.frame = CGRectMake(point.x, 0, 1, maxY);
    baseVerticalLineLayer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    [self.canvas.layer insertSublayer:baseVerticalLineLayer atIndex:0];
    [self.baseLineLayers addObject:baseVerticalLineLayer];
}

- (void)drawKeyPointUsingImageView
{
    NSInteger index = 0;
    for (NSValue *pointValue in self.points) {
        BOOL should = YES;
        if (!self.showKeyPoint &&
            [self.dataSource respondsToSelector:@selector(chartView:shouldShowKeyPointAtIndex:)]) {
            should = [self.dataSource chartView:self shouldShowKeyPointAtIndex:index];
        }
        
        if (should) {
            CGPoint point = pointValue.CGPointValue;
            
            [self drawKeyPointLineIfNeeded:point];
            
            UIImageView *imageView = [[UIImageView alloc]initWithImage:self.keyPointImage];
            [self.keyPointCanvas addSubview:imageView];
            imageView.center = point;
        }
        
        index++;
    }
}

- (void)drawKeyPoint
{
    if (!self.showKeyPoint &&
        ![self.dataSource respondsToSelector:@selector(chartView:shouldShowKeyPointAtIndex:)]) {
        return;
    }
    
    if (!self.keyPointImage) {
        [self drawKeyPointUsingLayer];
        return;
    }
    
    [self drawKeyPointUsingImageView];
}

- (void)fillPathIfNeeded
{
    if (![self.dataSource respondsToSelector:@selector(chartViewShouldFillPathToIndex:)]) {
        return;
    }
    
    NSInteger toIndex = [self.dataSource chartViewShouldFillPathToIndex:self];
    if (toIndex >= [self.dataSource numberOfValuesInChartView:self] ||
        toIndex <= 0) {
        return;
    }
    
    UIBezierPath *path = [self fillPathToIndex:toIndex];
    [path closePath];
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.frame = self.canvas.bounds;
    
    UIColor *fillColor = [self.themeColor colorWithAlphaComponent:0.1f];
    layer.fillColor = fillColor.CGColor;
    layer.strokeColor = [UIColor clearColor].CGColor;
    layer.lineCap = kCALineCapRound;
    layer.rasterizationScale = [UIScreen mainScreen].scale * 2;
    layer.shouldRasterize = YES;
    
    layer.path = path.CGPath;
    [self.canvas.layer insertSublayer:layer atIndex:1];
    
    self.fillLayer = layer;
}

- (void)drawHighlightPointIfNeeded
{
    if (![self.dataSource respondsToSelector:@selector(chartView:shouldShowHighlightPointAtIndex:)]) {
        return;
    }
    
    for (int i = 0; i < self.points.count; i++) {
        BOOL should = [self.dataSource chartView:self shouldShowHighlightPointAtIndex:i];
        if (!should) {
            continue;
        }
        
        NSValue *value = self.points[i];
        CGPoint point = value.CGPointValue;
        
        SCChartHighlightPointView *view =
        [[SCChartHighlightPointView alloc]initWithColor:self.highlightPointColor];
        view.tag = i;
        [self.keyPointCanvas addSubview:view];
        view.center = point;
        
        UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc]initWithTarget:self
                                               action:@selector(onHighlightViewTap:)];
        [view addGestureRecognizer:tap];
    }
}

- (void)drawYAxis
{
    if (![self.dataSource respondsToSelector:@selector(chartViewNeedShowYAxisWithValues:)]) {
        return;
    }
    
    NSArray *values = [self.dataSource chartViewNeedShowYAxisWithValues:self];
    if (!values.count) {
        return;
    }
    
    CGFloat maxY = CGRectGetHeight(self.canvas.bounds);
    
    for (int i = 0; i < values.count; i++) {
        CGFloat value = [(NSNumber *)values[i] floatValue];
        CGFloat y = [self yPositionForValue:value];
        
        UILabel *label = [[UILabel alloc]init];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = self.axisColor;
        label.font = self.axisFont;
        label.text = [self.dataSource textForYAxisLabelInChartView:self forValue:value];
        [label sizeToFit];
        
        CGRect frame = label.frame;
        if (value == self.maxValue) {
            frame.origin.y = 0;
        } else if (value == self.minValue) {
            frame.origin.y = maxY - CGRectGetHeight(label.bounds);
        } else {
            frame.origin.y = y;    // - (CGRectGetHeight(label.bounds) / 2.f);
        }
        
        label.frame = frame;
        
        [self.canvas insertSubview:label atIndex:0];
        [self.yAxisLabels addObject:label];
    }
}

- (void)drawXAxis
{
    if (![self shouldShowXAxis]) {
        return;
    }
    
    CGFloat maxX = CGRectGetWidth(self.bounds);
    CGFloat y = CGRectGetHeight(self.canvas.bounds) + 5;
    
    for (int i = 0; i < self.points.count; i++) {
        NSString *text = [self.dataSource textForXAxisLabelInChartView:self atIndex:i];
        if (!text.length) {
            continue;
        }
        
        NSValue *pointValue = self.points[i];
        CGPoint point = pointValue.CGPointValue;
        
        UILabel *label = [[UILabel alloc]init];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = self.axisColor;
        label.font = self.axisFont;
        label.text = text;
        [label sizeToFit];
        
        CGFloat x = point.x - CGRectGetWidth(label.bounds) / 2;
        CGRect frame = label.frame;
        frame.origin.y = y;
        
        if (i == 0) { //first
            frame.origin.x = 0;
        } else if (i == self.points.count - 1) { //last
            frame.origin.x = maxX - CGRectGetWidth(label.bounds);
        } else {
            frame.origin.x = x;
        }
        
        label.frame = frame;
        
        [self.canvas insertSubview:label atIndex:0];
        
        [self.xAxisLabels addObject:label];
        
        if ([self.dataSource respondsToSelector:@selector(chartView:willAddLabel:atIndex:)]) {
            [self.dataSource chartView:self willAddLabel:label atIndex:i];
        }
    }
}

- (void)drawAxis
{
    [self drawYAxis];
    [self drawXAxis];
}

- (void)drawBaseLineIfNeeded
{
    if (![self.dataSource respondsToSelector:@selector(chartViewNeedShowBaseLineWithValues:)] ||
        ![self.dataSource chartViewNeedShowBaseLineWithValues:self]) {
        return;
    }
    
    NSArray *values = [self.dataSource chartViewNeedShowBaseLineWithValues:self];
    for (NSNumber *number in values) {
        CGFloat value = number.floatValue;
        CGFloat y = [self yPositionForValue:value];
        
        CALayer *layer = [CALayer layer];
        layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
        layer.frame = CGRectMake(0, y, CGRectGetWidth(self.canvas.bounds), 1);
        [self.canvas.layer insertSublayer:layer atIndex:0];
        
        [self.baseLineLayers addObject:layer];
    }
}

- (void)startDrawing
{
    [self clear];
    
    [self collectValues];
    if (!self.values.count) {
        return;
    }
    
    [self checkCanvasBounds];
    
    [self detectMaxAndMinValue];
    if (self.minValue == self.maxValue) {
        return;
    }
    
    [self generatePoints];
    [self drawPath];
    [self drawBaseLineIfNeeded];
    [self fillPathIfNeeded];
    [self drawHighlightPointIfNeeded];
    [self drawKeyPoint];
    [self drawAxis];
}

#pragma mark - Action

- (void)onHighlightViewTap:(UITapGestureRecognizer *)tap
{
    NSInteger index = tap.view.tag;
    if ([self.dataSource respondsToSelector:@selector(chartView:didTapHighlightPointAtIndex:)]) {
        [self.dataSource chartView:self didTapHighlightPointAtIndex:index];
    }
}

#pragma mark - Utils

- (CGFloat)yPositionForValue:(CGFloat)value
{
    CGFloat maxY = CGRectGetHeight(self.canvas.bounds);
    value = MIN(value, self.maxValue);
    value = MAX(value, self.minValue);
    value -= self.minValue;
    
    CGFloat percentY = value / (self.maxValue - self.minValue);
    CGFloat y = maxY - maxY * percentY;
    return y;
}

- (BOOL)shouldShowXAxis
{
    if (![self.dataSource respondsToSelector:@selector(textForXAxisLabelInChartView:atIndex:)]) {
        return NO;
    }
    
    for (int i = 0; i < self.values.count; i++) {
        if ([self.dataSource textForXAxisLabelInChartView:self atIndex:i].length) {
            return YES;
        }
    }
    
    return NO;
}

- (UIBezierPath *)fillPathToIndex:(NSInteger)index
{
    NSMutableArray *pointArray = [NSMutableArray array];
    
    CGFloat maxY = CGRectGetHeight(self.canvas.bounds);
    
    //start point
    NSValue *startPoint = [NSValue valueWithCGPoint:CGPointMake(0, maxY)];
    [pointArray addObject:startPoint];
    
    //middle point
    NSArray *subPoints = [self.points subarrayWithRange:NSMakeRange(0, index + 1)];
    [pointArray addObjectsFromArray:subPoints];
    
    //end point
    NSValue *lastPoint = subPoints.lastObject;
    CGFloat lastX = lastPoint.CGPointValue.x;
    
    NSValue *endPoint = [NSValue valueWithCGPoint:CGPointMake(lastX, maxY)];
    [pointArray addObject:endPoint];
    
    return [self.class quadCurvedPathWithPoints:pointArray];
}

- (UIBezierPath *)keyPointPath
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    NSInteger index = 0;
    for (NSValue *pointValue in self.points) {
        CGPoint point = pointValue.CGPointValue;
        [path moveToPoint:point];
        
        BOOL should = YES;
        if (!self.showKeyPoint &&
            [self.dataSource respondsToSelector:@selector(chartView:shouldShowKeyPointAtIndex:)]) {
            should = [self.dataSource chartView:self shouldShowKeyPointAtIndex:index];
        }
        
        if (should) {
            [path addArcWithCenter:point radius:self.keyPointRadius startAngle:0 endAngle:180 clockwise:YES];
        }
        
        index++;
    }
    
    return path;
}

- (CGFloat)pickMaxValueInArray:(NSArray *)values
{
    if (!values.count) {
        return 0;
    }
    
    CGFloat maxValue = [(NSNumber *)values.firstObject floatValue];
    
    for (NSNumber *value in values) {
        CGFloat v = value.floatValue;
        if (v > maxValue) {
            maxValue = v;
        }
    }
    
    return maxValue;
}

- (CGFloat)pickMinValueInArray:(NSArray *)values
{
    if (!values.count) {
        return 0;
    }
    
    CGFloat minValue = [(NSNumber *)values.firstObject floatValue];
    for (NSNumber *value in values) {
        CGFloat v = value.floatValue;
        if (v < minValue) {
            minValue = v;
        }
    }
    
    return minValue;
}

static CGPoint midPointForPoints(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
}

static CGPoint controlPointForPoints(CGPoint p1, CGPoint p2) {
    CGPoint controlPoint = midPointForPoints(p1, p2);
    CGFloat diffY = fabs(p2.y - controlPoint.y);
    
    if (p1.y < p2.y)
        controlPoint.y += diffY;
    else if (p1.y > p2.y)
        controlPoint.y -= diffY;
    
    return controlPoint;
}

+ (UIBezierPath *)quadCurvedPathWithPoints:(NSArray *)points {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    if (points.count == 2) {
        value = points[1];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
        return path;
    }
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        
        CGPoint midPoint = midPointForPoints(p1, p2);
        [path addQuadCurveToPoint:midPoint controlPoint:controlPointForPoints(midPoint, p1)];
        [path addQuadCurveToPoint:p2 controlPoint:controlPointForPoints(midPoint, p2)];
        
        p1 = p2;
    }
    return path;
}

@end
