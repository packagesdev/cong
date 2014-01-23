/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMApplicationController.h"

#import "BMAboutBoxController.h"

#import "BMPreferencesController.h"

#import "BMReportDocument+Constants.h"

#import "WBRemoteVersionChecker.h"

@implementation BMApplicationController

/*- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *) sender
{
    return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *) sender
{
	return YES;
}*/

#pragma mark -

- (void) awakeFromNib
{
	defaults_=[NSUserDefaults standardUserDefaults];
	
	// Register for notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDocumentDidCreate:) name:BM_NOTIFICATION_REPORT_DOCUMENT_DID_CREATE object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDocumentDidClose:) name:BM_NOTIFICATION_REPORT_DOCUMENT_DID_CLOSE object:nil];
}

- (IBAction) showAboutBox:(id) sender
{
	[[BMAboutBoxController sharedController] showWindow];
}

- (IBAction) showPreferences:(id) sender
{
	[BMPreferencesController showPreferences];
}

/*- (IBAction) newDocument:(id) sender
{
	[[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:NULL];
}*/

- (IBAction) showUserGuide:(id) sender
{
	NSURL * tURL=nil;
    
    tURL=[NSURL URLWithString:NSLocalizedString(@"http://s.sudre.free.fr/Software/documentation/Cong/en/index.html",@"No comment")];
    
    if (tURL!=nil)
    {
        [[NSWorkspace sharedWorkspace] openURL:tURL];
    }
}

- (IBAction) sendFeedback:(id) sender
{
	NSURL * tURL=nil;
    NSString * tString;
	NSDictionary * tDictionary;
	
	tDictionary=[[NSBundle mainBundle] infoDictionary];
	
	tString=[NSString stringWithFormat:NSLocalizedString(@"mailto:dev.cong@gmail.com?subject=[Cong%%20%@]%%20Feedback%%20(build%%20%@)",@"No comment"),[tDictionary objectForKey:@"CFBundleShortVersionString"],
			 [tDictionary objectForKey:@"CFBundleVersion"]];
    tURL=[NSURL URLWithString:tString];
    
    if (tURL!=nil)
    {
        [[NSWorkspace sharedWorkspace] openURL:tURL];
    }
}

#pragma mark -

- (void) reportDocumentDidClose:(NSNotification *) inNotification
{
	reportDocumentCount_--;
	
	if (reportDocumentCount_==0)
	{
		if ([defaults_ boolForKey:@"ui.always.one.window"]==YES)
		{
			[[NSDocumentController sharedDocumentController] newDocument:nil];
		}
	}
}

- (void) reportDocumentDidCreate:(NSNotification *) inNotification
{
	reportDocumentCount_++;
}

- (void) applicationDidFinishLaunching:(NSNotification *) inNotification
{
	[WBRemoteVersionChecker sharedChecker];
}

@end
