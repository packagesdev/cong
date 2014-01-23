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

#import "BMQualityPluginManager.h"

#import "BMReportDocument+Constants.h"

@interface BMReportDocument : NSDocument
{
	// Drag and Drop View
	
	IBOutlet id IBdragAndDropContentView_;
	
	// Report View
	
	IBOutlet id IBreportContentView_;
	
	// Headers
	
	IBOutlet id IBbundleIcon_;
	
	IBOutlet id IBbundleNameTextField_;
	
	IBOutlet id IBbundleVersionTextField_;
	
	IBOutlet id IBbundleArchitectureTextField_;
	
	IBOutlet id IBcheckAgainButton_;
	
	// Report View
	
	IBOutlet id IBreportView_;
	
	// Bottom Bar
	
	IBOutlet id IBbottomLabel_;

	// Data
	
	BOOL newDocument_;
	
	BMQualityPluginManager * pluginManager_;
	
	NSMutableDictionary * reportDictionary_;
	
	BOOL isMainBundle_;
	
	NSBundle * mainBundle_;
	
	NSFileManager * fileManager_;
	
	id currentReporterViewController_;
	
	NSUInteger errorsCount_;
	NSUInteger warningsCount_;
	NSUInteger notesCount_;
}

- (void) delayedTest:(NSString *) inPath;

- (void) testItemAtPath:(NSString *) inPath ofType:(NSUInteger) inType;

- (void) switchVisibleReporter;

- (IBAction) checkAgain:(id) sender;

- (IBAction) switchScope:(id) sender;

// Notifications

- (void) bundleDidDrop:(NSNotification *) inNotification;

- (void) didReceiveExternalReport:(NSNotification *) inNotification;

@end
