#import "BM_OSX_NSMenu.h"

#import "BM_OSX_NSMenuItem.h"

@implementation BM_OSX_NSMenu

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super init];
    
    if ([inCoder allowsKeyedCoding]==YES)
	{
		internalName_=[[inCoder decodeObjectForKey:@"NSName"] copy];
	
		title_=[[inCoder decodeObjectForKey:@"NSTitle"] copy];
	
		items_=[[NSMutableArray alloc] initWithArray:[inCoder decodeObjectForKey:@"NSMenuItems"]];
	}
	
	return self;
}

- (void) dealloc
{
	[items_ release];

	[title_ release];
	
	[internalName_ release];
	
	[super dealloc];
}

#pragma mark -

- (NSString *) title
{
	return [[title_ retain] autorelease];
}

- (NSString *) name
{
	return [[internalName_ retain] autorelease];
}

- (NSArray *) itemArray
{
	return [[items_ retain] autorelease];
}

- (void) show:(NSString *) inIndent
{
	//NSLog(@"%@[%@]",inIndent,internalName_);
	
	for(BM_OSX_NSMenuItem * tMenuItem in items_)
	{
		[tMenuItem show:[inIndent stringByAppendingString:@"  "]];
	 }
}

@end
