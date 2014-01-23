#import "BM_OSX_NSView.h"

@interface BM_OSX_NSClipView : BM_OSX_NSView
{
    BM_OSX_NSView *_docView;
}

- (id) documentView;

@end
