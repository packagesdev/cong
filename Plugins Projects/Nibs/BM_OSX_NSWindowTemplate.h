#import <Foundation/Foundation.h>

#import "BM_OSX_NSView.h"

@interface BM_OSX_NSWindowTemplate : NSObject
{
	BM_OSX_NSView * contentView_;
}

- (BM_OSX_NSView *) contentView;

@end
