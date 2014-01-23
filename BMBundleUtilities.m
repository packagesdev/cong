/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMBundleUtilities.h"

#import "BMFilesHierarchyUtilities.h"
#import "BMReportingUtilities.h"

@implementation BMBundleUtilities

+ (NSUInteger) bundleTypeAtPath:(NSString *) inPath
{
	if (inPath!=nil)
	{
		static NSDictionary * tSupportedExtensions=nil;
		
		if (tSupportedExtensions==nil)
		{
			tSupportedExtensions=[[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_APP_BUNDLE],@"app",
																			  [NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_FRAMEWORK],@"framework",
																			  [NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_BUNDLE],@"saver",
																			  [NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_BUNDLE],@"bundle",
																			  [NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_PLUGIN],@"plugin",
																			  [NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_AUTOMATOR_ACTION],@"action",
																			  [NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_SPOTLIGHT_IMPORTER],@"mdimporter",
																			  [NSNumber numberWithUnsignedInteger:BM_BUNDLETYPE_PREFERENCES_PANE],@"prefPane",
																			  nil];
		}
		
		if (tSupportedExtensions!=nil)
		{
			NSNumber * tNumber;
			
			tNumber=[tSupportedExtensions objectForKey:[inPath pathExtension]];
			
			if (tNumber!=nil)
			{
				if ([tNumber unsignedIntegerValue]==BM_BUNDLETYPE_APP_BUNDLE)
				{
					if ([[NSFileManager defaultManager] fileExistsAtPath:[inPath stringByAppendingPathComponent:[[inPath lastPathComponent] stringByDeletingPathExtension]]]==YES)
					{
						return BM_BUNDLETYPE_IOS_APP_BUNDLE;
					}
				}
				
				return [tNumber unsignedIntegerValue];
			}
		}
	}
	
	return BM_BUNDLETYPE_BUNDLE;
}

+ (BOOL) checkStructureOfBundleAtPath:(NSString *) inPath withDelegate:(id) inDelegate
{
	if (inPath!=nil)
	{
		switch([BMBundleUtilities bundleTypeAtPath:inPath])
		{
			case BM_BUNDLETYPE_APP_BUNDLE:
			case BM_BUNDLETYPE_PREFERENCES_PANE:
			
				return [BMBundleUtilities checkStructureOfStandardBundleAtPath:inPath withDelegate:inDelegate];
				
			case BM_BUNDLETYPE_FRAMEWORK:
			
				return [BMBundleUtilities checkStructureOfVersionedBundleAtPath:inPath withDelegate:inDelegate];
		
			case BM_BUNDLETYPE_IOS_APP_BUNDLE:
				
				return [BMBundleUtilities checkStructureOfiOSAppBundleAtPath:inPath withDelegate:inDelegate];
		}
	}

	return NO;
}

#pragma mark -

+ (void) checkForLanguageDoublon:(NSArray *) inLanguages forResourcesFolderAtPath:(NSString *) inResourcesFolderPath withDelegate:(id) inDelegate
{
	static NSDictionary * sLanguageLookupDictionary=nil;
	
	if (sLanguageLookupDictionary==nil)
	{
		NSString * tPath;
		
		tPath=[[NSBundle mainBundle] pathForResource:@"OldNewLanguage" ofType:@"plist"];
		
		if (tPath!=nil)
		{
			sLanguageLookupDictionary=[[NSDictionary alloc] initWithContentsOfFile:tPath];
		}
	}
	
	if (sLanguageLookupDictionary!=nil)
	{
		for(NSString * tLanguageName in inLanguages)
		{
			NSString * tOldLanguageName;
			
			tOldLanguageName=[sLanguageLookupDictionary objectForKey:tLanguageName];
			
			if (tOldLanguageName!=nil)
			{
				NSUInteger tIndex;
				
				tIndex=[inLanguages indexOfObject:tOldLanguageName];
				
				if (tIndex!=NSNotFound)
				{
					NSString * tTitle;
					NSString * tMessage;
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"The %@.lproj folder was also found.",@"Common",@""),tOldLanguageName];
					
					tMessage=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Including both the %@.lproj and %@.lproj folders will lead to unexpected results.",@"Common",@""),tLanguageName,tOldLanguageName];
					
					[BMReportingUtilities reportProblemTo:inDelegate
													 file:[inResourcesFolderPath stringByAppendingPathComponent:[tLanguageName stringByAppendingPathExtension:@"lproj"]]
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:tMessage
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_LOCALIZATION]
												   extras:nil];
				}
			}
		}
	}
}

#pragma mark -

+ (BOOL) checkStructureOfStandardBundleAtPath:(NSString *) inPath withDelegate:(id) inDelegate
{
	BOOL tProblemFound=NO;
	
	if (inPath!=nil)
	{
		NSString * tContentsPath;
		NSString * tResourcesPath;
		NSFileManager * tFileManager;
		BOOL isDirectory;
		NSString * tTitle;
		
		tFileManager=[NSFileManager defaultManager];
		
		// Contents
		
		tContentsPath=[inPath stringByAppendingPathComponent:@"Contents"];
		
		if ([tFileManager fileExistsAtPath:tContentsPath isDirectory:&isDirectory]==NO)
		{
			tProblemFound=YES;
			
			tTitle=NSLocalizedStringFromTable(@"Folder not found",@"Common",@"");
		
			[BMReportingUtilities reportProblemTo:inDelegate
											 file:tContentsPath
											level:BM_PROBLEM_LEVEL_ERROR
											title:tTitle
									  description:@""];
		}
		else
		{
			if (isDirectory==NO)
			{
				tProblemFound=YES;
				
				tTitle=NSLocalizedStringFromTable(@"Folder expected",@"Common",@"");
				
				[BMReportingUtilities reportProblemTo:inDelegate
												 file:tContentsPath
												level:BM_PROBLEM_LEVEL_ERROR
												title:tTitle
										  description:@""];
			}
			else
			{
				NSString * tMacOSPath;
				
				// Contents/MacOS
				
				tMacOSPath=[tContentsPath stringByAppendingPathComponent:@"MacOS"];
		
				if ([tFileManager fileExistsAtPath:tMacOSPath isDirectory:&isDirectory]==NO)
				{
					tProblemFound=YES;
					
					tTitle=NSLocalizedStringFromTable(@"Folder not found",@"Common",@"");
				
					[BMReportingUtilities reportProblemTo:inDelegate
													 file:tMacOSPath
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:@""];
				}
				else
				{
					if (isDirectory==NO)
					{
						tProblemFound=YES;
						
						tTitle=NSLocalizedStringFromTable(@"Folder expected",@"Common",@"");
						
						[BMReportingUtilities reportProblemTo:inDelegate
														 file:tMacOSPath
														level:BM_PROBLEM_LEVEL_ERROR
														title:tTitle
												  description:@""];
					}
					else
					{
						NSString * tInfoPlistPath;
						
						// Contents/Info.plist
						
						tInfoPlistPath=[tContentsPath stringByAppendingPathComponent:@"Info.plist"];
						
						if ([tFileManager fileExistsAtPath:tInfoPlistPath isDirectory:&isDirectory]==NO)
						{
							tInfoPlistPath=[tContentsPath stringByAppendingPathComponent:@"info.plist"];
						
							/*if ([tFileManager fileExistsAtPath:tInfoPlistPath]==YES)
							{
								// A COMPLETER
							}
							else*/
							{
								tProblemFound=YES;
								
								tTitle=NSLocalizedStringFromTable(@"File not found",@"Common",@"");
				
								[BMReportingUtilities reportProblemTo:inDelegate
																 file:tInfoPlistPath
																level:BM_PROBLEM_LEVEL_ERROR
																title:tTitle
														  description:@""
																 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST]
															   extras:nil];
							}
						}
						else
						{
							if (isDirectory==YES)
							{
								tProblemFound=YES;
								
								tTitle=NSLocalizedStringFromTable(@"File expected",@"Common",@"");
						
								[BMReportingUtilities reportProblemTo:inDelegate
																  file:tInfoPlistPath
																 level:BM_PROBLEM_LEVEL_ERROR
																 title:tTitle
														   description:@""];
							}
						}
					}
				}
				
				// Contents/Resources
				
				tResourcesPath=[tContentsPath stringByAppendingPathComponent:@"Resources"];
				
				if ([tFileManager fileExistsAtPath:tResourcesPath isDirectory:&isDirectory]==YES)
				{
					if (isDirectory==NO)
					{
						tProblemFound=YES;
						
						tTitle=NSLocalizedStringFromTable(@"File expected",@"Common",@"");
						
						[BMReportingUtilities reportProblemTo:inDelegate
														 file:tResourcesPath
														level:BM_PROBLEM_LEVEL_ERROR
														title:tTitle
												  description:@""];
					}
					else
					{
						NSArray * tLocalizationsArray;
						
						tLocalizationsArray=[BMFilesHierarchyUtilities allLocalizationNamesAtPath:tResourcesPath];
						
						[BMBundleUtilities checkForLanguageDoublon:tLocalizationsArray forResourcesFolderAtPath:tResourcesPath withDelegate:inDelegate];
					}

				}
			}
		}
	}
	
	return (tProblemFound==NO);
}

// A COMPLETER (Support des Umbrella Frameworks)

+ (BOOL) checkStructureOfVersionedBundleAtPath:(NSString *) inPath withDelegate:(id) inDelegate
{
	BOOL tCheckSucceeded=NO;
	
	if (inPath!=nil)
	{
		NSFileManager * tFileManager;
		NSString * tFrameworkName;
		NSArray * tContents;
		NSMutableDictionary * tSymbolicLinkMutableDictionary;
		NSArray * tCommonLinksArray;
		NSString * tTitle;
		
		tCheckSucceeded=YES;
		
		tFileManager=[NSFileManager defaultManager];
		
		tFrameworkName=[[inPath lastPathComponent] stringByDeletingPathExtension];
		
		// Inspect first level
		
		tContents=[tFileManager contentsOfDirectoryAtPath:inPath error:NULL];
		
		if ([tContents containsObject:tFrameworkName]==NO)
		{
			tCheckSucceeded=NO;
			
			tTitle=NSLocalizedStringFromTable(@"Symbolic link not found",@"Common",@"");
				
			[BMReportingUtilities reportProblemTo:inDelegate
											 file:[inPath stringByAppendingPathComponent:tFrameworkName]
											level:BM_PROBLEM_LEVEL_ERROR
											title:tTitle
									  description:@""];
		}
		
		if ([tContents containsObject:@"Versions"]==NO)
		{
			tCheckSucceeded=NO;
			
			tTitle=NSLocalizedStringFromTable(@"Folder not found",@"Common",@"");
				
			[BMReportingUtilities reportProblemTo:inDelegate
											 file:[inPath stringByAppendingPathComponent:@"Versions"]
											level:BM_PROBLEM_LEVEL_ERROR
											title:tTitle
									  description:@""];
		}
		
		tCommonLinksArray=[NSArray arrayWithObjects:tFrameworkName,
													@"Frameworks",
													@"Resources",
													@"Headers",
													nil];
															
		
		tSymbolicLinkMutableDictionary=[NSMutableDictionary dictionary];
		
		for(NSString * tFileName in tContents)
		{
			NSString * tAbsolutePath;
			NSDictionary * tAttributesDictionary;
			
			tAbsolutePath=[inPath stringByAppendingPathComponent:tFileName];
				
			tAttributesDictionary=[tFileManager attributesOfItemAtPath:tAbsolutePath error:NULL];
			
			if ([[tAttributesDictionary fileType] isEqualToString:NSFileTypeSymbolicLink]==YES)
			{
				if ([tFileName isEqualToString:@"Versions"]==YES)
				{
					// It can not be a symbolic link
					
					tCheckSucceeded=NO;
					
					tTitle=NSLocalizedStringFromTable(@"Must not be a symbolic link",@"Common",@"");
							
					[BMReportingUtilities reportProblemTo:inDelegate
													 file:[inPath stringByAppendingPathComponent:tFileName]
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:@""];
				}
				else
				{	
					// Check that the link is relative
					
					NSString * tSymbolicLinkRelativePath;
					
					tSymbolicLinkRelativePath=[tFileManager destinationOfSymbolicLinkAtPath:tAbsolutePath error:NULL];
					
					if (tSymbolicLinkRelativePath!=nil)
					{
						if ([tSymbolicLinkRelativePath characterAtIndex:0]=='/')
						{
							// Can not be an absolute link
							
							tCheckSucceeded=NO;
							
							tTitle=NSLocalizedStringFromTable(@"Symbolic link reference must be relative",@"Common",@"");
					
							[BMReportingUtilities reportProblemTo:inDelegate
															 file:tAbsolutePath
															level:BM_PROBLEM_LEVEL_ERROR
															title:tTitle
													  description:@""];
						}
						else
						{
							// Check that the path exists
							
							NSString * tSymbolicLinkAbsolutePath;
							
							tSymbolicLinkAbsolutePath=[[tAbsolutePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:tSymbolicLinkRelativePath];
							
							if (tSymbolicLinkAbsolutePath!=nil)
							{
								if ([tFileManager fileExistsAtPath:tSymbolicLinkAbsolutePath]==NO)
								{
									// Referenced file does not exist
									
									tCheckSucceeded=NO;
									
									tTitle=NSLocalizedStringFromTable(@"File referenced by symbolic link not found",@"Common",@"");
					
									[BMReportingUtilities reportProblemTo:inDelegate
																	 file:tAbsolutePath
																	level:BM_PROBLEM_LEVEL_ERROR
																	title:tTitle
															  description:@""];
								}
								else
								{
									if ([tCommonLinksArray containsObject:tFileName]==YES)
									{
										[tSymbolicLinkMutableDictionary setObject:tSymbolicLinkAbsolutePath forKey:tFileName];
									}
								}
							}
							else
							{
								// A COMPLETER
							}
						}
					}
				}
			}
			else
			{
				if ([tFileName isEqualToString:tFrameworkName]==YES)
				{
					// It has to be a symbolic link
					
					tCheckSucceeded=NO;
					
					tTitle=NSLocalizedStringFromTable(@"Symbolic link expected",@"Common",@"");
						
					[BMReportingUtilities reportProblemTo:inDelegate
													 file:[inPath stringByAppendingPathComponent:tFileName]
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:@""];
				}
				else if ([tFileName isEqualToString:@"Versions"]==YES)
				{
					NSString * tVersionsFolderPath;
					BOOL isDirectory;
					
					tVersionsFolderPath=[inPath stringByAppendingPathComponent:tFileName];
				
					[tFileManager fileExistsAtPath:tVersionsFolderPath isDirectory:&isDirectory];
					
					if (isDirectory==NO)
					{
						tCheckSucceeded=NO;
							
						tTitle=NSLocalizedStringFromTable(@"Folder expected",@"Common",@"");
						
						[BMReportingUtilities reportProblemTo:inDelegate
														 file:tVersionsFolderPath
														level:BM_PROBLEM_LEVEL_ERROR
														title:tTitle
												  description:@""];
					}
					else
					{
						// Go One level deeper
					
						NSString * tCurrentFolderPath;
						
						tCurrentFolderPath=[tVersionsFolderPath stringByAppendingPathComponent:@"Current"];
						
						if ([tFileManager fileExistsAtPath:tCurrentFolderPath]==NO)
						{
							// Missing Current Symbolic Link
							
							tCheckSucceeded=NO;
							
							tTitle=NSLocalizedStringFromTable(@"Symbolic link not found",@"Common",@"");
							
							[BMReportingUtilities reportProblemTo:inDelegate
															 file:tCurrentFolderPath
															level:BM_PROBLEM_LEVEL_ERROR
															title:tTitle
													  description:@""];
						}
						else
						{
							NSDictionary * tAttributesDictionary;
							
							tAttributesDictionary=[tFileManager attributesOfItemAtPath:tCurrentFolderPath error:NULL];
					
							if ([[tAttributesDictionary fileType] isEqualToString:NSFileTypeSymbolicLink]==YES)
							{
								// Check that the link is relative
					
								NSString * tSymbolicLinkRelativePath;
								
								tSymbolicLinkRelativePath=[tFileManager destinationOfSymbolicLinkAtPath:tAbsolutePath error:NULL];
								
								if (tSymbolicLinkRelativePath!=nil)
								{
									if ([tSymbolicLinkRelativePath characterAtIndex:0]=='/')
									{
										// Can not be an absolute link
										
										tCheckSucceeded=NO;
										
										tTitle=NSLocalizedStringFromTable(@"Symbolic link reference must be relative",@"Common",@"");
								
										[BMReportingUtilities reportProblemTo:inDelegate
																		 file:tAbsolutePath
																		level:BM_PROBLEM_LEVEL_ERROR
																		title:tTitle
																  description:@""];
									}
									else
									{
										// Check that the path exists
										
										NSString * tSymbolicLinkAbsolutePath;
										
										tSymbolicLinkAbsolutePath=[[tAbsolutePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:tSymbolicLinkRelativePath];
										
										if (tSymbolicLinkAbsolutePath!=nil)
										{
											if ([tFileManager fileExistsAtPath:tSymbolicLinkAbsolutePath]==NO)
											{
												// Referenced file does not exist
												
												tCheckSucceeded=NO;
												
												tTitle=NSLocalizedStringFromTable(@"File referenced by symbolic link not found",@"Common",@"");
								
												[BMReportingUtilities reportProblemTo:inDelegate
																				 file:tAbsolutePath
																				level:BM_PROBLEM_LEVEL_ERROR
																				title:tTitle
																		  description:@""];
											}
											else
											{
												NSEnumerator * tKeyEnumerator;
												
												tKeyEnumerator=[tSymbolicLinkMutableDictionary keyEnumerator];
												
												if (tKeyEnumerator!=nil)
												{
													NSString * tKey;
													
													while (tKey=[tKeyEnumerator nextObject])
													{
														NSString * tAbsolutePath;
														
														tAbsolutePath=[tSymbolicLinkMutableDictionary objectForKey:tKey];
														
														if ([[tAbsolutePath stringByDeletingLastPathComponent] isEqualToString:tSymbolicLinkAbsolutePath]==NO)
														{
															// The link does not point to the current version
														
															tCheckSucceeded=NO;
															
															tTitle=NSLocalizedStringFromTable(@"Not a reference to the current version",@"Common",@"");
						
															[BMReportingUtilities reportProblemTo:inDelegate
																							 file:[inPath stringByAppendingPathComponent:tKey]
																							level:BM_PROBLEM_LEVEL_ERROR
																							title:tTitle
																					  description:@""];
														}
													}
												}
											}
										}
										else
										{
											// A COMPLETER
										}
									}
								}
							}
							else
							{
								// It has to be a symbolic link
								
								tCheckSucceeded=NO;
								
								tTitle=NSLocalizedStringFromTable(@"Symbolic link expected",@"Common",@"");
							
								[BMReportingUtilities reportProblemTo:inDelegate
																 file:tCurrentFolderPath
																level:BM_PROBLEM_LEVEL_ERROR
																title:tTitle
														  description:@""];
							}
						}
					}
				}
			}
		}
	}
	
	return tCheckSucceeded;
}

+ (BOOL) checkStructureOfiOSAppBundleAtPath:(NSString *) inPath withDelegate:(id) inDelegate
{
	if (inPath!=nil)
	{
		NSFileManager * tFileManager;
		NSString * tExecutablePath;
		BOOL isDirectory;
		NSString * tTitle;
		
		tFileManager=[NSFileManager defaultManager];
		
		// Executable File
		
		tExecutablePath=[inPath stringByAppendingPathComponent:[[inPath lastPathComponent] stringByDeletingPathExtension]];
		
		if ([tFileManager fileExistsAtPath:tExecutablePath isDirectory:&isDirectory]==NO)
		{
			tTitle=NSLocalizedStringFromTable(@"Executable not found",@"Common",@"");
			
			[BMReportingUtilities reportProblemTo:inDelegate
											 file:tExecutablePath
											level:BM_PROBLEM_LEVEL_ERROR
											title:tTitle
									  description:@""];
		}
		else
		{
			if (isDirectory==YES)
			{
				tTitle=NSLocalizedStringFromTable(@"File expected",@"Common",@"");
				
				[BMReportingUtilities reportProblemTo:inDelegate
												 file:tExecutablePath
												level:BM_PROBLEM_LEVEL_ERROR
												title:tTitle
										  description:@""];
			}
			else
			{
				NSString * tInfoPlistPath;
				
				// Contents/Info.plist
				
				tInfoPlistPath=[inPath stringByAppendingPathComponent:@"Info.plist"];
				
				if ([tFileManager fileExistsAtPath:tInfoPlistPath isDirectory:&isDirectory]==NO)
				{
					tInfoPlistPath=[inPath stringByAppendingPathComponent:@"info.plist"];
					
					/*if ([tFileManager fileExistsAtPath:tInfoPlistPath]==YES)
					 {
					 // A COMPLETER
					 }
					 else*/
					{
						tTitle=NSLocalizedStringFromTable(@"File not found",@"Common",@"");
						
						[BMReportingUtilities reportProblemTo:inDelegate
														 file:tInfoPlistPath
														level:BM_PROBLEM_LEVEL_ERROR
														title:tTitle
												  description:@""
														 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST]
													   extras:nil];
					}
				}
				else
				{
					if (isDirectory==YES)
					{
						tTitle=NSLocalizedStringFromTable(@"File expected",@"Common",@"");
						
						[BMReportingUtilities reportProblemTo:inDelegate
														 file:tInfoPlistPath
														level:BM_PROBLEM_LEVEL_ERROR
														title:tTitle
												  description:@""];
					}
					
					return YES;
				}
			}
		}
	}
	
	return NO;
}


@end
