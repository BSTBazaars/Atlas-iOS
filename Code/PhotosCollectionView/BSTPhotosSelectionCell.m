//
//  BSTPhotosSelectionCell.m
//  BST Kicks
//
//  Created by fantom on 2/2/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

#import "BSTPhotosSelectionCell.h"

@interface BSTPhotosSelectionCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *viewOverlay;
@property (strong, nonatomic) UILabel *compressingLabel;
@property (strong, nonatomic) UIButton *sendButton;

@end


@implementation BSTPhotosSelectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        const UIColor *kDefaultColor = [UIColor colorWithRed:5.f/255.f green:176.f/255.f blue:166.f/255.f alpha:1];
        
        self.imageView = [UIImageView new];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.imageView];
        
        self.viewOverlay = [UIView new];
        self.viewOverlay.hidden = YES;
        self.viewOverlay.backgroundColor = [UIColor colorWithRed:5.f/255.f green:176.f/255.f blue:166.f/255.f alpha:0.15];
        [self addSubview:self.viewOverlay];
        
        self.progressBar = [MBCircularProgressBarView new];
        self.progressBar.maxValue = 100;
        self.progressBar.value = 0;
        self.progressBar.valueFontSize = 13;
        self.progressBar.showUnitString = YES;
        self.progressBar.unitFontSize = 13;
        self.progressBar.fontColor = [UIColor colorWithRed:56.0f/255.f green:56.0f/255.f blue:0 alpha:1];
        self.progressBar.progressRotationAngle = 0;
        self.progressBar.progressLineWidth = 3;
        self.progressBar.progressColor = kDefaultColor;
        self.progressBar.progressStrokeColor = [UIColor whiteColor];
        self.progressBar.emptyLineColor = [UIColor lightGrayColor];
        self.progressBar.emptyCapType = 1;
        self.progressBar.emptyLineWidth = 1;
        self.progressBar.backgroundColor = [UIColor clearColor];
        [self.viewOverlay addSubview:self.progressBar];
        
        self.sendButton = [UIButton new];
        [self.sendButton addTarget:self action:@selector(sendBtnDidTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.sendButton setTitle:@"SEND" forState:UIControlStateNormal];
        [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.sendButton.titleLabel.font = [UIFont fontWithName:@"Nexa Bold" size:18];
        [self.sendButton setBackgroundColor:kDefaultColor];
        [self.viewOverlay addSubview:self.sendButton];
        
        self.compressingLabel = [UILabel new];
        self.compressingLabel.textAlignment = NSTextAlignmentCenter;
        self.compressingLabel.text = @"Compressing ...";
        self.compressingLabel.font = [UIFont fontWithName:@"Nexa Light" size:13];
        self.compressingLabel.textColor = [UIColor whiteColor];
        [self.viewOverlay addSubview:self.compressingLabel];
        
        self.clipsToBounds = YES;
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.viewOverlay.hidden = !selected;
}

- (void)setCellStatus:(CellStatus)cellStatus {
    if (cellStatus == CellStatusRegular) {
        self.progressBar.hidden = YES;
        self.compressingLabel.hidden = YES;
        self.sendButton.hidden = NO;
    } else {
        self.progressBar.hidden = NO;
        self.compressingLabel.hidden = NO;
        self.sendButton.hidden = YES;
    }
}

- (void)sendBtnDidTap:(UIButton *)sender {
    if (self.actionBlock) {
        self.actionBlock();
    }
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.progressBar.value = 0;
    self.imageView.image = nil;
}

- (void)layoutSubviews {
    self.imageView.frame = CGRectMake(0,
                                      0,
                                      self.bounds.size.width,
                                      self.bounds.size.height);
    self.viewOverlay.frame = CGRectMake(0,
                                        0,
                                        self.bounds.size.width,
                                        self.bounds.size.height);
    
    self.progressBar.frame = CGRectMake(self.viewOverlay.frame.size.width/2 - 50/2,
                                        self.viewOverlay.frame.size.height/2 - 50/2,
                                        50,
                                        50);
    self.sendButton.frame = CGRectMake(self.viewOverlay.frame.size.width/2 - 70/2,
                                       self.viewOverlay.frame.size.height/2 - 40/2,
                                       70,
                                       40);
    self.compressingLabel.frame = CGRectMake(8,
                                             85,
                                             self.viewOverlay.frame.size.width - 16,
                                             21);
    
}

@end
