#import "BM_OSX_NSBox.h"

@implementation BM_OSX_NSBox

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
        _titleCell=[[inCoder decodeObjectForKey:@"NSTitleCell"] retain];
	}
	
	return self;
}

#pragma mark -

- (NSString *) title
{
    return [_titleCell stringValue];
}


@end
