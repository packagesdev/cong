#import "BMPreferencesController.h"

#import "BMPreferences+Constants.h"

#import "WBRemoteVersionChecker.h"

@implementation BMPreferencesController

+ (void) showPreferences
{
	static BMPreferencesController * sPreferencesController=nil;
	
	if (sPreferencesController==nil)
	{
		sPreferencesController=[[BMPreferencesController alloc] initWithWindowNibName:@"BMPreferencesWindow"];
	}
	
	[sPreferencesController showWindow:self];
}

- (void) awakeFromNib
{
	defaults_=[NSUserDefaults standardUserDefaults];
	
	[self initSettings];
	
	[[self window] center];
}

#pragma mark -

- (void) initSettings
{
	[IBalwaysOneWindowCheckBox_ setState:[defaults_ boolForKey:BM_PREFERENCES_ALWAYS_SHOW_ONE_WINDOW]? NSOnState : NSOffState];

	[IBcheckUpdateCheckBox_ setState:([[WBRemoteVersionChecker sharedChecker] isCheckEnabled]==YES) ? NSOnState: NSOffState];
}

- (void) switchAlwaysOneWindow:(id) sender
{
	[defaults_ setBool:([IBalwaysOneWindowCheckBox_ state]==NSOnState) forKey:BM_PREFERENCES_ALWAYS_SHOW_ONE_WINDOW];
}

- (void) switchCheckUpdate:(id) sender
{
	[[WBRemoteVersionChecker sharedChecker] setCheckEnabled:([IBcheckUpdateCheckBox_ state]==NSOnState)];
}

@end
