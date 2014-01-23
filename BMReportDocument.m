/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMReportDocument.h"

#import "BMQualityPluginManager.h"

#import "BMBundleUtilities.h"

#import "BMStringsFileChecker.h"

#import "BMReportingUtilities.h"

#import "BMLinearReporterViewController.h"

#import "BMDragAndDropContentView.h"

#import "BMBottomBarView.h"

#import "ICArchitectureUtilities.h"

@implementation BMReportDocument

-  (id) initWithType:(NSString *) inType error:(NSError **) outError
{
	self=[super initWithType:inType error:outError];
	
	if (self!=nil)
	{
		fileManager_=[NSFileManager defaultManager];
		
		reportDictionary_=[[NSMutableDictionary alloc] initWithCapacity:100];
		
		newDocument_=YES;
	}
	
	return self;
}

- (id) init
{
    self = [super init];
	
    if (self!=nil)
	{
		fileManager_=[NSFileManager defaultManager];
		
		reportDictionary_=[[NSMutableDictionary alloc] initWithCapacity:100];
    }
	
    return self;
}

- (void) dealloc
{	
	[[NSNotificationCenter defaultCenter] postNotificationName:BM_NOTIFICATION_REPORT_DOCUMENT_DID_CLOSE object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
		
	[pluginManager_ release];
	
	[reportDictionary_ release];
	
	[mainBundle_ release];


	[super dealloc];
}

#pragma mark -

- (NSString *) windowNibName
{
    return @"BMReportDocument";
}

- (NSString *) displayName
{
	if (newDocument_==YES)
	{
		return @"Cong";//NSLocalizedString(@"Drop an application",@"");;
	}
	
	return [super displayName];
}

- (void) _prepareReportForItemAtPath:(NSString *) inPath
{
	NSImage * tImage;
	NSString * tString;
	NSString * tBundleName;
	NSDictionary * tDictionary;
	NSString * tVersionString;
	NSString * tBundleVersionString;
	NSBundle * tBundle;
	NSString * tExecutablePath;
	
	// Icon
	
	tImage=[[NSWorkspace sharedWorkspace] iconForFile:inPath];
	
	if (tImage==nil)
	{
		// A COMPLETER
		
		//tImage=[[NSWorkspace sharedWorkspace]
	}
	
	if (tImage!=nil)
	{
		[tImage setScalesWhenResized:YES];
		
		[tImage setSize:[IBbundleIcon_ bounds].size];
		
		[IBbundleIcon_ setImage:tImage];
	}
	
	tBundle=[NSBundle bundleWithPath:inPath];
	
	// Name
	
	tBundleName=[[inPath lastPathComponent] stringByDeletingPathExtension];
	
	[IBbundleNameTextField_ setStringValue:tBundleName];
	
	// Version
	
	tVersionString=[[tBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	
	tBundleVersionString=[[tBundle infoDictionary] objectForKey:@"CFBundleVersion"];
	
	if (tVersionString==nil)
	{
		tDictionary=[tBundle localizedInfoDictionary];
		
		if (tDictionary!=nil)
		{
			tString=[tDictionary objectForKey:@"CFBundleShortVersionString"];
			
			if (tString!=nil)
			{
				tVersionString=tString;
			}
		}
	}
	
	if (tVersionString==nil)
	{
		tVersionString=@"";
	}
	
	if (tBundleVersionString!=nil)
	{
		[IBbundleVersionTextField_ setStringValue:[NSString stringWithFormat:@"%@ (%@)",tVersionString,tBundleVersionString]];
	}
	else
	{
		[IBbundleVersionTextField_ setStringValue:tVersionString];
	}
	
	// Architecture
	
	tString=@"";
	
	tExecutablePath=[tBundle executablePath];
	
	if (tExecutablePath!=nil)
	{
		NSArray * tArchitecturesArray;
		
		tArchitecturesArray=[ICArchitectureUtilities architecturesOfFile:tExecutablePath];
		
		if (tArchitecturesArray!=nil)
		{
			tString=[tArchitecturesArray componentsJoinedByString:@" | "];
		}
	}
	
	[IBbundleArchitectureTextField_ setStringValue:tString];
	
	// Register for Notification
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveExternalReport:) name:BM_NOTIFICATION_DID_REPORT_PROBLEM object:self];
	
	
	
	[self switchVisibleReporter];
	
	errorsCount_=warningsCount_=notesCount_=0;
	
	[IBbottomLabel_ setStringValue:@""];
	
	if (currentReporterViewController_!=nil)
	{
		[currentReporterViewController_ analysisWillStart];
	}
	
	pluginManager_=[BMQualityPluginManager new];
	
	[self performSelector:@selector(delayedTest:) withObject:inPath afterDelay:0.0];
}

- (void) windowControllerDidLoadNib:(NSWindowController *) aController
{
    NSWindow * tWindow;
	
	[super windowControllerDidLoadNib:aController];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BM_NOTIFICATION_REPORT_DOCUMENT_DID_CREATE object:nil];
	
	tWindow=[self windowForSheet];
	
	[tWindow setContentBorderThickness:22 forEdge:NSMinYEdge];
	
	if ([tWindow respondsToSelector:@selector(setRestorable:)]==YES)
	{
		[tWindow setRestorable:NO];
	}
	
	if (newDocument_==NO)
	{
		NSString * tPath;
		
		tPath=[[self fileURL] path];
		
		if (tPath!=nil)
		{
			NSRect tBounds;
			NSRect tWindowFrame;
			NSRect tFrame;
			NSWindow * tWindow;
			NSRect tViewFrame;
			
			tWindow=[self windowForSheet];
			
			tWindowFrame=[tWindow frame];
			
			tViewFrame=tBounds=[IBreportContentView_ bounds];
			
			tViewFrame.origin.y+=22;
			tViewFrame.size.height-=22;
			
			[IBreportContentView_ setFrame:tViewFrame];
			
			tFrame=[tWindow frameRectForContentRect:tBounds];
			
			//NSLog(@"%@ %@",NSStringFromRect(tFrame),NSStringFromRect(tWindowFrame));
			
			[tWindow setFrame:NSMakeRect(NSMinX(tWindowFrame),NSMinY(tWindowFrame)-NSHeight(tFrame)+NSHeight(tWindowFrame),NSWidth(tFrame),NSHeight(tFrame)) display:NO animate:NO];
			
			[[tWindow contentView] addSubview:IBreportContentView_];
			
			[tWindow setMinSize:NSMakeSize(NSWidth(tFrame),400)];
			
			[tWindow setMaxSize:NSMakeSize(NSWidth(tFrame),3000)];
			
			[self _prepareReportForItemAtPath:tPath];
		}
	}
	else
	{
		NSRect tBounds;
		NSRect tWindowFrame;
		NSRect tFrame;
		NSRect tViewFrame;
		
		tWindowFrame=[tWindow frame];
		
		tViewFrame=tBounds=[IBdragAndDropContentView_ bounds];
		
		tViewFrame.origin.y+=22;
		tViewFrame.size.height-=22;
		
		[IBdragAndDropContentView_ setFrame:tViewFrame];
		
		tFrame=[tWindow frameRectForContentRect:tBounds];
		
		//NSLog(@"%@ %@",NSStringFromRect(tFrame),NSStringFromRect(tWindowFrame));
		
		[tWindow setFrame:NSMakeRect(NSMinX(tWindowFrame),NSMinY(tWindowFrame)-NSHeight(tFrame)+NSHeight(tWindowFrame),NSWidth(tFrame),NSHeight(tFrame)) display:NO animate:NO];
		
		[[tWindow contentView] addSubview:IBdragAndDropContentView_];
		
		[tWindow setShowsResizeIndicator:NO];
		
		[tWindow setContentMinSize:tBounds.size];
		[tWindow setContentMaxSize:tBounds.size];
		
		[[tWindow standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
		
		[[tWindow standardWindowButton:NSWindowZoomButton] setHidden:YES];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(bundleDidDrop:)
													 name:BMDragAndDropContentViewDidChangeNotification
												   object:IBdragAndDropContentView_];
	}
}

- (BOOL) readFromURL:(NSURL *) inURL ofType:(NSString *) inType error:(NSError **) outError
{
	return YES;
}

- (void) testItemAtPath:(NSString *) inPath ofType:(NSUInteger) inType
{
	// First check the integrity of the bundle structure
	
	if ([BMBundleUtilities checkStructureOfBundleAtPath:inPath withDelegate:self]==YES)
	{
		NSBundle * tBundle;
		NSString * tPath;
		NSArray * tArray;
		BOOL isDirectory;
		
		tBundle=nil;
		
		[pluginManager_ testItem:tBundle atPath:inPath ofType:inType withDelegate:self];
		
		if (inType==BM_BUNDLETYPE_APP_BUNDLE)
		{
			// Login Items (10.6.6 and later)
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/Library/LoginItems"];
			
			if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"app"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_APP_BUNDLE];
					}
				}
			}
			
			// Automator Actions
		
			tPath=[inPath stringByAppendingPathComponent:@"Contents/Library/Automator"];
			
			if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"action"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_AUTOMATOR_ACTION];
					}
				}
			}
			
			// Spotlight
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/Library/Spotlight"];
			
			if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"mdimporter"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_SPOTLIGHT_IMPORTER];
					}
				}
			}
			
			// PrivateFrameworks
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/PrivateFrameworks"];
			
			if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"framework"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_FRAMEWORK];
					}
				}
			}
		}
		else
		{
			if (inType==BM_BUNDLETYPE_IOS_APP_BUNDLE)
			{
				// Settings.bundle
				
				tPath=[inPath stringByAppendingPathComponent:@"Settings.bundle"];
				
				if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
				{
					// A COMPLETER
				}
			}
		}
		
		if (inType!=BM_BUNDLETYPE_IOS_APP_BUNDLE)
		{
			if (inType!=BM_BUNDLETYPE_FRAMEWORK)
			{
				// Plugins
			
				tPath=[inPath stringByAppendingPathComponent:@"Contents/PlugIns"];
				
				if (tPath!=nil)
				{
					tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
					
					for(NSString * tFilePath in tArray)
                    {
						
						if ([[tFilePath pathExtension] caseInsensitiveCompare:@"bundle"]==NSOrderedSame)
						{
							[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
										  ofType:BM_BUNDLETYPE_BUNDLE];
						}
						else if ([[tFilePath pathExtension] caseInsensitiveCompare:@"plugin"]==NSOrderedSame)
						{
							[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
										  ofType:BM_BUNDLETYPE_PLUGIN];
						}
						
					}
				}
				
				// Frameworks
				
				tPath=[inPath stringByAppendingPathComponent:@"Contents/Frameworks"];
				
				if (tPath!=nil)
				{
					tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
					
					for(NSString * tFilePath in tArray)
                    {
						
						if ([[tFilePath pathExtension] caseInsensitiveCompare:@"framework"]==NSOrderedSame)
						{
							[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
										  ofType:BM_BUNDLETYPE_FRAMEWORK];
						}
					}
				}
			}
		
			// Apps in Resources
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/Resources"];
			
			if (tPath!=nil)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"app"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath]
									  ofType:BM_BUNDLETYPE_APP_BUNDLE];
					}
				}
			}
		}
	}
}

- (void) delayedTest:(NSString *) inPath
{
	NSUInteger tBundleType;
	
	tBundleType=[BMBundleUtilities bundleTypeAtPath:inPath];
	
	[self testItemAtPath:inPath ofType:tBundleType];
	
	if (currentReporterViewController_!=nil)
	{
		[currentReporterViewController_ analysisDidComplete];
		
		[IBcheckAgainButton_ setEnabled:YES];
		
		// Bottom Label
		
		if (errorsCount_==0 && warningsCount_==0 && notesCount_==0)
		{
			[IBbottomLabel_ setStringValue:NSLocalizedString(@"No glitches found",@"")];
		}
		else
		{
			NSMutableString * tMutableString;
			NSString * tString;
			
			tMutableString=[NSMutableString string];
		
			if (errorsCount_>0)
			{
				if (errorsCount_>1)
				{
					tString=[NSString stringWithFormat:NSLocalizedString(@"%lu errors",@""),(unsigned long) errorsCount_];
				}
				else
				{
					tString=[NSString stringWithFormat:NSLocalizedString(@"%lu error",@""),(unsigned long) errorsCount_];
				}

				[tMutableString appendString:tString];
			}
			
			if (warningsCount_>0)
			{
				if ([tMutableString length]>0)
				{
					[tMutableString appendString:@", "];
				}
				
				if (warningsCount_>1)
				{
					tString=[NSString stringWithFormat:NSLocalizedString(@"%lu warnings",@""),(unsigned long) warningsCount_];
				}
				else
				{
					tString=[NSString stringWithFormat:NSLocalizedString(@"%lu warning",@""),(unsigned long) warningsCount_];
				}

				[tMutableString appendString:tString];
			}
			
			if (notesCount_>0)
			{
				if ([tMutableString length]>0)
				{
					[tMutableString appendString:@", "];
				}
				
				if (notesCount_>1)
				{
					tString=[NSString stringWithFormat:NSLocalizedString(@"%lu notes",@""),(unsigned long) notesCount_];
				}
				else
				{
					tString=[NSString stringWithFormat:NSLocalizedString(@"%lu note",@""),(unsigned long) notesCount_];
				}

				[tMutableString appendString:tString];
			}
			
			tString=[NSString stringWithFormat:NSLocalizedString(@"Glitches found (%@)",@""),tMutableString];
			
			[IBbottomLabel_ setStringValue:tString];
		}
	}
}

#pragma mark -

- (void) switchVisibleReporter
{
	NSView * tCurrentView;
	
	if (currentReporterViewController_!=nil)
	{
		tCurrentView=[currentReporterViewController_ view];
		
		if (tCurrentView!=nil)
		{
			[tCurrentView removeFromSuperview];
		}
	}
	
	currentReporterViewController_=[[BMLinearReporterViewController alloc] initWithReportingDictionary:reportDictionary_];
	
	if (currentReporterViewController_!=nil)
	{
		[currentReporterViewController_ setBundlePath:[[self fileURL] path]];
		
		tCurrentView=[currentReporterViewController_ view];
		
		if (tCurrentView!=nil)
		{
			NSRect tBounds;
		
			tBounds=[IBreportView_ bounds];
		
			[tCurrentView setFrame:tBounds];
			
			[IBreportView_ addSubview:tCurrentView];
		}
	}
}

#pragma mark -

- (BOOL) validateMenuItem:(NSMenuItem *) inMenuItem
{
	SEL tAction;
	
	tAction=[inMenuItem action];
	
	if (tAction==@selector(switchScope:))
	{
		return (newDocument_==NO && [currentReporterViewController_ canSwitchScope]==YES);
	}
	
	return [super validateMenuItem:inMenuItem];
}


- (IBAction) switchScope:(id) sender
{
	[currentReporterViewController_ switchScope:sender];
}

- (IBAction) checkAgain:(id) sender
{
	NSString * tPath;

	tPath=[[self fileURL] path];
	
	[reportDictionary_ removeAllObjects];
	
	[IBcheckAgainButton_ setEnabled:NO];
	
	errorsCount_=warningsCount_=notesCount_=0;
	
	[IBbottomLabel_ setStringValue:@""];
	
	if (currentReporterViewController_!=nil)
	{
		[currentReporterViewController_ analysisWillStart];
	}
	
	[self performSelector:@selector(delayedTest:) withObject:tPath afterDelay:0.6];
}

#pragma mark -

- (void) qualityController:(BMQualityPluginController *) inQualityPluginController didReportProblem:(NSDictionary *) inWarningDictionary level:(NSUInteger) inLevel
{
	// A COMPLETER
}

#pragma mark -

- (void) bundleDidDrop:(NSNotification *) inNotification
{
	NSDictionary * tDictionary;
	
	tDictionary=[inNotification userInfo];
	
	if (tDictionary!=nil)
	{
		NSString * tPath;
		
		tPath=[tDictionary objectForKey:@"Path"];
		
		if (tPath!=nil)
		{
			NSRect tBounds;
			NSRect tWindowFrame;
			NSRect tFrame;
			NSWindow * tWindow;
			NSRect tViewFrame;
			
			[[NSNotificationCenter defaultCenter] removeObserver:self name:BMDragAndDropContentViewDidChangeNotification object:IBdragAndDropContentView_];	
			
			[IBdragAndDropContentView_ removeFromSuperview];
			
			tWindow=[self windowForSheet];
			
			tWindowFrame=[tWindow frame];
			
			tViewFrame=tBounds=[IBreportContentView_ bounds];
			
			tViewFrame.origin.y+=22;
			tViewFrame.size.height-=22;
			
			[IBreportContentView_ setFrame:tViewFrame];
			
			tFrame=[tWindow frameRectForContentRect:tBounds];
			
			[tWindow setFrame:NSMakeRect(NSMinX(tWindowFrame),NSMinY(tWindowFrame)-NSHeight(tFrame)+NSHeight(tWindowFrame),NSWidth(tFrame),NSHeight(tFrame)) display:YES animate:YES];
			
			[[tWindow contentView] addSubview:IBreportContentView_];
			
			[tWindow setMinSize:NSMakeSize(NSWidth(tFrame),400)];
			
			[tWindow setMaxSize:NSMakeSize(NSWidth(tFrame),3000)];
			
			[tWindow setShowsResizeIndicator:YES];
			
			[[tWindow standardWindowButton:NSWindowMiniaturizeButton] setHidden:NO];
			
			[[tWindow standardWindowButton:NSWindowZoomButton] setHidden:NO];
			
			newDocument_=NO;
			
			[self setFileURL:[NSURL fileURLWithPath:tPath]];
			
             [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:tPath]];
            
			[self _prepareReportForItemAtPath:tPath];
		}
	}
}

- (void) didReceiveExternalReport:(NSNotification *) inNotification
{
	NSDictionary * tUserInfo;
	
	tUserInfo=[inNotification userInfo];
	
	if (tUserInfo!=nil)
	{
		NSString * tFilePath;
		NSMutableDictionary * tFileReportMutableDictionary;
		
		tFilePath=[tUserInfo objectForKey:BM_PROBLEM_FILE];
		
		tFileReportMutableDictionary=[reportDictionary_ objectForKey:tFilePath];
		
		if (tFileReportMutableDictionary==nil)
		{
			tFileReportMutableDictionary=[NSMutableDictionary dictionary];
				
			if (tFileReportMutableDictionary!=nil)
			{
				[reportDictionary_ setObject:tFileReportMutableDictionary forKey:tFilePath];
			}
			else
			{
				// Low Memory
				
				// A COMPLETER
			}
		}
		
		if (tFileReportMutableDictionary!=nil)
		{
			NSNumber * tLevelNumber;
			NSMutableArray * tLevelReportMutableArray;
			NSUInteger tLevelValue;
			
			tLevelNumber=[tUserInfo objectForKey:BM_PROBLEM_LEVEL];
			
			tLevelValue=[tLevelNumber unsignedIntegerValue];
			
			switch(tLevelValue)
			{
				case BM_PROBLEM_LEVEL_NOTE:
					
					notesCount_++;
					
					break;
					
				case BM_PROBLEM_LEVEL_WARNING:
					
					warningsCount_++;
					
					break;
					
				case BM_PROBLEM_LEVEL_ERROR:
					
					errorsCount_++;
					
					break;
			}
			
			tLevelReportMutableArray=[tFileReportMutableDictionary objectForKey:tLevelNumber];
			
			if (tLevelReportMutableArray==nil)
			{
				tLevelReportMutableArray=[NSMutableArray array];
				
				if (tLevelReportMutableArray!=nil)
				{
					[tFileReportMutableDictionary setObject:tLevelReportMutableArray forKey:tLevelNumber];
				}
				else
				{
					// Low Memory
					
					// A COMPLETER
				}
			}
			
			if (tLevelReportMutableArray!=nil)
			{
				NSMutableDictionary * tReportMutableDictionary;
				
				tReportMutableDictionary=[tUserInfo mutableCopy];
				
				if (tReportMutableDictionary!=nil)
				{
					[tReportMutableDictionary removeObjectForKey:BM_PROBLEM_LEVEL];
				
					[tReportMutableDictionary removeObjectForKey:BM_PROBLEM_FILE];
				
					[tLevelReportMutableArray addObject:tReportMutableDictionary];
					
					[currentReporterViewController_ didReceiveNewReport:tReportMutableDictionary forFileAtPath:tFilePath level:tLevelNumber];
					
					[tReportMutableDictionary release];
				}
				else
				{
					// Low Memory
					
					// A COMPLETER
				}
			}
		}
	}
}

@end
