#import "BM_OSX_NSButtonImageSource.h"

@implementation BM_OSX_NSButtonImageSource

- (id) initWithCoder:(NSCoder *) inCoder
{
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_imageName=[[inCoder decodeObjectForKey:@"NSImageName"] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[_imageName release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) isSwitchOrRadioButton
{
	return ([_imageName isEqualToString:@"NSSwitch"]==YES ||
			[_imageName isEqualToString:@"NSRadioButton"]==YES);
}

@end
