//
//  MainViewController.h
//  i48
//
//  Created by Daniel Parnell on 14/04/09.
//  Copyright Automagic Software Pty Ltd 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController {
	unsigned char* _display_buffer;
	
	CGContextRef lcdContext;

	NSThread* emulatorThread;
	BOOL fRunning;
	
	UIImageView* _lcd;
	
    UIImageView* _ann1;
    UIImageView* _ann2;
    UIImageView* _ann3;
    UIImageView* _ann4;
    UIImageView* _ann5;
    UIImageView* _ann6;
}

- (IBAction) buttonPressed:(UIButton*)sender;
- (IBAction) buttonReleased:(UIButton*)sender;

@property(nonatomic,retain) IBOutlet UIImageView* lcd;

@property(nonatomic,retain) IBOutlet UIImageView* ann1;
@property(nonatomic,retain) IBOutlet UIImageView* ann2;
@property(nonatomic,retain) IBOutlet UIImageView* ann3;
@property(nonatomic,retain) IBOutlet UIImageView* ann4;
@property(nonatomic,retain) IBOutlet UIImageView* ann5;
@property(nonatomic,retain) IBOutlet UIImageView* ann6;

@end
