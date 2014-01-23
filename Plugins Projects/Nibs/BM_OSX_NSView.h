#import "BM_OSX_NSResponder.h"

#import "BM_OSX_NSMenu.h"

@interface BM_OSX_NSView : BM_OSX_NSResponder
{
	BM_OSX_NSMenu * _menu;
	
	NSMutableArray * _subviews;
}

- (id) initWithCoder:(NSCoder *) inCoder;

- (id) initWithFrame:(NSRect) inFrame;

- (NSArray *) subviews;

@end
