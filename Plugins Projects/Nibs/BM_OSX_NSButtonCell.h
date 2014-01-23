#import "BM_OSX_NSActionCell.h"

@interface BM_OSX_NSButtonCell : BM_OSX_NSActionCell
{
	NSString * _alternateTitle;
	
	int       _imagePosition;
	
	NSString *_keyEquivalent;
	unsigned  _keyEquivalentModifierMask;
	
	BOOL isSwitchOrRadioButton_;
}

- (BM_OSX_NSCellImagePosition) imagePosition;

- (NSString *) title;

- (NSString *) alternateTitle;

- (BOOL) isSwitchOrRadioButton;

@end
