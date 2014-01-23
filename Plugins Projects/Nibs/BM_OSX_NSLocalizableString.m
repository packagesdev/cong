#import "BM_OSX_NSLocalizableString.h"

@implementation BM_OSX_NSLocalizableString

- (id) initWithCoder:(NSCoder *) inCoder
{
	if ([inCoder allowsKeyedCoding]==YES)
	{
        _developmentLanguageString=[[inCoder decodeObjectForKey:@"NSDev"] retain];
        
        _stringsFileKey=[[inCoder decodeObjectForKey:@"NSKey"] retain];
	}
	
	return self;
}

- (void) dealloc
{
    [_developmentLanguageString release];
    
    [_stringsFileKey release];

    [super dealloc];
}

#pragma mark -

- (unichar) characterAtIndex:(NSUInteger)inIndex
{
    return [_developmentLanguageString characterAtIndex:inIndex];
}

- (NSUInteger) length
{
    return 0;
    
    //return [_developmentLanguageString length];
}

@end
