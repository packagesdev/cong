#import "BM_OSX_NSView.h"

@implementation BM_OSX_NSView

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_subviews=[NSMutableArray new];
		
		[_subviews addObjectsFromArray:[inCoder decodeObjectForKey:@"NSSubviews"]];
	}
	
	return self;
}

- (id) initWithFrame:(NSRect) inFrame
{
	_subviews=[NSMutableArray new];
	
	return self;
}

- (void) dealloc
{
	[_menu release];
	
	[_subviews release];
	
	[super dealloc];
}

#pragma mark -

- (NSArray *) subviews
{
	return [[_subviews copy] autorelease];
}


@end
