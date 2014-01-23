/*
Copyright (c) 2004-2010, Stéphane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BMAboutBoxController.h"
#import "BMVersionSwitchView.h"

@implementation BMAboutBoxController

+ (BMAboutBoxController *) sharedController
{
	static BMAboutBoxController * sAboutBoxController=nil;
	
	if (sAboutBoxController==nil)
	{
		sAboutBoxController=[BMAboutBoxController alloc];
		
		if (sAboutBoxController!=nil)
		{
			if ([NSBundle loadNibNamed:@"BMAboutBox" owner:sAboutBoxController]==NO)
			{
				NSBeep();
				
				NSLog(@"[BMAboutBoxController sharedController] Cong can't find the \"%@\".nib resource file.",@"ICAboutBox");
			}
		}
		else
		{
			NSLog(@"[BMAboutBoxController sharedController] Not enough memory");
		}
	}
	
	return sAboutBoxController;
}

- (void) dealloc
{
	[IBwindow_ release];

	[super dealloc];
}

- (void) awakeFromNib
{
    NSDictionary * tDictionary;
        
	tDictionary=[[NSBundle mainBundle] infoDictionary];
        
	[IBversion_ setTitle:[NSString stringWithFormat:@"version %@",[tDictionary objectForKey:@"CFBundleShortVersionString"]]];
        
	[IBversion_ setAlternateTitle:[NSString stringWithFormat:@"Build %@",[tDictionary objectForKey:@"CFBundleVersion"]]];
    
    [IBwindow_ setBackgroundColor:[NSColor whiteColor]];
}

#pragma mark -

- (void) showWindow
{
    if ([IBwindow_ isVisible]==NO)
    {
        [IBwindow_ center];
        
        [IBwindow_ makeKeyAndOrderFront:self];
    }
}

#pragma mark -

- (IBAction) showLicenseAgreement:(id) sender
{
	NSString * tPath;
	
	tPath=[[NSBundle mainBundle] pathForResource:@"Cong_License" ofType:@"pdf"];
	
	if (tPath!=nil)
	{
		[[NSWorkspace sharedWorkspace] openFile:tPath];
	}
	else
	{
		NSLog(@"[BMAboutBoxController showLicenseAgreement:] Missing License file");
	}
}

- (IBAction) showAcknowledgments:(id) sender
{
	NSString * tPath;
	
	tPath=[[NSBundle mainBundle] pathForResource:@"Cong_Acknowledgments" ofType:@"pdf"];
	
	if (tPath!=nil)
	{
		[[NSWorkspace sharedWorkspace] openFile:tPath];
	}
	else
	{
		NSLog(@"[BMAboutBoxController showLicenseAgreement:] Missing License file");
	}
}

@end
