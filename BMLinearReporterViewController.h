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

#import "BMLinearTree.h"

@interface BMLinearReporterViewController : BMBundleReporterViewController
{
	IBOutlet id IBallScope_;
	
	IBOutlet id IBerrorsScope_;
	
	IBOutlet id IBwarningsScope_;
	
	IBOutlet id IBnotesScope_;
	
	IBOutlet id IBoutlineView_;
	
	IBOutlet id IBcheckingView_;
	
	IBOutlet id IBspinningIndicator_;
	
	IBOutlet id IBnoGlitchesView_;
	
	// Data
	
	id outlineSubView_;
	
	BOOL noGlitchesFound_;
	
	BMLinearTreeNode * storageTree_;
	
	NSMutableDictionary * storageTreeHash_;
	
	BMLinearTreeNode * displayTree_;
	
	NSMutableDictionary * displayTreeHash_;
	
	NSMutableDictionary * iconsCache_;
	
	NSMutableArray * itemsToExpand_;
	
	NSMutableIndexSet * scopeSet_;
	
	NSMutableIndexSet * scopeSetAll_;
	
	NSArray * cachedScopeButtons_;
}

- (NSString *) disclosedStateKey;

- (void) prepareData;

- (void) revealSelectedIssues:(id) sender;

- (IBAction) switchScope:(id) sender;


- (void) expandItem:(BMLinearTreeNode *) inFileTree ifKeyOfDictionary:(NSMutableDictionary *) inDictionary;

// Notifications

- (void) outlineViewFrameDidChange:(NSNotification *) inNotification;

@end
