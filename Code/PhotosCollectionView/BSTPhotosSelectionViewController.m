//
//  BSTPhotosSelectionViewController.m
//  BST Kicks
//
//  Created by fantom on 2/2/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

@import UIKit;
@import Photos;

#import "NSIndexSet+Convenience.h"
#import "UICollectionView+Convenience.h"

#import "BSTPhotosSelectionViewController.h"
#import "BSTPhotosSelectionCell.h"

@interface BSTPhotosSelectionViewController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHFetchResult *assetsFetchResults;
@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic, strong) PHCachingImageManager *imageManager;

@property (nonatomic, strong) NSMutableDictionary *allExportSessions;
@property (nonatomic, strong) NSTimer *timer;

@property CGRect previousPreheatRect;

@end


@implementation BSTPhotosSelectionViewController

static NSString * const reuseIdentifier = @"BSTPhotosSelectionCell";
static CGSize AssetGridThumbnailSize;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    
    if (self) {
        self.imageManager = [[PHCachingImageManager alloc] init];
        [self resetCachedAssets];
        
        PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
        allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        
        PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
        
        self.assetsFetchResults = allPhotos;
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        self.allExportSessions = [NSMutableDictionary new];
    
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.backgroundColor = [UIColor colorWithRed:247.f/255.f green:247.f/255.f blue:248.f/255.f alpha:1];
        [self.collectionView registerClass:[BSTPhotosSelectionCell class] forCellWithReuseIdentifier:reuseIdentifier];
    }
    
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.allowsMultipleSelection = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Begin caching assets in and around collection view's visible rect.
    [self updateCachedAssets];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    for (AVAssetExportSession *session in [self.allExportSessions allValues]) {
        [session cancelExport];
    }
    
    [self.timer invalidate];
    self.timer = nil;
    self.allExportSessions = nil;
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Check if there are changes to the assets we are showing.
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
    if (collectionChanges == nil) {
        return;
    }
    
    /*
     Change notifications may be made on a background queue. Re-dispatch to the
     main queue before acting on the change as we'll be updating the UI.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get the new fetch result.
        self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
        
        UICollectionView *collectionView = self.collectionView;
        
        if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
            // Reload the collection view if the incremental diffs are not available
            [collectionView reloadData];
            
        } else {
            /*
             Tell the collection view to animate insertions and deletions if we
             have incremental diffs.
             */
            [collectionView reloadData];
//            [collectionView performBatchUpdates:^{
//                NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
//                if ([removedIndexes count] > 0) {
//                    [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                }
//                
//                NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
//                if ([insertedIndexes count] > 0) {
//                    [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                }
//                
//                NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
//                if ([changedIndexes count] > 0) {
//                    [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                }
//            } completion:NULL];
        }
        
        [self resetCachedAssets];
    });
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetsFetchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    BSTPhotosSelectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.representedAssetIdentifier = asset.localIdentifier;
    
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    
    cell.actionBlock = ^{
        [weakSelf.imageManager requestImageDataForAsset:asset
                                                options:nil
                                          resultHandler:^(NSData * _Nullable imageData,
                                                          NSString * _Nullable dataUTI,
                                                          UIImageOrientation orientation,
                                                          NSDictionary * _Nullable info) {
                                              NSString *photosId = [[asset.localIdentifier componentsSeparatedByString:@"/"] firstObject];
                                              NSString *fileExtension = [[[info[@"PHImageFileURLKey"] absoluteString] componentsSeparatedByString:@"."] lastObject];
                                              NSString *photosUrl = [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@&ext=%@", fileExtension, photosId, fileExtension];
                                              
                                              if (asset.mediaType == PHAssetMediaTypeImage) {
                                                  [weakSelf sendImageData:[NSURL URLWithString:photosUrl]];
                                              } else if (asset.mediaType == PHAssetMediaTypeVideo) {
                                                  weakCell.cellStatus = CellStatusDownloading;
                                                  [weakSelf compressVideoWithURL:[NSURL URLWithString:photosUrl] videoId:photosId atIndexPath:indexPath];
                                              }
        }];
    };
    // Request an image for the asset from the PHCachingImageManager.
    [self.imageManager requestImageForAsset:asset
                                 targetSize:AssetGridThumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  // Set the cell's thumbnail image if it's still showing the same asset.
                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                      cell.thumbnailImage = result;
                                  }
                              }];
    if (self.allExportSessions[indexPath]) {
        AVAssetExportSession *session = self.allExportSessions[indexPath];
        cell.selected = YES;
        cell.cellStatus = CellStatusDownloading;
        cell.progressBar.value = session.progress * 100;
        NSLog(@"session progress %f", session.progress);
    } else {
        cell.cellStatus = CellStatusRegular;
    }
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Update cached assets for the new visible area.
    [self updateCachedAssets];
}

#pragma mark Actions

- (void)sendImageData:(NSURL *)imageURL {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photosSelectionViewController:shouldSendImageWithUrl:)]) {
        [self.delegate photosSelectionViewController:self shouldSendImageWithUrl:imageURL];
    }
}

- (void)compressVideoWithURL:(NSURL *)inputURL videoId:(NSString *)videoID atIndexPath:(NSIndexPath *)indePath {
    if (self.allExportSessions[indePath]) {
        return;
    }
    NSString *appFile = [NSTemporaryDirectory() stringByAppendingFormat:@"%@.mov", videoID];

    NSURL *outputURL = [NSURL fileURLWithPath:appFile];
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:AVAssetExportPresetLowQuality];
    session.outputURL = outputURL;
    session.outputFileType = AVFileTypeQuickTimeMovie;
    
    __weak typeof(self) weakSelf = self;
    
    [session exportAsynchronouslyWithCompletionHandler:^(void) {
        if (session.status == AVAssetExportSessionStatusCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(photosSelectionViewController:shouldSendVideoWithUrl:)]) {
                    [weakSelf.delegate photosSelectionViewController:weakSelf shouldSendVideoWithUrl:outputURL];
                }
                
                [weakSelf.collectionView reloadItemsAtIndexPaths:@[indePath]];
            });
            
            [weakSelf.allExportSessions removeObjectForKey:indePath];
            
            if (![weakSelf.allExportSessions count]) {
                [weakSelf.timer invalidate];
                weakSelf.timer = nil;
            }
        }
    }];
    [self.allExportSessions setObject:session forKey:indePath];
    
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(checkProgress) userInfo:nil repeats:YES];
        [self.timer fire];
        
    }
}

- (void)checkProgress {
    [self.collectionView reloadItemsAtIndexPaths:[self.allExportSessions allKeys]];
}

- (void)updateContent {
    for (AVAssetExportSession *session in [self.allExportSessions allValues]) {
        [session cancelExport];
    }
    
    [self.timer invalidate];
    self.timer = nil;
    self.allExportSessions = [NSMutableDictionary new];
    
    [UIView performWithoutAnimation:^{
        [self.collectionView reloadData];
        [self.collectionViewLayout invalidateLayout];
        self.collectionView.contentOffset = CGPointMake(0, 0);
    }];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assets addObject:asset];
    }
    
    return assets;
}

@end
