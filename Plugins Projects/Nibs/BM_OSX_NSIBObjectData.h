#import <Foundation/Foundation.h>

#import "BM_OSX_NSCustomObject.h"

@interface BM_OSX_NSIBObjectData : NSObject
{
	NSArray * keys_;
	NSArray * objects_;
	
	BM_OSX_NSCustomObject * fileOwner_;
}

- (NSArray *) allMenus;

- (NSArray *) allViews;

- (NSArray *) allWindowViews;

@end
