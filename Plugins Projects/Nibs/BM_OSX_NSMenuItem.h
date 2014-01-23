#import <Foundation/Foundation.h>

@class BM_OSX_NSMenu;

@interface BM_OSX_NSMenuItem : NSObject
{
	BM_OSX_NSMenu * submenu_;
	
	NSString * title_;
	
	NSString *_keyEquivalent;
	
	unsigned  _keyEquivalentModifierMask;
}

- (NSString *) title;

- (BM_OSX_NSMenu *) submenu;

- (void) show:(NSString *) inIndent;

@end
