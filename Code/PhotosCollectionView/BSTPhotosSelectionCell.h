//
//  BSTPhotosSelectionCell.h
//  BST Kicks
//
//  Created by fantom on 2/2/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBCircularProgressBarView.h"

typedef NS_ENUM(NSInteger, CellStatus) {
    CellStatusRegular,
    CellStatusDownloading
};

@interface BSTPhotosSelectionCell : UICollectionViewCell

@property (nonatomic, copy) void(^actionBlock)(void);
@property (nonatomic, assign) CellStatus cellStatus;

@property (nonatomic, weak) IBOutlet MBCircularProgressBarView *progressBar;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, copy) NSString *representedAssetIdentifier;

@end
