//
//  MyScene.h
//  Ping Pong 5
//

//  Copyright (c) 2014 Alexandru Rosianu. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MyScene : SKScene<SKPhysicsContactDelegate>

@property SKShapeNode *topPaddle;
@property SKShapeNode *bottomPaddle;
@property SKShapeNode *ball;
@property SKLabelNode *scoreLabel;
@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;

@property int scoreLeft;
@property int scoreRight;
@property bool pingOrPong;

-(CGPoint)centerOfPath:(CGPathRef)path;
-(SKShapeNode *)createPaddleAtY:(int)y;
-(SKShapeNode *)createBall;

-(void)updateScore;
-(void)ballStartMoving;
-(void)ensureMarginForPaddle:(SKNode *)paddle atTop:(bool)atTop;
-(void)movePaddle:(SKNode *)paddle x:(int)x;

@end
