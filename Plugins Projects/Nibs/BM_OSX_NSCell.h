#import <Foundation/Foundation.h>

typedef enum
{
	BM_OSX_NSNoImage=0,
	BM_OSX_NSImageOnly=1,
	BM_OSX_NSImageLeft=2,
	BM_OSX_NSImageRight=3,
	BM_OSX_NSImageBelow=4,
	BM_OSX_NSImageAbove=5,
	BM_OSX_NSImageOverlaps=6,
} BM_OSX_NSCellImagePosition;

@interface BM_OSX_NSCell : NSObject
{
	id _objectValue;
	id _titleOrAttributedTitle;
}

- (id) initWithCoder:(NSCoder *) inCoder;

- (NSString *) stringValue;

@end
