#import "BM_OSX_NSButton.h"

@implementation BM_OSX_NSButton

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	//NSLog(@"Button Title: %@",[self title]);
	
	return self;
}

#pragma mark -

- (NSString *) title
{
	if ([_cell isKindOfClass:[BM_OSX_NSButtonCell class]]==YES)
	{
		return [_cell title];
	}
	
	return nil;
}

- (NSString *) alternateTitle
{
	if ([_cell isKindOfClass:[BM_OSX_NSButtonCell class]]==YES)
	{
		return [_cell alternateTitle];
	}

	return nil;
}

@end
