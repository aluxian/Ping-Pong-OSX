//
//  MyScene.m
//  Ping Pong 5
//
//  Created by Alexandru Rosianu on 12/08/14.
//  Copyright (c) 2014 Alexandru Rosianu. All rights reserved.
//

#import "MyScene.h"

static const int PADDLE_SPEED    = 10;      // The speed the paddles move at
static const int PADDLE_WIDTH    = 100;     // The width of the paddles
static const int PADDLE_HEIGHT   = 20;      // The height of the paddles
static const int PADDLE_RADIUS   = 4;       // The radius of the rounded corners
static const int WINDOW_PADDING  = 20;      // Padding between the window and the paddles
static const int WALL_HIT_OFFSET = 450;     // Minimum x offset to make a ball -- wall collision end the game
static const int BALL_RADIUS     = 10;      // Ball radius in px
static const int BALL_SPEED      = 15;      // The speed of the ball
static const int AI_SPEED        = 10;      // The speed the AI paddle moves with

static const uint32_t BALL_CATEGORY   = 0x1 << 0;
static const uint32_t PADDLE_CATEGORY = 0x1 << 1;
static const uint32_t FRAME_CATEGORY  = 0x1 << 2;

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        // Set contact delegate
        self.physicsWorld.contactDelegate = self;
        
        // TTS
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
        
        // Score label
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        _scoreLabel.fontSize = 30;
        _scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame) + 50);
        [self addChild:_scoreLabel];
        //[self updateScore];
        
        // Top Paddle
        _topPaddle = [self createPaddleAtY:CGRectGetMaxY(self.frame) - WINDOW_PADDING - PADDLE_HEIGHT];
        [self addChild:_topPaddle];
        
        // Bottom Paddle
        _bottomPaddle = [self createPaddleAtY:WINDOW_PADDING];
        [self addChild:_bottomPaddle];
        
        // Ball
        _ball = [self createBall];
        [self addChild:_ball];
        
        // Frame
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody.friction = 0.0f;
        self.physicsBody.categoryBitMask = FRAME_CATEGORY;
        
        // Start
        [self runAction:[SKAction repeatActionForever:[SKAction playSoundFileNamed:@"harp.mp3" waitForCompletion:YES]]];
        [self ballStartMoving];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {

    }
}

-(void)update:(NSTimeInterval)currentTime {
    /*// Move AI
     if (AI_SPEED > 0) {
     int speed = 0;
     
     if (fabs(_ball.position.y - _bottomPaddle.position.y) > 50) {
     speed = (_ball.position.y > _bottomPaddle.position.y ? 1 : -1) * AI_SPEED;
     }
     
     [self movePaddle:_bottomPaddle y:speed];
     [self ensureMarginForPaddle:_bottomPaddle atTop:true];
     [self ensureMarginForPaddle:_bottomPaddle atTop:false];
     }*/
}

-(CGPoint)centerOfPath:(CGPathRef)path {
    CGRect boundingBox = CGPathGetBoundingBox(path);
    return CGPointMake(boundingBox.origin.x + boundingBox.size.width / 2, boundingBox.origin.y + boundingBox.size.height / 2);
}

-(SKShapeNode *)createPaddleAtY:(int)y {
    SKShapeNode *paddle = [[SKShapeNode alloc] init];
    
    paddle.fillColor = [SKColor colorWithRed:0.92 green:1 blue:0.2 alpha:1];
    paddle.strokeColor = [SKColor clearColor];
    
    CGRect rect = CGRectMake(CGRectGetMidX(self.frame) - PADDLE_WIDTH / 2, y, PADDLE_WIDTH, PADDLE_HEIGHT);
    CGPathRef path = CGPathCreateWithRoundedRect(rect, PADDLE_RADIUS, PADDLE_RADIUS, nil);
    
    paddle.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    paddle.physicsBody.dynamic = NO;
    paddle.physicsBody.categoryBitMask = PADDLE_CATEGORY;
    
    [paddle setPath:path];
    CGPathRelease(path);
    
    return paddle;
}

-(void)didBeginContact:(SKPhysicsContact*)contact {
    SKPhysicsBody* firstBody;
    SKPhysicsBody* secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // Ball -- Wall contact
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == FRAME_CATEGORY
        && (_ball.position.x < -WALL_HIT_OFFSET || _ball.position.x > WALL_HIT_OFFSET)) {
        
        if (_ball.position.x < -WALL_HIT_OFFSET) {
            _scoreRight++;
        } else {
            _scoreLeft++;
        }
        
        SKAction *fadeOutAction = [SKAction fadeAlphaTo:0.0f duration:1.0f];
        SKAction *newBallAction = [SKAction runBlock:^{
            [_ball removeFromParent];
            _ball = [self createBall];
            [self addChild:_ball];
            [self ballStartMoving];
        }];
        
        [_ball.physicsBody setLinearDamping:5.0f];
        [_ball runAction:[SKAction sequence:@[fadeOutAction, newBallAction]]];
        
        NSString *utteranceString = [NSString stringWithFormat:@"Oops! %d to %d", _scoreLeft, _scoreRight];
        [_synthesizer speakUtterance:[[AVSpeechUtterance alloc] initWithString:utteranceString]];
        
        [self updateScore];
    }
    
    // Ball -- Paddle contact
    else if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == PADDLE_CATEGORY) {
        [self runAction:[SKAction playSoundFileNamed:@"hit.mp3" waitForCompletion:NO]];
    }
}

-(SKShapeNode *)createBall {
    SKShapeNode *ball = [[SKShapeNode alloc] init];
    ball.fillColor = [SKColor colorWithRed:0.99 green:0.82 blue:0.16 alpha:1];
    ball.strokeColor = [SKColor clearColor];
    
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:BALL_RADIUS center:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))];
    ball.physicsBody.allowsRotation = NO;
    
    ball.physicsBody.friction = 0.0f;
    ball.physicsBody.restitution = 1.0f;
    ball.physicsBody.linearDamping = 0.0f;
    
    ball.physicsBody.categoryBitMask = BALL_CATEGORY;
    ball.physicsBody.contactTestBitMask = FRAME_CATEGORY | PADDLE_CATEGORY;
    
    CGMutablePathRef ballPath = CGPathCreateMutable();
    CGPathAddArc(ballPath, NULL, CGRectGetMidX(self.frame), CGRectGetMidY(self.frame), BALL_RADIUS, M_PI*2, 0, YES);
    
    [ball setPath:ballPath];
    CGPathRelease(ballPath);
    
    return ball;
}

-(void)updateScore {
    _scoreLabel.text = [NSString stringWithFormat:@"%d - %d", _scoreLeft, _scoreRight];
}

-(void)ballStartMoving {
    float angle = arc4random_uniform(M_PI * 2 * 100) / 100;
    [_ball.physicsBody applyImpulse:CGVectorMake(BALL_SPEED * cosf(angle), BALL_SPEED * sinf(angle))];
}

-(void)ensureMarginForPaddle:(SKNode *)paddle atTop:(bool)atTop {
    /*float maxY = CGRectGetMaxY(self.frame) / 2 - PADDLE_HEIGHT / 2 - WINDOW_PADDING;
     
     if (!atTop) {
     maxY = -maxY;
     }
     
     if (atTop == paddle.position.y > maxY) {
     paddle.position = CGPointMake(paddle.position.x, maxY);
     }*/
}

-(void)movePaddle:(SKNode *)paddle x:(int)x {
    paddle.position = CGPointMake(paddle.position.x + x, paddle.position.y);
}

@end
