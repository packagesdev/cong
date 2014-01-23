#import <Foundation/Foundation.h>

#import "BM_OSX_NSView.h"

@interface BM_OSX_NSTabViewItem : NSObject
{
	NSString		*_label;			// the label
	
    BM_OSX_NSView		*_view;	
}

- (id) view;

- (NSString *) label;

@end
