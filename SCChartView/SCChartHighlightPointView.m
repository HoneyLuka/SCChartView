//
//  SCChartHighlightPointView.m
//  Test
//
//  Created by Shadow on 2017/3/7.
//  Copyright © 2017年 Shadow. All rights reserved.
//

#import "SCChartHighlightPointView.h"

#define kOriginPointDiameter 12

@interface SCChartHighlightPointView ()

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) CALayer *originPoint;

@end

@implementation SCChartHighlightPointView

- (void)dealloc
{
    for (CALayer *layer in self.layer.sublayers) {
        [layer removeAllAnimations];
    }
}

- (instancetype)initWithColor:(UIColor *)color
{
    self = [super initWithFrame:CGRectMake(0, 0, 40, 40)];
    if (self) {
        self.color = color;
        [self prepare];
    }
    return self;
}

- (void)prepare
{
    self.clipsToBounds = NO;
    self.layer.masksToBounds = NO;
    self.backgroundColor = [UIColor clearColor];
    
    self.originPoint = [CALayer layer];
    self.originPoint.backgroundColor = self.color.CGColor;
    self.originPoint.frame =
    CGRectMake((CGRectGetWidth(self.bounds) - kOriginPointDiameter) / 2,
               (CGRectGetHeight(self.bounds) - kOriginPointDiameter) / 2,
               kOriginPointDiameter,
               kOriginPointDiameter);
    self.originPoint.cornerRadius = kOriginPointDiameter / 2;
    [self.layer addSublayer:self.originPoint];
    
    [self startAnimation];
}

- (void)startAnimation
{
    NSInteger count = 3;
    NSInteger duration = 5;
    for (int i = 0; i < count; i++) {
        CALayer *animLayer = [CALayer layer];
        animLayer.frame = self.originPoint.frame;
        animLayer.backgroundColor = self.color.CGColor;
        animLayer.cornerRadius = kOriginPointDiameter / 2;
        [self.layer insertSublayer:animLayer atIndex:0];
        
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.duration = duration;
        group.repeatCount = MAXFLOAT;
        group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        group.fillMode = kCAFillModeBackwards;
        group.beginTime = CACurrentMediaTime() + (double)i * duration / (double)count;
        group.removedOnCompletion = NO;
        
        CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        alphaAnimation.fromValue = @0.7;
        alphaAnimation.toValue = @0;
        
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = @1;
        scaleAnimation.toValue = @5;

        group.animations = @[alphaAnimation, scaleAnimation];
        
        [animLayer addAnimation:group forKey:@"scaleAnimation"];
    }
}

@end
