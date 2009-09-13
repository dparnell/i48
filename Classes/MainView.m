//
//  MainView.m
//  i48
//
//  Created by Daniel Parnell on 14/04/09.
//  Copyright Automagic Software Pty Ltd 2009. All rights reserved.
//

#import "MainView.h"

@implementation MainView

@synthesize image = _image;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	if(_image) {
		[_image drawInRect: self.bounds];
	} else {
		[super drawRect: rect];
	}
	
}


- (void)dealloc {
	[_image release];
	
    [super dealloc];
}

- (void) setImage:(UIImage *)img {
	[img retain];
	[_image release];
	
	_image = img;
	
	[self setNeedsDisplay];
}

@end
