/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import "BMReportingConstants.h"

/*extern NSString * BM_REPORTER_DIDRECEIVE_NEW_REPORT;*/

@interface BMBundleReporterViewController : NSObject
{
	IBOutlet id IBview_;
	
	// Data
	
	NSDictionary * reportDictionary_;
	
	NSString * bundlePath_;
	
	NSMutableDictionary * controllerDefaults_;
}

- (id) initWithReportingDictionary:(NSDictionary *) inDictionary;

- (id) view;

- (BOOL) canSwitchScope;

- (void) setBundlePath:(NSString *) inPath;

- (void) didReceiveNewReport:(NSDictionary *) inReportDictionary forFileAtPath:(NSString *) inPath level:(NSNumber *) inLevelNumber;

- (void) analysisWillStart;

- (void) analysisDidStart;

- (void) analysisDidComplete;

- (id) controllerDefaultForKey:(NSString *) inKey;

- (void) setControllerDefault:(id) inObject forKey:(NSString *) inKey;

- (void) removeControllerDefaultForKey:(NSString *) inKey;

@end
