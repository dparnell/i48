//
//  MainView.m
//  i48
//
//  Created by Daniel Parnell on 14/04/09.
//  Copyright Automagic Software Pty Ltd 2009. All rights reserved.
//

#import "MainView.h"

@implementation MainView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	if(_image) {
        // NSLog(@"bounds: %f %f %f %f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
        
		[_image drawInRect: self.bounds];
	} else {
		[super drawRect: rect];
	}
	
}



- (UIImage*) image {
    return _image;
}

- (void) setImage:(UIImage *)img {
	_image = img;
	
	[self setNeedsDisplay];
}

@end
