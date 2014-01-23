#import "BM_OSX_NSIBObjectData.h"

#import "BM_OSX_NSMenu.h"

#import "BM_OSX_NSView.h"

#import "BM_OSX_NSWindowTemplate.h"

@implementation BM_OSX_NSIBObjectData

- (id) initWithCoder:(NSCoder *) inCoder
{
	if ([inCoder allowsKeyedCoding]==YES)
	{
		fileOwner_=[[inCoder decodeObjectForKey:@"NSRoot"] retain];
	
		keys_=[[inCoder decodeObjectForKey:@"NSObjectsKeys"] retain];
	
		objects_=[[inCoder decodeObjectForKey:@"NSObjectsValues"] retain];
	}
	
    return self;
}

- (void) dealloc
{
	[objects_ release];
	
	[keys_ release];
	
	[fileOwner_ release];

	[super dealloc];
}

#pragma mark -

- (NSArray *) topLevelObjects
{
    NSUInteger i,tCount;
    NSMutableArray * tMutableArray;
    
	tCount=[objects_ count];
	
	tMutableArray=[NSMutableArray array];
	
    for(i=0; i<tCount; i++)
	{
        id  tObject;
		
		tObject= [objects_ objectAtIndex:i];
        
        if (tObject==fileOwner_)
		{
            id tKey;
			
			tKey=[keys_ objectAtIndex:i];
			
			if (tKey!=fileOwner_)
			{
				[tMutableArray addObject:tKey];
			}
		}
	}
	
    return tMutableArray;
}

- (NSArray *) allMenus
{
	NSMutableArray * tMutableArray=nil;
	NSUInteger tCount;
	NSArray * topLevelObjects;
	
	topLevelObjects=[self topLevelObjects];
	
	tCount=[topLevelObjects count];
	
	if (tCount>0)
	{
		tMutableArray=[NSMutableArray array];
	
		if (tMutableArray!=nil)
		{
			for(NSObject * tObject in topLevelObjects)
			{
				if ([tObject isKindOfClass:[BM_OSX_NSMenu class]]==YES)
				{
					[tMutableArray addObject:tObject];
				}
			}
		}
	}
	
	return tMutableArray;
}

- (NSArray *) allViews
{
	NSMutableArray * tMutableArray=nil;
	NSUInteger tCount;
	NSArray * topLevelObjects;
	
	topLevelObjects=[self topLevelObjects];
	
	tCount=[topLevelObjects count];
	
	if (tCount>0)
	{
		tMutableArray=[NSMutableArray array];
		
		if (tMutableArray!=nil)
		{
			for(NSObject * tObject in topLevelObjects)
			{
				if ([tObject isKindOfClass:[BM_OSX_NSView class]]==YES)
				{
					[tMutableArray addObject:tObject];
				}
			}
		}
	}
	
	return tMutableArray;
}

- (NSArray *) allWindowViews
{
	NSMutableArray * tMutableArray=nil;
	NSUInteger tCount;
	NSArray * topLevelObjects;
	
	topLevelObjects=[self topLevelObjects];
	
	tCount=[topLevelObjects count];
	
	if (tCount>0)
	{
		tMutableArray=[NSMutableArray array];
		
		if (tMutableArray!=nil)
		{
			for(NSObject * tObject in topLevelObjects)
            {	
				if ([tObject isKindOfClass:[BM_OSX_NSWindowTemplate class]]==YES)
				{
					[tMutableArray addObject:[(BM_OSX_NSWindowTemplate *) tObject contentView]];
				}
			}
		}
	}
	
	return tMutableArray;
}

@end
