#import <Cocoa/Cocoa.h>

@interface BMPreferencesController : NSWindowController
{	
	IBOutlet id IBalwaysOneWindowCheckBox_;
	
	IBOutlet id IBcheckUpdateCheckBox_;

	// Data
	
	NSUserDefaults * defaults_;
}

+ (void) showPreferences;

- (void) initSettings;

- (void) switchAlwaysOneWindow:(id) sender;

- (void) switchCheckUpdate:(id) sender;

@end
