#import "BM_OSX_NSTabViewItem.h"

@implementation BM_OSX_NSTabViewItem

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super init];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_label=[[inCoder decodeObjectForKey:@"NSLabel"] retain];
		
		_view=[[inCoder decodeObjectForKey:@"NSView"] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[_label release];
	
	[_view release];
	
	[super dealloc];
}

#pragma mark -

- (id) view
{
	return [[_view retain] autorelease];
}

- (NSString *) label
{
	return [[_label retain] autorelease];
}

@end
