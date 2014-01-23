#import "BM_OSX_NSMenuItem.h"

#import "BM_OSX_NSMenu.h"

@implementation BM_OSX_NSMenuItem

- (id) initWithCoder:(NSCoder *) inCoder
{
	if ([inCoder allowsKeyedCoding]==YES)
	{
		if ([inCoder decodeBoolForKey:@"NSIsSeparator"]==NO)
		{
			title_=[[inCoder decodeObjectForKey:@"NSTitle"] retain];
		}
	
		submenu_=[[inCoder decodeObjectForKey:@"NSSubmenu"] retain];
		
		_keyEquivalent=[[inCoder decodeObjectForKey:@"NSKeyEquiv"] retain];
		
		_keyEquivalentModifierMask=[inCoder decodeIntForKey:@"NSKeyEquivModMask"];
	}
	
	return self;
}

- (void) dealloc
{
	[submenu_ release];
	
	[title_ release];

	[super dealloc];
}

#pragma mark -

- (NSString *) title
{
	//NSLog(@"%@ %u %@",title_,_keyEquivalentModifierMask,_keyEquivalent);
	
	return [[title_ retain] autorelease];
}

- (BM_OSX_NSMenu *) submenu
{
	if ([submenu_ isKindOfClass:[BM_OSX_NSMenu class]]==YES)
	{
		return [[submenu_ retain] autorelease];
	}

	return nil;
}

#pragma mark -

- (void) show:(NSString *) inIndent
{
	if (title_==nil)
	{
		//NSLog(@"%@-----",inIndent);
	}
	else
	{
		//NSLog(@"%@%@",inIndent,title_);
		
		if (submenu_!=nil)
		{
			[submenu_ show:[inIndent stringByAppendingString:@"  "]];
		}
	}
}

@end
