#import "BM_OSX_NSTableView.h"

@implementation BM_OSX_NSTableView

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		[inCoder decodeObjectForKey:@"NSHeaderView"];
		
		[inCoder decodeObjectForKey:@"NSTableColumns"];
	}
	
	return self;
}

@end
