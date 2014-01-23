/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMStringsCheckerController.h"

#import "BMReportingUtilities.h"

#import "BMStringUtilities.h"

NSString * const BM_STRINGS_INTERNATIONAL_LANGUAGE=@"International";

@implementation BMStringsCheckerController

- (id) initWithBundle:(NSBundle *) inBundle
{
	self=[super initWithBundle:inBundle];
	
	if (self!=nil)
	{
		fileManager_=[NSFileManager defaultManager];
		
		stringsFileChecker_=[[BMStringsFileChecker stringsFileChecker] retain];
	}
	
	return self;
}

- (void) dealloc
{
	[stringsFileChecker_ release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) canTestItemOfType:(NSUInteger) inType
{
	switch(inType)
	{
		case BM_BUNDLETYPE_APP_BUNDLE:
		case BM_BUNDLETYPE_FRAMEWORK:
		case BM_BUNDLETYPE_BUNDLE:
		case BM_BUNDLETYPE_PLUGIN:
		case BM_BUNDLETYPE_AUTOMATOR_ACTION:
		case BM_BUNDLETYPE_SPOTLIGHT_IMPORTER:
		case BM_BUNDLETYPE_PREFERENCES_PANE:
		case BM_BUNDLETYPE_IOS_APP_BUNDLE:
			return YES;
	}
	
	return NO;
}

- (NSMutableDictionary *) checkFolderAtPath:(NSString *) inFolderPath
{
	NSMutableDictionary * tMutableDictionary=nil;
	
	if (inFolderPath!=nil)
	{
		NSArray * tFolderContentsArray;
		NSUInteger tCount;
		NSString * tLocalizationName;
		BOOL isFrench=NO;
		BOOL isEnglish=NO;
		BOOL isJapanese=NO;
		
		tLocalizationName=[inFolderPath lastPathComponent];
		
		if ([tLocalizationName isEqualToString:@"Resources"]==YES)
		{
			tLocalizationName=BM_STRINGS_INTERNATIONAL_LANGUAGE;
		}
		else
		{
			tLocalizationName=[tLocalizationName stringByDeletingPathExtension];
		}
		
		if ([tLocalizationName isEqualToString:@"fr"]==YES ||
			[tLocalizationName isEqualToString:@"French"]==YES)
		{
			isFrench=YES;
		}
		else if ([tLocalizationName isEqualToString:@"en"]==YES ||
			[tLocalizationName isEqualToString:@"English"]==YES)
		{
			isEnglish=YES;
		}
		else if ([tLocalizationName isEqualToString:@"ja"]==YES ||
				 [tLocalizationName isEqualToString:@"Japanese"]==YES)
		{
			isJapanese=YES;
		}
		
		
		tFolderContentsArray=[fileManager_ contentsOfDirectoryAtPath:inFolderPath error:NULL];
	
		tCount=[tFolderContentsArray count];
		
		if (tCount>0)
		{
			/*NSString * tTitle;
			NSString * tDescription;*/
			
            tMutableDictionary=[NSMutableDictionary dictionary];
		
			for(NSString * tFileName in tFolderContentsArray)
			{
				NSString * tExtension;
				
				tExtension=[tFileName pathExtension];

				if ([tExtension isEqualToString:@"strings"]==YES)
				{
					NSDictionary * tAttributesDictionary;
					NSString * tAbsolutePath;
					
					tAbsolutePath=[inFolderPath stringByAppendingPathComponent:tFileName];
					
					// Check if it's a file or a folder
					
					tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
					
					if ([tAttributesDictionary fileType]==NSFileTypeRegular)
					{
						//NSLog(@"%@",tAbsolutePath);	// A VIRER
						
						if ([stringsFileChecker_ checkStringsFileAtPath:tAbsolutePath withDelegate:delegate]==YES)
						{
							NSDictionary * tStringsDictionary;
							
							tStringsDictionary=[NSDictionary dictionaryWithContentsOfFile:tAbsolutePath];
							
							if (tStringsDictionary!=nil)
							{
								// Check ellipsis
								
								NSEnumerator * tKeyEnumerator;
								
								tKeyEnumerator=[tStringsDictionary keyEnumerator];
								
								if (tKeyEnumerator!=nil)
								{
									NSString * tKey;
									
									while (tKey=[tKeyEnumerator nextObject])
									{
										NSString * tLocalizedString;
										NSRange tRange;
										
										tLocalizedString=[tStringsDictionary objectForKey:tKey];
										
										if ([tLocalizedString hasPrefix:@"http://"]==YES)
										{
											NSUInteger tLength;
											
											tLength=[tLocalizedString length];
											
											if (tLength>7)
											{
												NSRange tHostRange;
												
												tHostRange=[tLocalizedString rangeOfString:@"/" options:0 range:NSMakeRange(7,tLength-7)];
											
												if (tHostRange.location!=NSNotFound)
												{
													NSString * tURLShortened;
													NSURL * tURL;
													
													tURLShortened=[tLocalizedString substringToIndex:tHostRange.location];
													
													tURL=[NSURL URLWithString:tURLShortened];
													
													if (tURL!=nil)
													{
														NSString * tHostName;
														
														tHostName=[tURL host];
														
														if ([BMStringUtilities isIPaddress:tHostName]==YES)
														{
															[BMReportingUtilities reportProblemTo:delegate
																							 file:tAbsolutePath
																							level:BM_PROBLEM_LEVEL_WARNING
																							title:NSLocalizedStringFromTableInBundle(@"IPv4 address used for host. Use a host name instead.",@"WarningsAndErrors",bundle_,@"") 
																					  description:tLocalizedString
																							 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_STRINGS,nil]
																						   extras:[NSDictionary dictionaryWithObjectsAndKeys:tKey,BM_PROBLEM_EXTRA_KEY,
																								   nil]];
															
														}
														
													}
												}
											}
										}
										else
										{
											if (isJapanese==NO)
											{
												// Look for "..."
											
												tRange=[tLocalizedString rangeOfString:@"..."];
												
												if (tRange.location!=NSNotFound)
												{
													[BMReportingUtilities reportProblemTo:delegate
																					 file:tAbsolutePath
																					level:BM_PROBLEM_LEVEL_WARNING
																					title:NSLocalizedStringFromTableInBundle(@"Localized string using 3 dots instead of ellipsis.",@"WarningsAndErrors",bundle_,@"") 
																			  description:tLocalizedString
																					 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_STRINGS,nil]
																				   extras:[NSDictionary dictionaryWithObjectsAndKeys:tKey,BM_PROBLEM_EXTRA_KEY,
																																	 NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																																	 nil]];
												}
											}
										
											if (isFrench==YES || isEnglish==YES)
											{
												NSUInteger tLocation=0;
												NSUInteger tStringLength;
												static NSCharacterSet * sPunctuationSet=nil;
												static NSCharacterSet * sExceptionSet=nil;
												
												if (sPunctuationSet==nil)
												{
													sPunctuationSet=[[NSCharacterSet characterSetWithCharactersInString:@"?!:"] copy];
												}
												
												if (sExceptionSet==nil)
												{
													sExceptionSet=[[NSCharacterSet characterSetWithCharactersInString:@"([{|<>%="] copy];
												}
												
												tStringLength=[tLocalizedString length];
												
												do
												{
													tRange=[tLocalizedString rangeOfCharacterFromSet:sPunctuationSet options:0 range:NSMakeRange(tLocation,tStringLength-tLocation)];
													
													tLocation=tRange.location;
													
													if (tLocation!=NSNotFound)
													{
														unichar tFoundCharacter;
														
														tFoundCharacter=[tLocalizedString characterAtIndex:tLocation];
														
														if (tLocation>0)
														{
															unichar tCharacter;
															
															tCharacter=[tLocalizedString characterAtIndex:tLocation-1];
															
															if ([sExceptionSet characterIsMember:tCharacter]==NO)
															{	
																NSString * tTitle;
																
																if (isFrench==YES)
																{
																	if (tCharacter==' ')
																	{
																		tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Use a non-breaking space before '%@' in French.",@"WarningsAndErrors",bundle_,@""),[tLocalizedString substringWithRange:tRange]];
																		
																		[BMReportingUtilities reportProblemTo:delegate
																										 file:tAbsolutePath
																										level:BM_PROBLEM_LEVEL_WARNING
																										title:tTitle
																								  description:tLocalizedString
																										 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_STRINGS,nil]
																									   extras:[NSDictionary dictionaryWithObjectsAndKeys:tKey,BM_PROBLEM_EXTRA_KEY,
																											   NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																											   nil]];
																	}
																	else if (tCharacter!=0x00A0 && tCharacter!='@')	// 0x00A0 = non-breaking space
																	{
																		BOOL isException=NO;
																		
																		if (tFoundCharacter==':')
																		{
																			// Exceptions
																			
																			if (tLocation<([tLocalizedString length]-1))
																			{
																				unichar tNextChar;
																				
																				tNextChar=[tLocalizedString characterAtIndex:tLocation+1];
																				
																				if (tNextChar!=' ' && tNextChar!='\n')
																				{
																					isException=YES;
																				}
																			}

																			if (isException==NO)
																			{
																				
																			}
																		}
																		else if (tFoundCharacter=='!')
																		{
																			// Exceptions (Yahoo!)
																			
																			NSString * tSubString;
																			
																			tSubString=[tLocalizedString substringWithRange:NSMakeRange(0,tLocation)];
																			
																			if ([tSubString hasSuffix:@"Yahoo"]==YES)
																			{
																				isException=YES;
																			}
																		}
																		else if (tFoundCharacter=='?')
																		{
																			// Exceptions
																			
																			if (tLocation<([tLocalizedString length]-1))
																			{
																				unichar tNextChar;
																				
																				tNextChar=[tLocalizedString characterAtIndex:tLocation+1];
																				
																				if (tNextChar!=' ' && tNextChar!='\n')
																				{
																					isException=YES;
																				}
																			}
																			
																			if (isException==NO)
																			{
																				
																			}
																		}
																		
																		if (isException==NO)
																		{
																			tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"There is a non-breaking space before '%@' in French.",@"WarningsAndErrors",bundle_,@""),[tLocalizedString substringWithRange:tRange]];
																			
																			[BMReportingUtilities reportProblemTo:delegate
																											 file:tAbsolutePath
																											level:BM_PROBLEM_LEVEL_WARNING
																											title:tTitle
																									  description:tLocalizedString
																											 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_STRINGS,nil]
																										   extras:[NSDictionary dictionaryWithObjectsAndKeys:tKey,BM_PROBLEM_EXTRA_KEY,
																												   NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																												   nil]];
																		}
																	}
																	
																}
																else if (isEnglish==YES)
																{
																	if (tCharacter==' ' || tCharacter==0x00A0)
																	{
																		tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"There are no spaces before '%@' in English.",@"WarningsAndErrors",bundle_,@""),[tLocalizedString substringWithRange:tRange]];
																		
																		[BMReportingUtilities reportProblemTo:delegate
																										 file:tAbsolutePath
																										level:BM_PROBLEM_LEVEL_WARNING
																										title:tTitle
																								  description:tLocalizedString/*NSLocalizedStringFromTableInBundle(@"Header files in embedded frameworks are useless. Noone is going to use them.",@"WarningsAndErrors",bundle_,@"")*/
																										 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_STRINGS,nil]
																									   extras:[NSDictionary dictionaryWithObjectsAndKeys:tKey,BM_PROBLEM_EXTRA_KEY,
																											   NSStringFromRange(tRange),BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE,
																											   nil]];
																	}
																}
															}
														}
														
														tLocation+=1;
													}
													else
													{
														break;
													}

												}
												while (YES);
											}
										}
									}
								}
								else
								{
									// A COMPLETER
								}
								
								[tMutableDictionary setObject:[NSMutableDictionary dictionaryWithObject:tStringsDictionary forKey:tLocalizationName] forKey:tFileName];
							}
							else
							{
								// A COMPLETER
							}
						}
					}
				}
			}
		}
	}
	
	return tMutableDictionary;
}

- (void) checkFolderAtPath:(NSString *) inFolderPath isFramework:(BOOL) isFramework
{
	if (inFolderPath!=nil)
	{
		NSMutableDictionary * tLocalizedStringsFilesDictionary;
		NSMutableDictionary * tMutableDictionary;
		NSArray * tFolderContentsArray;
		NSEnumerator * tEnumerator;
		
		tLocalizedStringsFilesDictionary=[NSMutableDictionary dictionary];
		
		// Look for the non-localized strings
		
		tMutableDictionary=[self checkFolderAtPath:inFolderPath];
		
		if (tMutableDictionary!=nil)
		{
			[tLocalizedStringsFilesDictionary addEntriesFromDictionary:tMutableDictionary];
		}
		
		// Look for localized strings
		
		tFolderContentsArray=[fileManager_ contentsOfDirectoryAtPath:inFolderPath error:NULL];
		
		for(NSString * tFileName in tFolderContentsArray)
		{
			NSString * tExtension;
			
			tExtension=[tFileName pathExtension];
			
			if ([tExtension isEqualToString:@"lproj"]==YES)
			{
				NSDictionary * tAttributesDictionary;
				NSString * tAbsolutePath;
				
				tAbsolutePath=[inFolderPath stringByAppendingPathComponent:tFileName];
				
				// Verify that it's a folder
				
				tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
				
				if ([tAttributesDictionary fileType]==NSFileTypeDirectory)
				{
					tMutableDictionary=[self checkFolderAtPath:tAbsolutePath];
					
					if (tMutableDictionary!=nil)
					{
						NSEnumerator * tKeyEnumerator;
						
						// Merge the data
						
						tKeyEnumerator=[tMutableDictionary keyEnumerator];
						
						if (tKeyEnumerator!=nil)
						{
							NSString * tKeyPath;
							
							while (tKeyPath=[tKeyEnumerator nextObject])
							{
								NSMutableDictionary * tMergedDictionary;
								NSMutableDictionary * tLocalizedLanguageDictionary;
								
								tLocalizedLanguageDictionary=[tMutableDictionary objectForKey:tKeyPath];
								
								tMergedDictionary=[tLocalizedStringsFilesDictionary objectForKey:tKeyPath];
								
								if (tMergedDictionary==nil)
								{
									[tLocalizedStringsFilesDictionary setObject:tLocalizedLanguageDictionary forKey:tKeyPath];
								}
								else
								{
									NSString * tLanguage;
									
									tLanguage=[[tLocalizedLanguageDictionary allKeys] objectAtIndex:0];
									
									[tMergedDictionary setObject:[tLocalizedLanguageDictionary objectForKey:tLanguage] forKey:tLanguage];
								}
								
							}
						}
					}
				}
			}
		}
		
		tEnumerator=[tLocalizedStringsFilesDictionary keyEnumerator];
		
		if (tEnumerator!=nil)
		{
			NSString * tFileRelativePath;
			
			while (tFileRelativePath=[tEnumerator nextObject])
			{
				NSDictionary * tLanguageDictionary;
				
				tLanguageDictionary=[tLocalizedStringsFilesDictionary objectForKey:tFileRelativePath];
				
				if (tLanguageDictionary!=nil)
				{
					NSArray * tLanguagesArray;
					
					tLanguagesArray=[tLanguageDictionary allKeys];
					
					if ([tLanguagesArray count]>1)
					{
						if ([tLanguagesArray containsObject:BM_STRINGS_INTERNATIONAL_LANGUAGE]==YES)
						{
							NSString * tTitle;
							NSString * tDescription;
							
							tTitle=NSLocalizedStringFromTableInBundle(@"There are both non-localized and localized versions of this file.",@"WarningsAndErrors",bundle_,@"");
							
							tDescription=NSLocalizedStringFromTableInBundle(@"This can produce unwanted results.",@"WarningsAndErrors",bundle_,@"");
							
							[BMReportingUtilities reportProblemTo:delegate
															 file:[inFolderPath stringByAppendingPathComponent:tFileRelativePath]
															level:BM_PROBLEM_LEVEL_WARNING
															title:tTitle
													  description:tDescription
															 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_STRINGS,nil]
														   extras:nil];
						}
					}
				}
			}
		}
		
		// Analyse the data
		
		//NSLog(@"%@",tLocalizedStringsFilesDictionary);
	}
}

- (void) testItem:(id) inItem atPath:(NSString *) inPath ofType:(NSUInteger) inType withDelegate:(id) inDelegate
{	
	//NSLog(@"%@",inPath);	// A VIRER
	
	[super testItem:inItem atPath:inPath ofType:inType withDelegate:inDelegate];
		
	if (inType==BM_BUNDLETYPE_FRAMEWORK)
	{
		NSString * tVersionsFolderPath;
		NSArray * tVersionsContentArray;
		
		// Check all versions
		
		tVersionsFolderPath=[inPath stringByAppendingPathComponent:@"Versions"];
		
		tVersionsContentArray=[fileManager_ contentsOfDirectoryAtPath:tVersionsFolderPath error:NULL];
		
		for(NSString * tFileName in tVersionsContentArray)
		{
			NSString * tAbsolutePath;
			NSDictionary * tAttributesDictionary;
			
			tAbsolutePath=[tVersionsFolderPath stringByAppendingPathComponent:tFileName];
			
			tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
			
			if ([tAttributesDictionary fileType]==NSFileTypeDirectory)
			{
				NSString * tResourcesFolderPath;
				BOOL isDirectory;
				
				tResourcesFolderPath=[tAbsolutePath stringByAppendingPathComponent:@"Resources"];
				
				if ([fileManager_ fileExistsAtPath:tResourcesFolderPath isDirectory:&isDirectory]==YES && isDirectory==YES)
				{
					[self checkFolderAtPath:tResourcesFolderPath isFramework:YES];
				}
			}
		}
	}
	else
	{
		NSString * tResourcesFolderPath;
		
		if (inType==BM_BUNDLETYPE_IOS_APP_BUNDLE)
		{
			tResourcesFolderPath=inPath;
		}
		else
		{
			tResourcesFolderPath=[inPath stringByAppendingPathComponent:@"Contents/Resources"];
		}
		
		// Check first level of Resources
		
		[self checkFolderAtPath:tResourcesFolderPath isFramework:NO];
	}
}

@end
