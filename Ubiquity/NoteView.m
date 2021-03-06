//
//  NoteView.m
//  Ubiquity
//
//  Created by Winnie Wu on 8/13/13.
//  Copyright (c) 2013 Team Ubi. All rights reserved.
//

static CGFloat const kHeaderFontSize = 16.f;
static CGFloat const kFromFontSize = 15.f;
static CGFloat const kSentLabelFontSize = 12.f;
static CGFloat const kMessageFontSize = 11.f;


#import "NoteView.h"
#import "NewMessageView.h"


@implementation NoteView
#define WIDEST_POINT self.envelope.frame.size.width * 7/10;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        int const SCREEN_WIDTH = frame.size.width;
        int const SCREEN_HEIGHT = frame.size.height;
        
        
        [self createEnvelopeBackgroundWithWidth: SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
        
        [self createAddressTitleBarWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
                
        [self createMessageWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
        
        [self createFromLabelWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
        
        [self createSentLabelWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
        [self createPagingLabelWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
        [self createImageViewWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
        [self createPictureButtonWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];
        [self createMusicButtonWithWidth:SCREEN_WIDTH andHeight:SCREEN_HEIGHT];


    }
    return self;
}



- (void) createEnvelopeBackgroundWithWidth: (int)w andHeight: (int)h
{
    int imageWidth = w * 19 / 20;
    int imageHeight = h * 19 / 20;
    self.envelope = [[UIImageView alloc] initWithFrame:CGRectMake(w/2 - imageWidth / 2, h - imageHeight, imageWidth, imageHeight)];
    self.envelope.image = [UIImage imageNamed:@"envelope"];
    [self addSubview:self.envelope];
    
}

- (void) createSentLabelWithWidth: (int) w andHeight: (int) h
{
    int width = WIDEST_POINT;
    int innerFrameLeftMargin = w/2 - width/2;
    int innerFrameTopMargin = h - TOP_PADDING * 8;
    self.sentLabel = [[UILabel alloc] initWithFrame:CGRectMake(innerFrameLeftMargin, innerFrameTopMargin, width, LINE_HEIGHT)];
    self.sentLabel.text = @"10:20 AM, 08 August 2013";
    // self.sentLabel.backgroundColor = [UIColor greenColor];
    self.sentLabel.backgroundColor = [UIColor clearColor];
    
    self.sentLabel.textAlignment = NSTextAlignmentCenter;
    self.sentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.sentLabel.numberOfLines = 2;
    self.sentLabel.font = [UIFont systemFontOfSize: kSentLabelFontSize];
    [self addSubview:self.sentLabel];
}

- (void) createPagingLabelWithWidth: (int) w andHeight: (int) h
{
    int width = WIDEST_POINT;
    int innerFrameLeftMargin = w/2 - width/2;
    CGFloat iconDimensions = 20.0;
    int innerFrameTopMargin = h-self.envelope.frame.size.height+ ADDRESS_PADDING;
    self.pagingLabel = [[UILabel alloc] initWithFrame:CGRectMake(innerFrameLeftMargin, innerFrameTopMargin, width, LINE_HEIGHT)];
    self.pagingLabel.text = @"1 of 2";
    // self.sentLabel.backgroundColor = [UIColor greenColor];
    self.pagingLabel.backgroundColor = [UIColor clearColor];
    
    self.pagingLabel.textAlignment = NSTextAlignmentCenter;
    self.pagingLabel.font = [UIFont systemFontOfSize: kSentLabelFontSize];
    [self addSubview:self.pagingLabel];
    
    self.leftArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    self.leftArrow.frame = CGRectMake(innerFrameLeftMargin + LEFT_PADDING*1.1, innerFrameTopMargin + 5, iconDimensions, iconDimensions);
    [self.leftArrow setBackgroundImage: [UIImage imageNamed:@"leftarrow"] forState: UIControlStateNormal];
    [self addSubview: self.leftArrow];

    
    self.rightArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightArrow.frame = CGRectMake(innerFrameLeftMargin + width - LEFT_PADDING * 1.5, innerFrameTopMargin + 5, iconDimensions, iconDimensions);
    [self.rightArrow setBackgroundImage: [UIImage imageNamed:@"rightarrow"] forState: UIControlStateNormal];
    [self addSubview: self.rightArrow];

}






- (void) createAddressTitleBarWithWidth: (int)w andHeight: (int)h
{
    int addressWidth = WIDEST_POINT;
    int addressHeight = HEADER_HEIGHT;
    self.addressTitle = [[UILabel alloc] initWithFrame: CGRectMake(w/2 - addressWidth/2, h-self.envelope.frame.size.height+ ADDRESS_PADDING*3, addressWidth, addressHeight)];
    self.addressTitle.textAlignment = NSTextAlignmentCenter;
    self.addressTitle.font = [UIFont systemFontOfSize: kHeaderFontSize];
    self.addressTitle.text = @"<INSERT ADDRESS>";
    // self.addressTitle.backgroundColor = [UIColor greenColor];
    self.addressTitle.backgroundColor = [UIColor clearColor];
    [self addSubview:self.addressTitle];
    
}


- (void) createMessageWithWidth: (int) w andHeight: (int) h
{
    int innerFrameTopMargin = h - self.envelope.frame.size.height + HEADER_HEIGHT + TOP_PADDING * 1.5;
    int width = WIDEST_POINT;
    int height = h * 2 / 5 ;
    int innerFrameLeftMargin = w/2 - width/2;
    self.textScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(innerFrameLeftMargin, innerFrameTopMargin, width, height)];
    self.messageTextView = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, width, height)];
    self.messageTextView.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageTextView.numberOfLines = 0;

    [self.textScroll addSubview: self.messageTextView];
    self.messageTextView.font = [UIFont systemFontOfSize: kMessageFontSize];
    self.messageTextView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.textScroll];
    
}

- (void) createFromLabelWithWidth: (int) w andHeight: (int) h
{
    int width = WIDEST_POINT;
    int innerFrameLeftMargin = w/2 - width/2;
    int innerFrameTopMargin = h - TOP_PADDING * 9.0;
    self.fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(innerFrameLeftMargin, innerFrameTopMargin, width, LINE_HEIGHT)];
    self.fromLabel.text = @"<INSERT SENDERS NAME>";
    self.fromLabel.textAlignment = NSTextAlignmentRight;
    self.fromLabel.font = [UIFont systemFontOfSize: kFromFontSize];
    [self addSubview:self.fromLabel];
}


- (void) createImageViewWithWidth: (int) w andHeight: (int) h
{
    int width = WIDEST_POINT;
    int height = self.textScroll.frame.size.height*9/10;
    int innerFrameTopMargin = self.textScroll.frame.origin.y;
    int innerFrameLeftMargin = self.textScroll.frame.origin.x;

    self.image = [[UIView alloc] initWithFrame:CGRectMake(innerFrameLeftMargin, innerFrameTopMargin, width, height)];
    self.image.backgroundColor = [UIColor clearColor];

}

- (void) createPictureButtonWithWidth: (int) w andHeight: (int) h
{
    CGFloat iconDimensions = 35.0;
    self.pictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *pictureButtonImage = [UIImage imageNamed:@"camera"];
    [self.pictureButton setBackgroundImage:pictureButtonImage forState:UIControlStateNormal];
    int width = WIDEST_POINT;
    int innerFrameLeftMargin = w/2 + width/2 - iconDimensions;
    int innerFrameTopMargin = h - TOP_PADDING * 10.75;
    self.pictureButton.frame = CGRectMake(innerFrameLeftMargin, innerFrameTopMargin, iconDimensions*1.1, iconDimensions);
    [self addSubview:self.pictureButton];
}

- (void)createMusicButtonWithWidth:(int)w andHeight:(int) h
{
    CGFloat iconDimensions = 35.0;
    self.musicButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *musicButtonImage = [UIImage imageNamed:@"musicNote"];
    [self.musicButton setBackgroundImage:musicButtonImage forState:UIControlStateNormal];
    int width = WIDEST_POINT;
    int innerFrameLeftMargin = w/2 - width/2;
    int innerFrameTopMargin = h - TOP_PADDING * 10.75;
    CGRect musicFrame = CGRectMake(innerFrameLeftMargin, innerFrameTopMargin, iconDimensions, iconDimensions);
    [_musicButton setFrame:musicFrame];
    [self addSubview:self.musicButton];
}





@end
