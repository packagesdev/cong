/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMNibMenuCheckerManager.h"

#import "BMReportingUtilities.h"

#define BM_ADDMENUPATH(inTitle) (([inRelativeLocation length]==0)? inTitle : [inRelativeLocation stringByAppendingFormat:@" > %@",inTitle])

@implementation BMNibMenuCheckerManager

- (void) analyzeMenuItem:(BM_OSX_NSMenuItem *) inMenuItem relativeLocation:(NSString *) inRelativeLocation
{
	NSString * tTitle;
	
	tTitle=[inMenuItem title];
	
	if (tTitle==nil)
	{
		// Separator item
	}
	else
	{
		NSRange tRange;
		
		// Check the capitalization
		
		// A COMPLETER
		
		if (isJapanese_==NO)
		{
			// Check the ellipsis
			
			tRange=[tTitle rangeOfString:@"..."];
			
			if (tRange.location!=NSNotFound)
			{
				if ([inRelativeLocation length]>0)
				{
					tRange.location+=[inRelativeLocation length]+3;
				}
				
				[BMReportingUtilities reportProblemTo:delegate
												 file:filePath_
												level:BM_PROBLEM_LEVEL_WARNING
												title:NSLocalizedStringFromTableInBundle(@"Menu item title using 3 dots instead of ellipsis.",@"WarningsAndErrors",bundle_,@"") 
										  description:BM_ADDMENUPATH(tTitle)
												 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
											   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
													   nil]];
			}
			else
			{
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
							
							if ([inRelativeLocation length]>0)
							{
								tRange.location+=[inRelativeLocation length]+3;
							}
							
							[BMReportingUtilities reportProblemTo:delegate
															 file:filePath_
															level:BM_PROBLEM_LEVEL_WARNING
															title:NSLocalizedStringFromTableInBundle(@"Menu Title: there should be a space before the ellipsis in German.",@"WarningsAndErrors",bundle_,@"") 
													  description:BM_ADDMENUPATH(tTitle)
															 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
														   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																   nil]];
						}
					}
				}
			}

		}
		
		if (analyzingApplicationMenu_==YES)
		{
			if (isEnglish_==YES)
			{
				// Check that the default strings have been replaced
				
				if ([tTitle isEqualToString:@"About NewApplication"]==YES ||
					[tTitle isEqualToString:@"Hide NewApplication"]==YES ||
					[tTitle isEqualToString:@"Quit NewApplication"]==YES)
				{
					[BMReportingUtilities reportProblemTo:delegate
													 file:filePath_
													level:BM_PROBLEM_LEVEL_ERROR
													title:NSLocalizedStringFromTableInBundle(@"Default title used for menu item.",@"WarningsAndErrors",bundle_,@"") 
											  description:BM_ADDMENUPATH(tTitle)
													 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
												   extras:nil];
				}
			}
			else if (isFrench_==YES)
			{
				// Check the A propos de accentuation
				
				if ([tTitle hasPrefix:@"A propos"]==YES)
				{
					tRange=NSMakeRange(0,1);
					
					if ([inRelativeLocation length]>0)
					{
						tRange.location+=[inRelativeLocation length]+3;
					}
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:filePath_
													level:BM_PROBLEM_LEVEL_WARNING
													title:NSLocalizedStringFromTableInBundle(@"There's a grave accent on the A of A propos.",@"WarningsAndErrors",bundle_,@"") 
											  description:BM_ADDMENUPATH(tTitle)
													 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
												   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
														   nil]];
				}
			}

		}
		
		if ([inMenuItem isKindOfClass:[BM_OSX_NSMenuItem class]]==YES)
		{
			BM_OSX_NSMenu * tSubMenu;
			
			tSubMenu=[inMenuItem submenu];
		
			if (tSubMenu!=nil)
			{
				[self analyzeMenu:tSubMenu relativeLocation:BM_ADDMENUPATH(tTitle)];
			}
		}
	}
}

- (void) analyzeMenu:(BM_OSX_NSMenu *) inMenu relativeLocation:(NSString *) inRelativeLocation
{
	NSArray * tMenuItemsArray;
	BOOL analyzingApplicationMenu=NO;
	
	if (analyzingApplicationMenu_==NO)
	{
		if (analyzingMainMenu_==YES)
		{
			// Application Menu?
		
			analyzingApplicationMenu=analyzingApplicationMenu_=([[inMenu name] isEqualToString:@"_NSAppleMenu"]==YES);
		}
	}
	
	tMenuItemsArray=[inMenu itemArray];
	
	for (BM_OSX_NSMenuItem * tMenuItem in tMenuItemsArray)
	{
		if (analyzingMainMenu_==YES)
		{
			if (isFrench_==YES)
			{
				// Check that the Edit menu has its accent
				
				NSString * tTitle;
				
				tTitle=[tMenuItem title];
				
				if (tTitle!=nil)
				{
					if ([tTitle isEqualToString:@"Edition"]==YES)
					{
						NSRange tRange;
						
						tRange=NSMakeRange(0,1);
						
						if ([inRelativeLocation length]>0)
						{
							tRange.location+=[inRelativeLocation length]+3;
						}
						
						[BMReportingUtilities reportProblemTo:delegate
														 file:filePath_
														level:BM_PROBLEM_LEVEL_WARNING
														title:NSLocalizedStringFromTableInBundle(@"There's an accent on the E of Edition.",@"WarningsAndErrors",bundle_,@"") 
												  description:[inRelativeLocation stringByAppendingFormat:@" > %@",tTitle]
														 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
													   extras:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
															   nil]];
					}
				}
			}
		}
			
		[self analyzeMenuItem:tMenuItem relativeLocation:inRelativeLocation];
	}
	
	if (analyzingApplicationMenu==YES)
	{
		analyzingApplicationMenu_=NO;
	}
}

- (void) analyzeTopLevelMenu:(BM_OSX_NSMenu *) inTopLevelMenu
{
	analyzingMainMenu_=([[inTopLevelMenu name] isEqualToString:@"_NSMainMenu"]==YES);
	
	[self analyzeMenu:inTopLevelMenu relativeLocation:@""];
}

- (void) checkObjectsWithObjectData:(BM_OSX_NSIBObjectData *) inObjectData ofFile:(NSString *) inPath forLanguage:(NSString *) inLanguage
{
	if (inObjectData!=nil)
	{
		NSArray * tAllMenus;
		
		[super checkObjectsWithObjectData:inObjectData ofFile:inPath forLanguage:inLanguage];
		
		tAllMenus=[inObjectData allMenus];
		
		if (tAllMenus!=nil)
		{
			for(BM_OSX_NSMenu * tMenu in tAllMenus)
			{
				[self analyzeTopLevelMenu:tMenu];
			}
		}
	}
}

@end
