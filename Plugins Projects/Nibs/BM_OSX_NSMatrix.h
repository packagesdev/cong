#import "BM_OSX_NSControl.h"

@interface BM_OSX_NSMatrix : BM_OSX_NSControl
{
	NSMutableArray *_cells;
}

- (NSArray *) cells;

@end
