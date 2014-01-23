#import <Foundation/Foundation.h>

#import "BMQualityPluginManager.h"

@interface BMCommandLineProcessor : NSObject
{
	BOOL printDescription_;
	
	NSFileManager * fileManager_;
	
	BMQualityPluginManager * pluginManager_;
	
	NSUInteger errorsCount_;
	NSUInteger warningsCount_;
	NSUInteger notesCount_;
	
	NSMutableDictionary * reportDictionary_;
}

- (void) testItemAtPath:(NSString *) inPath ofType:(NSUInteger) inType;

- (int) processBundleAtPath:(NSString *) inPath printDescription:(BOOL) inPrintDescription;

#pragma mark -

- (void) didReceiveExternalReport:(NSNotification *) inNotification;

@end
