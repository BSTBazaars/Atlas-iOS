//
//  BSTPhotosSelectionCell.m
//  BST Kicks
//
//  Created by fantom on 2/2/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

#import "BSTPhotosSelectionCell.h"

@interface BSTPhotosSelectionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *viewOverlay;
@property (weak, nonatomic) IBOutlet UILabel *compressingLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@end


@implementation BSTPhotosSelectionCell

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

- (IBAction)sendBtnDidTap:(UIButton *)sender {
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

@end
