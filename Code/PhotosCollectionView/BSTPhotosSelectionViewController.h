//
//  BSTPhotosSelectionViewController.h
//  BST Kicks
//
//  Created by fantom on 2/2/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BSTPhotosSelectionViewController;

@protocol BSTPhotosSelectionViewControllerDelegate <NSObject>

- (void)photosSelectionViewController:(BSTPhotosSelectionViewController *)controller shouldSendImageWithUrl:(NSURL *)imageURL;
- (void)photosSelectionViewController:(BSTPhotosSelectionViewController *)controller shouldSendVideoWithUrl:(NSURL *)videoURL;

@end


@interface BSTPhotosSelectionViewController : UICollectionViewController

@property (nonatomic, weak) id<BSTPhotosSelectionViewControllerDelegate> delegate;

- (void)updateContent;

@end
