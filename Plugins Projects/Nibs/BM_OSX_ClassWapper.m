#import "BM_OSX_ClassWapper.h"

#import "BM_OSX_ArchivedObject.h"

@implementation BM_OSX_ClassWapper

- (id) initWithCoder:(NSCoder *) inCoder
{
	//NSLog(@"Class: %@",[inCoder decodeObjectForKey:@"NSClassName"]);
	
	[self autorelease];
	
	return [[BM_OSX_ArchivedObject alloc] initWithCoder:inCoder];
	
	//return self;
}

/*+ (id) allocWithKeyedUnarchiver:(NSKeyedUnarchiver *) inUnarchiver
{
	NSLog(@"toto: %@",[inUnarchiver decodeObjectForKey:@"NSClassName"]);
	
	return nil;
}*/

@end
