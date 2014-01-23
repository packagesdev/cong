#import "BM_OSX_NSTabView.h"

@implementation BM_OSX_NSTabView

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_tabViewItems=[[NSMutableArray alloc] initWithArray:[inCoder decodeObjectForKey:@"NSTabViewItems"]];
	}
	
	return self;
}

- (void) dealloc
{
	[_tabViewItems release];
	
	[super dealloc];
}

#pragma mark -

- (NSArray *) tabViewItems
{
	return [[_tabViewItems retain] autorelease];
}

@end
