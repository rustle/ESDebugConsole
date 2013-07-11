//
//  ESDebugConsole+iOS_GUI.h
//
//  Copyright Doug Russell 2012. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ESDebugConsole.h"

@interface ESDebugConsole (iOS_GUI)

/**
 * Gesture recognizer will by default be a rotation gesture recognizer attached to the window
 * If you set your own it's target must be [ESDebugConsole sharedDebugConsole] with action gestureRecognized:
 */
@property (nonatomic) UIGestureRecognizer *gestureRecognizer;
/**
 * Used by view controllers when displayed in UIPopoverController
 */
@property (nonatomic) CGSize consoleSizeInPopover;

- (void)showFromView:(UIView *)view;

@end

@interface ESDebugConsole (iOS_GUI_Private)
@property (nonatomic) UIWindow *window;
@property (nonatomic) UIPopoverController *popoverController;
@property (nonatomic) UINavigationController *navigationController;
- (void)iOSInit;
- (void)iOSDealloc;
@end