#import "BM_OSX_NSPopUpButtonCell.h"

@implementation BM_OSX_NSPopUpButtonCell

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_menu=[[inCoder decodeObjectForKey:@"NSMenu"] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[_menu release];
	
	[super dealloc];
}

#pragma mark -

- (BM_OSX_NSMenu *) menu
{
	return _menu;
}

@end
