#import "BM_OSX_NSWindow.h"

@implementation BM_OSX_NSWindow

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
