/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMQualityPluginController.h"

#import "BMReportingUtilities.h"

@implementation BMQualityPluginController

- (id) initWithBundle:(NSBundle *) inBundle
{
	self=[super init];
	
	if (self!=nil)
	{
		enabled_=YES;
		
		bundle_=[inBundle retain];
		
		// Register for Notification
		
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInternalReport:) name:BM_NOTIFICATION_INTERNAL_DID_REPORT_PROBLEM object:self];
	}
	
	return self;
}

- (void) dealloc
{
	[bundle_ release];

	[super dealloc];
}

#pragma mark -

- (NSString *) identifier
{
	return [bundle_ bundleIdentifier];
}

- (NSString *) name
{
	return [bundle_ objectForInfoDictionaryKey:@"BMPluginName"];
}

- (NSString *) version
{
	return [bundle_ objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *) checker_description
{
	return [bundle_ objectForInfoDictionaryKey:@"BMPluginDescription"];
}

- (BOOL) isEnabled
{
	return enabled_;
}

- (void) setEnabled:(BOOL) inEnabled
{
	enabled_=inEnabled;
}

- (BOOL) canTestItemOfType:(NSUInteger) inType
{
	return NO;
}

- (void) testItem:(id) inItem atPath:(NSString *) inPath ofType:(NSUInteger) inType  withDelegate:(id) inDelegate
{
	delegate=inDelegate;
}

#pragma mark -

- (void) didReceiveInternalReport:(NSNotification *) inNotification
{
	/*NSDictionary * tUserInfo;
	
	tUserInfo=[inNotification userInfo];
	
	// A VOIR
	
	if (tUserInfo!=nil)
	{
		NSString * tLevelString;
		NSString * tTitle;
		NSString * tDescription;
		
		tLevelString=([[tUserInfo objectForKey:BM_PROBLEM_LEVEL] intValue]==BM_PROBLEM_LEVEL_WARNING) ? @"Warning" : @"Error";
		
		tTitle=[tUserInfo objectForKey:BM_PROBLEM_TITLE];
		
		tDescription=[tUserInfo objectForKey:BM_PROBLEM_DESCRIPTION];
		
	}*/
}

@end

@implementation NSObject (BMQualityPluginController_delegate)

- (void) qualityController:(BMQualityPluginController *) inController didReportProblem:(NSDictionary *) inWarningDictionary level:(NSUInteger) inLevel
{
}

@end