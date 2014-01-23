#import "BM_OSX_NSMatrix.h"

@implementation BM_OSX_NSMatrix

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_cells=[[NSMutableArray alloc] initWithArray:[inCoder decodeObjectForKey:@"NSCells"]];
	}
	
	return self;
}

- (void) dealloc
{
	[_cells release];
	
	[super dealloc];
}

#pragma mark -

- (NSArray *) cells
{
	return [[_cells retain] autorelease];
}

@end

