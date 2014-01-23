#import "BM_OSX_NSControl.h"

@implementation BM_OSX_NSControl

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		[self setCell:[inCoder decodeObjectForKey:@"NSCell"]];
	}
	
	return self;
}

- (void) dealloc
{
	[_cell release];
	
	[super dealloc];
}

#pragma mark -

- (id) cell
{
	return [[_cell retain] autorelease];
}

- (void) setCell:(BM_OSX_NSCell *) cell
{
	cell=[cell retain];
	
	[_cell release];
	
	_cell=cell;
}

- (NSString *) stringValue
{
	if ([_cell isKindOfClass:[BM_OSX_NSCell class]]==YES)
	{
		return [_cell stringValue];
	}
	
	return @"";
}

@end
