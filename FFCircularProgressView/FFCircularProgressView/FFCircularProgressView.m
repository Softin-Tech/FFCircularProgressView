//
//  FFCircularProgressBar.m
//  FFCircularProgressBar
//
//  Created by Fabiano Francesconi on 16/07/13.
//  Copyright (c) 2013 Fabiano Francesconi. All rights reserved.
//

#import "FFCircularProgressView.h"

@interface FFCircularProgressView()
@property (nonatomic, strong) CAShapeLayer *progressBackgroundLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) CAShapeLayer *iconLayer;

@property (nonatomic, assign) BOOL isSpinning;

@property (nonatomic, assign) BOOL isAnimatingProgressBackgroundLayerFillColor;
@end

@implementation FFCircularProgressView

#define kArrowSizeRatio .12
#define kStopSizeRatio  .2
#define kTickWidthRatio .3

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setInitialIconView:(UIView *)iconView {
    if (_initialIconView) {
        [_initialIconView removeFromSuperview];
    }
    
    _initialIconView = iconView;
    [self addSubview:_initialIconView];
}

- (void)setCompletedIconView:(UIView *)completedIconView {
    if (_completedIconView) {
        [_completedIconView removeFromSuperview];
    }
    
    _completedIconView = completedIconView;
    [_completedIconView setHidden:true];
    [self addSubview:_completedIconView];
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    
    _progress = -1;
    _lineWidth = fmaxf(self.frame.size.width * 0.025, 1.f);
    _progressColor = [UIColor colorWithRed:0 green:122/255.0 blue:1.0 alpha:1.0];
    _backgroundCircleColor = [UIColor grayColor];
    _tickColor = [UIColor whiteColor];
    
    self.progressBackgroundLayer = [CAShapeLayer layer];
    _progressBackgroundLayer.contentsScale = [[UIScreen mainScreen] scale];
    _progressBackgroundLayer.strokeColor = _progressColor.CGColor;
    _progressBackgroundLayer.fillColor = self.backgroundColor.CGColor;
    _progressBackgroundLayer.lineCap = kCALineCapRound;
    _progressBackgroundLayer.lineWidth = _lineWidth;
    [self.layer addSublayer:_progressBackgroundLayer];
    
    self.progressLayer = [CAShapeLayer layer];
    _progressLayer.contentsScale = [[UIScreen mainScreen] scale];
    _progressLayer.strokeColor = _progressColor.CGColor;
    _progressLayer.fillColor = nil;
    _progressLayer.lineCap = kCALineCapSquare;
    _progressLayer.lineWidth = _lineWidth;
    [self.layer addSublayer:_progressLayer];
    
    self.iconLayer = [CAShapeLayer layer];
    _iconLayer.contentsScale = [[UIScreen mainScreen] scale];
    _iconLayer.strokeColor = nil;
    _iconLayer.fillColor = nil;
    _iconLayer.lineCap = kCALineCapButt;
    _iconLayer.lineWidth = _lineWidth;
    _iconLayer.fillRule = kCAFillRuleNonZero;
    [self.layer addSublayer:_iconLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _initialIconView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    _completedIconView.center = _initialIconView.center;
    _progressBackgroundLayer.frame = [self contentFrame];
    _progressLayer.frame = [self contentFrame];
    _iconLayer.frame = [self contentFrame];
}

- (void)setBackgroundCircleColor:(UIColor *)backgroundCircleColor {
    _backgroundCircleColor = backgroundCircleColor;
    _progressBackgroundLayer.strokeColor = backgroundCircleColor.CGColor;
}

- (void)setProgressColor:(UIColor *)tintColor {
    _progressColor = tintColor;
    _progressLayer.strokeColor = tintColor.CGColor;
}

- (void)setTickColor:(UIColor *)tickColor {
    _tickColor = tickColor;
}

- (void)drawRect:(CGRect)rect {
    // Make sure the layers cover the whole view
    CGRect contentFrame = [self contentFrame];
    _progressBackgroundLayer.frame = contentFrame;
    _progressLayer.frame = contentFrame;
    _iconLayer.frame = contentFrame;
    
    // Draw background
    [self drawBackgroundCircle:_isSpinning];

    // Draw progress
    [self drawProgress];

    [self drawStop];
}

#pragma mark -
#pragma mark Setters

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = fmaxf(lineWidth, 1.f);
    
    _progressBackgroundLayer.lineWidth = _lineWidth;
    _progressLayer.lineWidth = _lineWidth;
    _iconLayer.lineWidth = _lineWidth;
}

#pragma mark -
#pragma mark Drawing

- (void)drawBackgroundCircle:(BOOL)partial {
    if (_progress < 0 || _progress == 1) {
        _progressBackgroundLayer.path = nil;
        return;
    }
    
    CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
    CGFloat endAngle = (2 * (float)M_PI) + startAngle;
    CGPoint center = CGPointMake(_progressBackgroundLayer.bounds.size.width/2, _progressBackgroundLayer.bounds.size.height/2);
    CGFloat radius = center.x - _lineWidth;
    
    // Draw background
    UIBezierPath *processBackgroundPath = [UIBezierPath bezierPath];
    processBackgroundPath.lineWidth = _lineWidth;
    processBackgroundPath.lineCapStyle = kCGLineCapRound;
    
    // Recompute the end angle to make it at 90% of the progress
    if (partial) {
        endAngle = (1.8F * (float)M_PI) + startAngle;
    }
    
    [processBackgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    _progressBackgroundLayer.path = processBackgroundPath.CGPath;
}

- (void)drawProgress {
    if (_progress < 0 || _progress == 1) {
        _progressLayer.path = nil;
        return;
    }
    
    CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
    CGFloat endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
    UIBezierPath *processPath = [UIBezierPath bezierPath];
    processPath.lineCapStyle = kCGLineCapRound;
    processPath.lineWidth = _lineWidth;
    
    CGPoint center = CGPointMake(_progressLayer.bounds.size.width/2, _progressLayer.bounds.size.height/2);
    CGFloat radius = center.x - _lineWidth;
    [processPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    [_progressLayer setPath:processPath.CGPath];
}

- (void)drawStop {
    if (_progress < 0 || _progress == 1) {
        _iconLayer.path = nil;
        return;
    }
    
    CGFloat radius = [self contentSize].width / 2;
    CGFloat ratio = kStopSizeRatio;
    CGFloat sideSize = _iconLayer.bounds.size.width * ratio;
    
    UIBezierPath *stopPath = [self roundedPathFromRect:CGRectMake(0, 0, sideSize, sideSize) radius:0.5];

    // ...and move it into the right place.
    [stopPath applyTransform: CGAffineTransformMakeTranslation(radius * (1-ratio), radius* (1-ratio))];
    
    [_iconLayer setPath:stopPath.CGPath];
    CGColorRef color = _progress == 0 ? _backgroundCircleColor.CGColor : _progressColor.CGColor;
    [_iconLayer setStrokeColor: color];
    [_iconLayer setFillColor: color];
}

#pragma mark Setters

- (void)setProgress:(CGFloat)progress {
    if (progress > 1.0) progress = 1.0;
    
    [_initialIconView setHidden: progress >= 0.0];
    [_completedIconView setHidden: progress != 1.0];
    
    if (progress == 0 && _isSpinning == false) {
        [self startSpinProgressBackgroundLayer];
    }
    
    if (progress > 0.0 && _isSpinning) {
        [self stopSpinProgressBackgroundLayer];
    }
    
    if (_progress != progress) {
        _progress = progress;
        [self setNeedsDisplay];
    }
}

#pragma mark Animations

- (void)startSpinProgressBackgroundLayer {
    self.isSpinning = YES;
    [self drawBackgroundCircle:YES];
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [_progressBackgroundLayer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopSpinProgressBackgroundLayer {
    [self drawBackgroundCircle:NO];
    [_progressBackgroundLayer removeAllAnimations];
    self.isSpinning = NO;
}

- (void)restartAnimation {
    BOOL shouldStart = self.isSpinning;
    self.isSpinning = YES;
    [self stopSpinProgressBackgroundLayer];
    if(shouldStart){
        [self startSpinProgressBackgroundLayer];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    [self restartAnimation];
}

- (void)willMoveToWindow:(UIWindow *)newWindow{
    [super willMoveToWindow:newWindow];
    [self restartAnimation];
}

#pragma mark - Notification

- (void)applicationWillEnterForeground:(NSNotification*)notification{
    [self restartAnimation];
}

#pragma mark - Added

- (CGRect)contentFrame {
    return CGRectMake((self.bounds.size.width - _contentSize.width) / 2,
                      (self.bounds.size.height - _contentSize.height) / 2,
                      _contentSize.width,
                      _contentSize.height);
}

- (UIBezierPath *)roundedPathFromRect:(CGRect)f radius:(CGFloat)radius {

    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    // Draw the path
    [path moveToPoint:CGPointMake(radius, 0)];
    [path addLineToPoint:CGPointMake(f.size.width - radius, 0)];
    [path addArcWithCenter:CGPointMake(f.size.width - radius, radius)
                    radius:radius
                startAngle:- (M_PI / 2)
                  endAngle:0
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(f.size.width, f.size.height - radius)];
    [path addArcWithCenter:CGPointMake(f.size.width - radius, f.size.height - radius)
                    radius:radius
                startAngle:0
                  endAngle:- ((M_PI * 3) / 2)
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(radius, f.size.height)];
    [path addArcWithCenter:CGPointMake(radius, f.size.height - radius)
                    radius:radius
                startAngle:- ((M_PI * 3) / 2)
                  endAngle:- M_PI
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(0, radius)];
    [path addArcWithCenter:CGPointMake(radius, radius)
                    radius:radius
                startAngle:- M_PI
                  endAngle:- (M_PI / 2)
                 clockwise:YES];
    
    return path;
}

@end
