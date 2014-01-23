#import "BM_OSX_UnarchiverDelegate.h"

#import "BM_OSX_ArchivedObject.h"

@implementation BM_OSX_UnarchiverDelegate

- (Class) unarchiver:(NSKeyedUnarchiver *) inUnarchiver cannotDecodeObjectOfClassName:(NSString *) inClassName originalClasses:(NSArray *) classNames
{
	//NSLog(@"%@",inClassName);
	
	return [BM_OSX_ArchivedObject class];
}

@end
