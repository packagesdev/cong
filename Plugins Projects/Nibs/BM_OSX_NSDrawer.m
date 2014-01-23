#import "BM_OSX_NSDrawer.h"

@implementation BM_OSX_NSDrawer

- (id) initWithCoder:(NSCoder *) inCoder
{	
	self=[super initWithCoder:inCoder];
	
	/*if ([inCoder allowsKeyedCoding]==YES)
	{
		[inCoder decodeObjectForKey:@"Content View"];
	}*/
	
	return self;
}

@end
