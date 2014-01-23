#import "BM_OSX_NSTableColumn.h"

@implementation BM_OSX_NSTableColumn

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super init];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		//NSLog(@"Table Column:");
		
		[inCoder decodeObjectForKey:@"NSHeaderCell"];
	}
	
	return self;
}


@end
