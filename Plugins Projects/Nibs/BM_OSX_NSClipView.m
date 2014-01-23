#import "BM_OSX_NSClipView.h"

@implementation BM_OSX_NSClipView

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_docView=[[inCoder decodeObjectForKey:@"NSDocView"] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[_docView release];
	
	[super dealloc];
}

#pragma mark -

- (id) documentView
{
    return _docView;
}

@end
