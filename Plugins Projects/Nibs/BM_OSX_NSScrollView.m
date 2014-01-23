#import "BM_OSX_NSScrollView.h"

@implementation BM_OSX_NSScrollView

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super init];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_clipView=[[inCoder decodeObjectForKey:@"NSContentView"] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[_clipView release];
	
	[super dealloc];
}

#pragma mark -

- (id) documentView
{
    return [_clipView documentView];
}

- (BM_OSX_NSClipView *) contentView
{
    return _clipView;
}

@end
