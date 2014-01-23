#import "BM_OSX_NSButtonCell.h"

#import "BM_OSX_NSMenu.h"

@interface BM_OSX_NSPopUpButtonCell : BM_OSX_NSButtonCell
{
	BM_OSX_NSMenu * _menu;
}

- (BM_OSX_NSMenu *) menu;

@end
