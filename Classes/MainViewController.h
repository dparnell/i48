//
//  MainViewController.h
//  i48
//
//  Created by Daniel Parnell on 14/04/09.
//  Copyright Automagic Software Pty Ltd 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainView.h"
#import <AudioToolbox/AudioToolbox.h>

@interface MainViewController : UIViewController {
	unsigned char* _display_buffer;

	SystemSoundID soundID;
	CGContextRef lcdContext;

	MainView* _lcd;
	
    UIImageView* _ann1;
    UIImageView* _ann2;
    UIImageView* _ann3;
    UIImageView* _ann4;
    UIImageView* _ann5;
    UIImageView* _ann6;	
}

- (IBAction) buttonPressed:(UIButton*)sender;
- (IBAction) buttonReleased:(UIButton*)sender;

@property(nonatomic,strong) IBOutlet MainView* lcd;

@property(nonatomic,strong) IBOutlet UIImageView* ann1;
@property(nonatomic,strong) IBOutlet UIImageView* ann2;
@property(nonatomic,strong) IBOutlet UIImageView* ann3;
@property(nonatomic,strong) IBOutlet UIImageView* ann4;
@property(nonatomic,strong) IBOutlet UIImageView* ann5;
@property(nonatomic,strong) IBOutlet UIImageView* ann6;

@end
