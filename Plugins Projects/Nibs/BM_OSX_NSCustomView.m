#import "BM_OSX_NSCustomView.h"

#import "BMNibKeyedUnarchiver.h"

@implementation BM_OSX_NSCustomView

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
    
    if ([inCoder allowsKeyedCoding]==YES)
	{
		NSString * tClassName;
		Class tClass;
		
		tClassName = [(NSKeyedUnarchiver *) inCoder decodeObjectForKey:@"NSClassName"];
		
		tClass = NSClassFromString(tClassName);
		
		if (tClass == nil)
		{
			//NSLog(@"NSCustomView unknown class %@", className);
			
			return self;
		}
		else
		{
			tClass=[[BMNibKeyedUnarchiver supportedClasses] objectForKey:tClassName];
			
			if (tClass!=nil)
			{
				NSKeyedUnarchiver * tKeyedUnarchiver;
				id tView;
				NSRect tFrame=NSZeroRect;
				
				tKeyedUnarchiver= (NSKeyedUnarchiver *) inCoder;
			
				tView=[[tClass alloc] initWithFrame:tFrame];
				
				[((BM_OSX_NSView *)tView)->_subviews addObjectsFromArray:[tKeyedUnarchiver decodeObjectForKey:@"NSSubviews"]];
				
				[_subviews removeAllObjects];
				
				[self release];
			
				return tView;
			}
		}
	}
	
	return self;
}

@end
