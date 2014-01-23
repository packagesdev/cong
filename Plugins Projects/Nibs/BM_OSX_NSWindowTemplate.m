#import "BM_OSX_NSWindowTemplate.h"

@implementation BM_OSX_NSWindowTemplate

- (id) initWithCoder:(NSCoder *) inCoder
{	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		contentView_=[[inCoder decodeObjectForKey:@"NSWindowView"] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[contentView_ release];
	
	[super dealloc];
}

#pragma mark -

- (BM_OSX_NSView *) contentView
{
	return [[contentView_ retain] autorelease];
}

@end
