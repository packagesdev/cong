#import <Foundation/Foundation.h>

@interface BM_OSX_NSMenu : NSObject
{
	NSString * internalName_;
	
	NSString * title_;
	
	NSMutableArray	* items_;
}

- (NSString *) name;

- (NSString *) title;

- (NSArray *) itemArray;

- (void) show:(NSString *) inIndent;

@end
