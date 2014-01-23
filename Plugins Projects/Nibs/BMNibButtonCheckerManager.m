/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMNibButtonCheckerManager.h"

#import "BMNibMenuCheckerManager.h"

#import "BMReportingUtilities.h"

#import "BM_OSX_NSButton.h"

#import "BM_OSX_NSPopUpButton.h"

#import "BM_OSX_NSMatrix.h"

#import "BM_OSX_NSTabView.h"

#import "BM_OSX_NSTabViewItem.h"

@implementation BMNibButtonCheckerManager

- (void) checkTitleOfButtonCell:(BM_OSX_NSButtonCell *) inButtonCell;
{
	if (inButtonCell!=nil)
	{
		NSString * tTitle;
		
		tTitle=[inButtonCell title];
		
		if (tTitle!=nil)
		{
			NSRange tRange;
			
			// Voice Over checks
			
			if ([inButtonCell imagePosition]==BM_OSX_NSImageOnly)
			{
				// A COMPLETER
			}
			
			// Check the capitalization
			
			// A COMPLETER
			
			// Check that the default strings have been replaced
			
			if ([tTitle isEqualToString:@"Button"]==YES)
			{
				if ([inButtonCell imagePosition]!=BM_OSX_NSNoImage)
				{
					[BMReportingUtilities reportProblemTo:delegate
													 file:filePath_
													level:BM_PROBLEM_LEVEL_WARNING
													title:NSLocalizedStringFromTableInBundle(@"Default \"Button\" title used.",@"WarningsAndErrors",bundle_,@"") 
											  description:tTitle
													 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
												   extras:nil];
				}
			}
			else
			{
				if ([tTitle caseInsensitiveCompare:@"OK"]==NSOrderedSame)
				{
					if ([tTitle isEqualToString:@"OK"]==NO)
					{
						[BMReportingUtilities reportProblemTo:delegate
														 file:filePath_
														level:BM_PROBLEM_LEVEL_WARNING
														title:NSLocalizedStringFromTableInBundle(@"Incorrect spelling of OK button.",@"WarningsAndErrors",bundle_,@"") 
												  description:tTitle
														 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
													   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(NSMakeRange(0,[tTitle length])),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
															   nil]];
					}
				}
				else
				{
					if (isJapanese_==NO)
					{
						// Check the ellipsis
						
						tRange=[tTitle rangeOfString:@"..."];
						
						if (tRange.location!=NSNotFound)
						{
							[BMReportingUtilities reportProblemTo:delegate
															 file:filePath_
															level:BM_PROBLEM_LEVEL_WARNING
															title:NSLocalizedStringFromTableInBundle(@"Button title using 3 dots instead of ellipsis.",@"WarningsAndErrors",bundle_,@"") 
													  description:tTitle
															 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
														   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																   nil]];
						}
						else
						{
							if ([inButtonCell isSwitchOrRadioButton]==YES)
							{
								if ([tTitle hasSuffix:@"."]==YES)
								{
									[BMReportingUtilities reportProblemTo:delegate
																	 file:filePath_
																	level:BM_PROBLEM_LEVEL_WARNING
																	title:NSLocalizedStringFromTableInBundle(@"Radio buttons and checkboxes' titles usually do not end with a \'.\'",@"WarningsAndErrors",bundle_,@"") 
															  description:tTitle
																	 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
																   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(NSMakeRange([tTitle length]-1,1)),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																		   nil]];
								}
							}
							
							if (isGerman_==YES)
							{
								// In German, there should be a space before the ellipsis
								
								NSUInteger tLength;
								
								tLength=[tTitle length];
								
								if (tLength>=2)
								{
									if ([tTitle characterAtIndex:tLength-1]==0x2026 && [tTitle characterAtIndex:tLength-2]!=' ')
									{
										tRange=NSMakeRange(tLength-1,1);
										
										[BMReportingUtilities reportProblemTo:delegate
																		 file:filePath_
																		level:BM_PROBLEM_LEVEL_WARNING
																		title:NSLocalizedStringFromTableInBundle(@"Button Title: there should be a space before the ellipsis in German.",@"WarningsAndErrors",bundle_,@"") 
																  description:tTitle
																		 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
																	   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																			   nil]];
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

- (void) analyzeView:(BM_OSX_NSView *) inView
{
	if (inView!=nil && [inView isKindOfClass:[BM_OSX_NSView class]]==YES)
	{
		NSArray * tSubViews;
		
		if ([inView isKindOfClass:[BM_OSX_NSPopUpButton class]]==YES)
		{
			id tCell;
			
			tCell=[(BM_OSX_NSPopUpButton *) inView cell];
			
			if ([tCell isKindOfClass:[BM_OSX_NSPopUpButtonCell class]]==YES)
			{
				BM_OSX_NSMenu * tMenu;
				
				tMenu=[(BM_OSX_NSPopUpButtonCell *) tCell menu];
				
				if (tMenu!=nil)
				{
					BMNibMenuCheckerManager * tMenuCheckerManager;
					
					tMenuCheckerManager=[BMNibMenuCheckerManager new];
					
					if (tMenuCheckerManager!=nil)
					{
						[tMenuCheckerManager setBundle:bundle_];
					
						[tMenuCheckerManager setDelegate:delegate];
					
						[tMenuCheckerManager analyzeMenu:tMenu relativeLocation:@""];
				
						[tMenuCheckerManager release];
					}
				}
				
				[self checkTitleOfButtonCell:(BM_OSX_NSButtonCell *) tCell];
			}
		}
		else if ([inView isKindOfClass:[BM_OSX_NSButton class]]==YES)
		{
			id tCell;
			
			tCell=[(BM_OSX_NSButton *) inView cell];
			
			if ([tCell isKindOfClass:[BM_OSX_NSButtonCell class]]==YES)
			{
				[self checkTitleOfButtonCell:(BM_OSX_NSButtonCell *) tCell];
			}
		}
		else if ([inView isKindOfClass:[BM_OSX_NSMatrix class]]==YES)
		{
			NSArray * tArray;
			
			tArray=[(BM_OSX_NSMatrix *) inView cells];
			
			for(BM_OSX_NSCell * tCell in tArray)
			{
				if ([tCell isKindOfClass:[BM_OSX_NSButtonCell class]]==YES)
				{
					[self checkTitleOfButtonCell:(BM_OSX_NSButtonCell *) tCell];
				}
			}
		}
		else if ([inView isKindOfClass:[BM_OSX_NSTabView class]]==YES)
		{
			NSArray * tArray;
			
			tArray=[(BM_OSX_NSTabView *) inView tabViewItems];
			
			for(BM_OSX_NSTabViewItem * tTabViewItem in tArray)
			{
				[self analyzeView:[tTabViewItem view]];
			}
			
		}
		
		tSubViews=[inView subviews];
		
		for(BM_OSX_NSView * tView in tSubViews)
		{
			[self analyzeView:tView];
		}
	}
}

- (void) checkObjectsWithObjectData:(BM_OSX_NSIBObjectData *) inObjectData ofFile:(NSString *) inPath forLanguage:(NSString *) inLanguage
{
	if (inObjectData!=nil)
	{
		NSArray * tAllViews;
		
		[super checkObjectsWithObjectData:inObjectData ofFile:inPath forLanguage:inLanguage];
		
		// Top level Views
		
		tAllViews=[inObjectData allViews];
		
		if (tAllViews!=nil)
		{
			for(BM_OSX_NSView * tView in tAllViews)
			{
				[self analyzeView:tView];
			}
		}
		
		// Content Views of Windows
		
		tAllViews=[inObjectData allWindowViews];
		
		if (tAllViews!=nil)
		{
			for(BM_OSX_NSView * tView in tAllViews)
			{
				[self analyzeView:tView];
			}
		}
	}
}

@end
