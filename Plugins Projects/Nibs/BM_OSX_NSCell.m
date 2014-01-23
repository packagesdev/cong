#import "BM_OSX_NSCell.h"

@implementation BM_OSX_NSCell

- (id) initWithCoder:(NSCoder *) inCoder
{
	if ([inCoder allowsKeyedCoding]==YES)
	{
		_objectValue=[[inCoder decodeObjectForKey:@"NSContents"] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[_titleOrAttributedTitle release];
	
	[_objectValue release];
	
	[super dealloc];
}


#pragma mark -

- (NSString *) title
{
    return _titleOrAttributedTitle;
}

- (NSString *) stringValue
{
	if ([_objectValue isKindOfClass:[NSAttributedString class]])
	{
		return [_objectValue string];
	}
	else if([_objectValue isKindOfClass:[NSString class]])
	{
		return _objectValue;
	}
	
    return [_objectValue descriptionWithLocale:[NSLocale currentLocale]];
}

@end
