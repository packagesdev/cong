#import "BM_OSX_NSButtonCell.h"
#import "BM_OSX_NSButtonImageSource.h"

@implementation BM_OSX_NSButtonCell

- (id) initWithCoder:(NSCoder *) inCoder
{
	self=[super initWithCoder:inCoder];
	
	if ([inCoder allowsKeyedCoding]==YES)
	{
		unsigned int flags,flags2;
		id tObject;
		
		_titleOrAttributedTitle=[[inCoder decodeObjectForKey:@"NSContents"] retain];
		
		_alternateTitle=[[inCoder decodeObjectForKey:@"NSAlternateContents"] retain];
		
		flags=[inCoder decodeIntForKey:@"NSButtonFlags"];
		
		_imagePosition=BM_OSX_NSNoImage;
		if((flags&0x00480000)==0x00400000)
			_imagePosition=BM_OSX_NSImageOnly;
		else if((flags&0x00480000)==0x00480000)
			_imagePosition=BM_OSX_NSImageOverlaps;
		else if((flags&0x00380000)==0x00380000)
			_imagePosition=BM_OSX_NSImageLeft;
		else if((flags&0x00380000)==0x00280000)
			_imagePosition=BM_OSX_NSImageRight;
		else if((flags&0x00380000)==0x00180000)
			_imagePosition=BM_OSX_NSImageBelow;
		else if((flags&0x00380000)==0x00080000)
			_imagePosition=BM_OSX_NSImageAbove;
		
		flags2=[inCoder decodeIntForKey:@"NSButtonFlags2"];
		
		_keyEquivalent=[[inCoder decodeObjectForKey:@"NSKeyEquivalent"] retain];
		_keyEquivalentModifierMask=flags2>>8;
		
		tObject=[inCoder decodeObjectForKey:@"NSAlternateImage"];
		
		if ([tObject isKindOfClass:[BM_OSX_NSButtonImageSource class]]==YES)
		{
			isSwitchOrRadioButton_=[tObject isSwitchOrRadioButton];
		}
	}
	
	return self;
}

- (void) dealloc
{
	[_keyEquivalent release];
	
	[_alternateTitle release];
	
	[super dealloc];
}

#pragma mark -

- (BM_OSX_NSCellImagePosition) imagePosition
{
	return _imagePosition;
}

- (NSString *) title
{
	if ([_titleOrAttributedTitle isKindOfClass:[NSAttributedString class]])
	{
		return [_titleOrAttributedTitle string];
	}
	else
	{
		return _titleOrAttributedTitle;
	}
}

- (NSString *) alternateTitle
{
	return _alternateTitle;
}

#pragma mark -

- (BOOL) isSwitchOrRadioButton
{
	return isSwitchOrRadioButton_;
}

@end
