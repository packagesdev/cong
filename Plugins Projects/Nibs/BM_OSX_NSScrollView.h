#import "BM_OSX_NSView.h"

#import "BM_OSX_NSClipView.h"

@interface BM_OSX_NSScrollView : BM_OSX_NSView
{
    BM_OSX_NSClipView   *_clipView;
}

- (id) documentView;

- (BM_OSX_NSClipView *) contentView;

@end

