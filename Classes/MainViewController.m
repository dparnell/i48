//
//  MainViewController.m
//  i48
//
//  Created by Daniel Parnell on 14/04/09.
//  Copyright Automagic Software Pty Ltd 2009. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"
#import "hp48.h"
#import "global.h"
#import "hp48_emu.h"
#import "device.h"

#define EMULATE_SOUND
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

static MainViewController* instance = nil;

@implementation MainViewController

@synthesize lcd = _lcd;

@synthesize ann1 = _ann1;
@synthesize ann2 = _ann2;
@synthesize ann3 = _ann3;
@synthesize ann4 = _ann4;
@synthesize ann5 = _ann5;
@synthesize ann6 = _ann6;

char  *progname = "i48";
struct saturn_t saturn;
int	    verbose = 1;
int	    quiet = 0;
int     useSerial = 0;
char   *serialLine = nil;
int     initialize = 0;
int     resetOnStartup = 0;
char   *romFileName = "rom";
char   *homeDirectory = nil;

static BOOL fKeyInterrupt;
static BOOL dirty = NO;
BOOL fRunning = NO;
NSThread* emulatorThread = nil;

static unsigned char * display_buffer = nil;

int GetEvent() {
	if(!fRunning) {
        NSLog(@"Stopping emulation");
        
		exit_emulator();
        emulatorThread = nil;
		[NSThread exit];
	}
	
	if(fKeyInterrupt) {
		fKeyInterrupt = NO;
		do_kbd_int();
		
		return 1;
	}
	
	return 0;
}

void refresh_display() {
    dirty = YES;
}

void pause_emulation() {
	if(dirty) {
        update_display();
		dirty = NO;
		// NSLog(@"dirty");
	}
	
	[NSThread sleepForTimeInterval: 0.02];
	got_alarm = 1;
}

display_t display;
#define DISP_COLS 131
#define DISP_ROWS 64

void init_display() {	
	display.on = (int)(saturn.disp_io & 0x8) >> 3;
	
	display.disp_start = (saturn.disp_addr & 0xffffe);
	display.offset = (saturn.disp_io & 0x7);
	
	display.lines = (saturn.line_count & 0x3f);
	if (display.lines == 0) {
		display.lines = 63;
	}
	
	if (display.offset > 3) {
		display.nibs_per_line = (NIBBLES_PER_ROW+saturn.line_offset+2) & 0xfff;
	} else {
		display.nibs_per_line = (NIBBLES_PER_ROW+saturn.line_offset) & 0xfff;
	}
	
	display.disp_end = display.disp_start + (display.nibs_per_line * (display.lines + 1));

	display.menu_start = saturn.menu_addr;
	display.menu_end = saturn.menu_addr + 0x110;
	
	display.contrast = saturn.contrast_ctrl;
	display.contrast |= ((saturn.disp_test & 0x1) << 4);
	
	display.annunc = saturn.annunc;
}

void init_annunc() {
	got_alarm = 1;
}

- (void) draw_annunc:(id)dummy {
//	NSLog(@"display.annunc = %d", display.annunc);
	
	[_ann1 setHidden: (display.annunc & ANN_LEFT)!=ANN_LEFT];
	[_ann2 setHidden: (display.annunc & ANN_RIGHT)!=ANN_RIGHT];
	[_ann3 setHidden: (display.annunc & ANN_ALPHA)!=ANN_ALPHA];
	[_ann4 setHidden: (display.annunc & ANN_BATTERY)!=ANN_BATTERY];
	[_ann5 setHidden: (display.annunc & ANN_BUSY)!=ANN_BUSY];
	[_ann6 setHidden: (display.annunc & ANN_IO)!=ANN_IO];
}

void draw_annunc() {
    if(stop_emulation == 0) {
        [instance performSelectorOnMainThread: @selector(draw_annunc:) withObject: nil waitUntilDone: YES];
    }
}

#define BACKGROUND_PIXEL 0x5CDDCA
#define FOREGROUND_PIXEL 0x000000

/*
 float fgColor[] = {0.0f, 0.0f, 0.0f};
 float bgColor[] = {202.0f/255.0f, 221.0f/255.0f, 92.0f/255.0f};

 */
static void lcd_display_nibbles(int id, int x, int y) {
//	NSLog(@"%d %d %d", x, y, id);
	unsigned char mask;
	int i, limit;
	
	if(display_buffer && x<=129) {
		unsigned int* p = (unsigned int*)(display_buffer + (y*(DISP_COLS+2)*4)+x*4);
		
		if(x<128) {
			limit = 4;
		} else {
			limit = 3;
		}
		mask = 0x01;
		for (i = limit; i>0; i--) {
			
			if (id & mask) {
				*p = FOREGROUND_PIXEL;
			} else {
				*p = BACKGROUND_PIXEL;
			}
			
			p++;
			mask = mask << 1;
		}
	}	
}

static inline void
draw_nibble(int c, int r, int val)
{
	int x, y;
	
	x = (c * 4)+1;
	y = r+1;
	val &= 0x0f;
	lcd_display_nibbles(val, x, y);
}

static inline void
draw_row(long addr, int row)
{
	int i, v;
	int line_length;
	
	line_length = NIBBLES_PER_ROW;
	if ((display.offset > 3) && (row <= display.lines))
		line_length += 2;
	for (i = 0; i < line_length; i++) {
		v = read_nibble(addr + i);
		draw_nibble(i, row, v);
	}
	
}

- (void) update_display {
	int i, j;
	long addr;
	static int old_offset = -1;
	static int old_lines = -1;
	if (display.on) {
		BOOL redraw_needed = NO;
		
		addr = display.disp_start;
		if (display.offset != old_offset) {
			redraw_needed = YES;
			old_offset = display.offset;
		}
		if (display.lines != old_lines) {
			redraw_needed = YES;
			old_lines = display.lines;
		}
		
		if(redraw_needed) {
			for (i = 0; i <= display.lines; i++) {
				draw_row(addr, i);
				addr += display.nibs_per_line;
			}
			if (i < DISP_ROWS) {
				addr = display.menu_start;
				for (; i < DISP_ROWS; i++) {
					draw_row(addr, i);
					addr += NIBBLES_PER_ROW;
				}
			}
		}
	} else {
		for (i = 0; i < 64; i++) {
			for (j = 0; j < NIBBLES_PER_ROW; j++) {
				draw_nibble(j, i, 0x00);
			}
		}
	}
	
	dirty = NO;
	
	CGImageRef img = CGBitmapContextCreateImage(lcdContext);
//	NSLog(@"img = %p", img);
	_lcd.image = [UIImage imageWithCGImage: img];
    CGImageRelease(img);
}

void update_display() {
    if(stop_emulation == 0) {
        [instance performSelectorOnMainThread: @selector(update_display) withObject: nil waitUntilDone: YES];
    }
}

void menu_draw_nibble(word_20 addr, word_4 val) {
	long offset;
	int x, y;
//	NSLog(@"menu_draw_nibble");
	
	offset = (addr - display.menu_start);
    x = offset % NIBBLES_PER_ROW;
    y = display.lines + (int)(offset / NIBBLES_PER_ROW) + 1;
	dirty = YES;
	draw_nibble(x, y, val);
}

void disp_draw_nibble(word_20 addr, word_4 val) {	
	long offset;
	int x, y;	
//	NSLog(@"disp_draw_nibble");
	
	offset = (addr - display.disp_start);
	x = offset % display.nibs_per_line;
	if (x < 0 || x > 35)
		return;
	if (display.nibs_per_line != 0) {
		y = (int)offset / display.nibs_per_line;
		if (y < 0 || y > 63)
			return;
		dirty = YES;
		draw_nibble(x, y, val);
	} else {
		dirty = YES;
		for (y = 0; y < display.lines; y++) {
			draw_nibble(x, y, val);
		}
	}
}

- (void) emulatorThread:(id)dummy {		
	BOOL limit_speed;
	
	@autoreleasepool {
		NSLog(@"starting emulation thread");
        NSNumber* limit_pref = [[NSUserDefaults standardUserDefaults] objectForKey: @"limit_speed"];
        if(limit_pref) {
            limit_speed = [limit_pref boolValue];
        } else {
            limit_speed = YES;
        }
	}
//	NSLog(@"calling emulate");
    fRunning = YES;
    fKeyInterrupt = NO;
    dirty = YES;
    update_display();
    draw_annunc();
    
	emulate(limit_speed);
    do_shutdown();
    
    exit_emulator();
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {		
    }
    return self;
}

#ifdef EMULATE_SOUND
#define BUFFER_SAMPLE_SIZE 1024
#define BUFFER_SIZE (BUFFER_SAMPLE_SIZE * sizeof(short))
#define BUFFER_COUNT 4
#define SAMPLE_RATE 8000

static AudioQueueRef audioQueue = 0;
static BOOL currentSpeakerValue = NO;

void AudioQueueCallback(void* inUserData, AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer) {
    short* pBuffer = inBuffer->mAudioData;
    UInt32 bytes = inBuffer->mAudioDataBytesCapacity;
    int count = bytes / sizeof(short);
    int countdown;
    if(device.speaker_transition_count == 0) {
        countdown = inBuffer->mAudioDataBytesCapacity * 2;
    } else {
        countdown = count / device.speaker_transition_count;
    }
    int counter = countdown;
    
    for(int i=0; i<count; i++) {
        if(counter-- == 0) {
            currentSpeakerValue = !currentSpeakerValue;
            counter = countdown;
        }
        short value = currentSpeakerValue ? 0x7fff : 0xffff;
        pBuffer[i] = value;
    }

    inBuffer->mAudioDataByteSize = bytes;
	OSStatus err = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
	if(err) {
		NSLog(@"AudioQueueEnqueueBuffer failed - %d", err);
	}

    //NSLog(@"HERE: %p - %d - %d", inBuffer, count, device.speaker_transition_count);
    device.speaker_transition_count = 0;
}
#endif

- (void) startEmulation:(id)dummy {
    if(emulatorThread == nil) {
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if([[[NSUserDefaults standardUserDefaults] objectForKey: @"reset"] boolValue]) {
            [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: NO] forKey: @"reset"];
            NSLog(@"Removing HP48 processor state file");
            [[NSFileManager defaultManager] removeItemAtPath: [NSString stringWithFormat: @"%s/hp48", homeDirectory] error: nil];
            initialize = 1;
//            saturn.PC = 0;
//            do_reset();
        }

        init_emulator();
        init_active_stuff();
//        resetOnStartup = YES;
        
        emulatorThread = [[NSThread alloc] initWithTarget: self selector: @selector(emulatorThread:) object: nil];
        [emulatorThread setName: @"Emulator Thread"];
        [emulatorThread start];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"click" ofType:@"aiff"];
    if(path) {
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &soundID);
    } else {
        soundID = 0;
    }
	
	instance = self;
	memset(&saturn, 0, sizeof(saturn));
		
	_display_buffer = malloc((DISP_COLS+2)*4*(DISP_ROWS+2));
	
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();

	lcdContext = CGBitmapContextCreate(_display_buffer, DISP_COLS+2, DISP_ROWS+2, 8, (DISP_COLS+2)*4, colorspace, kCGImageAlphaNoneSkipLast);
	CGColorSpaceRelease(colorspace);
	CGContextSetShouldAntialias(lcdContext, NO);
	display_buffer = CGBitmapContextGetData(lcdContext);

	for(int i=0; i<(DISP_ROWS+2)*(DISP_COLS+2); i++) {
		((unsigned int*)display_buffer)[i] = BACKGROUND_PIXEL;
	}
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	homeDirectory = strdup([documentsDirectory cStringUsingEncoding: NSUTF8StringEncoding]);
	
	romFileName = (char*)[[[NSBundle mainBundle] pathForResource: @"hp48" ofType: @"rom"] cStringUsingEncoding: NSUTF8StringEncoding];

#ifdef EMULATE_SOUND	
	// start up the sound support
    NSError* error = NULL;
    
    if([[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &error]) {
        NSLog(@"Set audio session category");
        
        OSStatus err = noErr;
        // Setup the audio device.
        AudioStreamBasicDescription deviceFormat;
        deviceFormat.mSampleRate = SAMPLE_RATE;
        deviceFormat.mFormatID = kAudioFormatLinearPCM;
        deviceFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        deviceFormat.mBitsPerChannel = 16;
        deviceFormat.mChannelsPerFrame = 1;
        deviceFormat.mBytesPerFrame = sizeof(short) * deviceFormat.mChannelsPerFrame;
        deviceFormat.mFramesPerPacket = 1;
        deviceFormat.mBytesPerPacket = deviceFormat.mBytesPerFrame * deviceFormat.mFramesPerPacket;
        deviceFormat.mReserved = 0;
        
        NSLog(@"Allocating audio output queue...");
        // Create a new output AudioQueue for the device.
        err = AudioQueueNewOutput(&deviceFormat, AudioQueueCallback, NULL,
                                  CFRunLoopGetCurrent(), kCFRunLoopCommonModes,
                                  0, &audioQueue);
        if(err == noErr) {
            NSLog(@"Allocated audio output queue successfully");

            // Allocate buffers for the AudioQueue, and pre-fill them.
            for (int i = 0; i < BUFFER_COUNT; ++i) {
                AudioQueueBufferRef mBuffer;
                err = AudioQueueAllocateBuffer(audioQueue, BUFFER_SIZE, &mBuffer);
                if (err != noErr) break;
                NSLog(@"Allocated audio buffer %d successfully", i + 1);
                AudioQueueCallback(NULL, audioQueue, mBuffer);
            }
            
            err = AudioQueueStart(audioQueue, nil);
            if(err == noErr) {
                NSLog(@"Started audio queue");
            } else {
                NSLog(@"Failed to start audio queue: %d", (int)err);
            }
            fRunning = YES;
        } else {
            NSLog(@"Audio queue allocation failed: %d", (int)err);
        }
    } else {
        NSLog(@"Unable to set audio session category: %@", error);
    }
#endif
		
	// connect up the event handlers
	for(UIView* v in [self.view subviews]) {
		if([v isKindOfClass: [UIButton class]]) {
			UIButton* b = (UIButton*)v;
			
			b.showsTouchWhenHighlighted = YES;
			[b addTarget: self action: @selector(buttonPressed:) forControlEvents: UIControlEventTouchDown];
			[b addTarget: self action: @selector(buttonReleased:) forControlEvents: UIControlEventTouchUpInside];
		}
	}

    [self startEmulation: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(timeToDie:) name: UIApplicationWillTerminateNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(timeToDie:) name: UIApplicationWillResignActiveNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startEmulation:) name: UIApplicationDidBecomeActiveNotification object: nil];
}

- (void)timeToDie:(id)dummy {
    NSLog(@"Shutting the emulation down...");
	while(emulatorThread && ![emulatorThread isFinished]) {
        fRunning = NO;
        stop_emulation = 1;
        got_alarm = 1;
		[NSThread sleepForTimeInterval: 0.1];
	}
    NSLog(@"Emulation stopped!");
    emulatorThread = nil;
}

- (BOOL)shouldAutorotate {
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
	instance = nil;
    if(soundID) {
        AudioServicesDisposeSystemSoundID(soundID);
	}
}

- (IBAction) buttonPressed:(UIButton*)sender {
	int code = [[sender titleForState: UIControlStateDisabled] intValue];
//	NSLog(@"button %@ - %d pressed", [sender titleForState: UIControlStateNormal], code);
	
	int i, r, c;
	
    if(soundID) {
        NSNumber* play_click = [[NSUserDefaults standardUserDefaults] objectForKey: @"key_click"];

        if([play_click boolValue]) {
            AudioServicesPlaySystemSound(soundID);
        }
    }
	
	if (code == 0x8000) {
		for (i = 0; i < 9; i++) {
			saturn.keybuf.rows[i] |= 0x8000;
		}
		fKeyInterrupt = YES;
	} else {
		r = code >> 4;
		c = 1 << (code & 0xf);
		if ((saturn.keybuf.rows[r] & c) == 0) {
			if (saturn.kbd_ien) {
				fKeyInterrupt = YES;
			}
			if ((saturn.keybuf.rows[r] & c)) {
				NSLog(@"bug");
//				fprintf(stderr, "bug\n");
			}
			saturn.keybuf.rows[r] |= c;
		}
	}
	
    got_alarm = 1;
}

- (IBAction) buttonReleased:(UIButton*)sender {
	int code = [[sender titleForState: UIControlStateDisabled] intValue];
//	NSLog(@"button %@ - %d released", [sender titleForState: UIControlStateNormal], code);
	
	if (code == 0x8000) {
		int i;
		for (i = 0; i < 9; i++)
			saturn.keybuf.rows[i] &= ~0x8000;
	} else {
		int r, c;
		r = code >> 4;
		c = 1 << (code & 0xf);
		saturn.keybuf.rows[r] &= ~c;
	}
	
    got_alarm = 1;
}


@end
