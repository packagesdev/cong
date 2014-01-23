/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMBundleReporterViewController.h"

/*NSString * BM_REPORTER_DIDRECEIVE_NEW_REPORT=@"BM_REPORTER_DIDRECEIVE_NEW_REPORT";*/

@implementation BMBundleReporterViewController

- (id) initWithReportingDictionary:(NSDictionary *) inDictionary
{
	self=[super init];
	
	if (self!=nil)
	{
		controllerDefaults_=[[NSMutableDictionary alloc] initWithCapacity:10];
		
		reportDictionary_=[inDictionary retain];
		
		/*[[NSNotificationCenter defaultCenter] removeObserver:self];
		
		// Register for notification
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewReport:) name:BM_REPORTER_DIDRECEIVE_NEW_REPORT object:self];*/
	}
	
	return self;
}

- (void) dealloc
{
	[IBview_ release];
	
	[controllerDefaults_ release];
	
	[bundlePath_ release];
	
	[reportDictionary_ release];
	
	/*[[NSNotificationCenter defaultCenter] removeObserver:self];*/
	
	[super dealloc];
}

#pragma mark -

- (id) view
{
	return IBview_;
}

- (BOOL) canSwitchScope
{
	return YES;
}

- (void) setBundlePath:(NSString *) inPath
{
	[bundlePath_ release];
	
	bundlePath_=[inPath retain];
}

#pragma mark -

- (id) controllerDefaultForKey:(NSString *) inKey
{
	id tObject=nil;
	
	if (inKey!=nil)
	{
		tObject=[controllerDefaults_ objectForKey:inKey];
	}
	
	return tObject;
}

- (void) setControllerDefault:(id) inObject forKey:(NSString *) inKey
{
	if (inKey!=nil && inObject!=nil)
	{
		[controllerDefaults_ setObject:inObject forKey:inKey];
	}
}

- (void) removeControllerDefaultForKey:(NSString *) inKey
{
	if (inKey!=nil)
	{
		[controllerDefaults_ removeObjectForKey:inKey];
	}
}

#pragma mark -

- (void) didReceiveNewReport:(NSDictionary *) inReportDictionary forFileAtPath:(NSString *) inPath level:(NSNumber *) inLevelNumber
{
	// A COMPLETER
}

- (void) analysisWillStart
{
}

- (void) analysisDidStart
{
}

- (void) analysisDidComplete
{
}

@end
