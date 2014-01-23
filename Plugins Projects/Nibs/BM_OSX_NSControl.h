#import "BM_OSX_NSView.h"

#import "BM_OSX_NSCell.h"

@interface BM_OSX_NSControl : BM_OSX_NSView
{
	id _cell;
}

- (id) cell;

- (void) setCell:(BM_OSX_NSCell *) cell;

- (NSString *) stringValue;

@end
