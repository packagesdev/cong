/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMPropertyListFileChecker.h"

#import "BMReportingConstants.h"

#import "BMReportingUtilities.h"

#include "CFPropertyList_Debug.h"

NSString * const BM_PROPERTYLIST_KEY_TYPE=@"Type";

NSString * const BM_PROPERTYLIST_KEY_FORMAT=@"Format";

NSString * const BM_PROPERTYLIST_KEY_DEPRECATED=@"Deprecated";

NSString * const BM_PROPERTYLIST_KEY_DEPRECATED_OS_VERSION=@"DeprecatedByMacOSXVersion";

NSString * const BM_PROPERTYLIST_KEY_DEPRECATED_ALTERNATIVES=@"DeprecatedAlternatives";

NSString * const BM_PROPERTYLIST_KEY_PRIVATE=@"Private";

NSString * const BM_PROPERTYLIST_KEY_SHOULD_CONFORM_TO_FORMAT=@"ShouldConformToFormat";

NSString * const BM_PROPERTYLIST_KEY_CAN_NOT_BE_EMPTY=@"CanNotBeEmpty";

NSString * const BM_PROPERTYLIST_KEY_CHILDREN_VIRTUAL_KEY=@"ChildrenVirtualKey";

NSString * const BM_PROPERTYLIST_KEY_AUTHORIZED_CHILDREN_TYPES=@"AuthorizedChildrenTypes";

NSString * const BM_PROPERTYLIST_KEY_AUTHORIZED_CHILDREN_KEYS=@"AuthorizedChildrenKeys";

NSString * const BM_PROPERTYLIST_KEY_REQUIRED_CHILDREN_KEYS=@"RequiredChildrenKeys";

NSString * const BM_PROPERTYLIST_KEY_AUTHORIZED_VALUES=@"AuthorizedValues";

@implementation BMPropertyListFileChecker

- (id) initWithCheckListAtPath:(NSString *) inPath
{
	self=[super init];
	
	if (self!=nil)
	{
		checkListDictionary_=[NSDictionary dictionaryWithContentsOfFile:inPath];
		
		if (checkListDictionary_!=nil)
		{
			[checkListDictionary_ retain];
		}
		else
		{
			// A COMPLETER
		}
	}
	
	return self;
}

- (void) dealloc
{
	[checkedFilePath_ release];
	
	[checkListDictionary_ release];
	
	[super dealloc];
}

#pragma mark -

- (void) setProblemLevel:(NSUInteger) inLevel
{
	if (inLevel>problemLevel_)
	{
		problemLevel_=inLevel;
	}
}

- (NSUInteger) problemLevel
{
	return problemLevel_;
}

#pragma mark -

- (void) reportProblemLevel:(NSUInteger) inLevel title:(NSString *) inTitle description:(NSString *) inDescription
{
	[BMReportingUtilities reportProblemTo:delegate
									 file:checkedFilePath_
									level:inLevel
									title:inTitle
							  description:inDescription
									 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST]
									 extras:nil];
}

- (void) checkObject:(id) inObject forKey:(NSString *) inKey
{
	[self checkObject:inObject forKey:inKey supportDeviceSpecificKey:NO];
}

- (void) checkObject:(id) inObject forKey:(NSString *) inKey supportDeviceSpecificKey:(BOOL) inSupportDeviceSpecificKey
{
	NSDictionary * tKeyCheckList;
	NSString * tTitle;
	NSString * tDescription;
	
	tKeyCheckList=[checkListDictionary_ objectForKey:inKey];
	
	if (tKeyCheckList==nil && inSupportDeviceSpecificKey==YES)
	{
		if ([inKey hasSuffix:@"˜iphone"]==YES)
		{
			inKey=[inKey substringToIndex:[inKey length]-7];
		}
		else if ([inKey hasSuffix:@"˜ipod"]==YES)
		{
			inKey=[inKey substringToIndex:[inKey length]-5];
		}
		else if ([inKey hasSuffix:@"˜ipad"]==YES)
		{
			inKey=[inKey substringToIndex:[inKey length]-5];
		}
	}
	
	if (tKeyCheckList!=nil)
	{
		NSString * tTypeString;
		NSArray * tAuthorizedValues;
		NSString * tRealKey;
		NSNumber * tDeprecatedNumber;
		
		tRealKey=[[inKey componentsSeparatedByString:@"."] lastObject];
		
		if ([tRealKey isEqualToString:@"__ROOT__"]==YES)
		{
			tRealKey=@"property list";
		}
		
		tDeprecatedNumber=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_DEPRECATED];
		
		if ([tDeprecatedNumber boolValue]==YES)
		{
			NSArray * tArray;
			NSString * tOSVersion;
			NSArray * tAlternativesArray;
			NSMutableString * tAlternativeSuggestions=nil;
			NSUInteger tCount;
			
			[self setProblemLevel:BM_PROBLEM_LEVEL_WARNING];
			
			tAlternativesArray=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_DEPRECATED_ALTERNATIVES];
			
			tCount=[tAlternativesArray count];
			
			if (tCount>0)
			{
				NSUInteger i;
					
				tAlternativeSuggestions=[[[tAlternativesArray objectAtIndex:0] mutableCopy] autorelease];
					
				i=1;
					
				while (i<(tCount-1))
				{
					NSString * tOtherAlternative;
					
					tOtherAlternative=[tAlternativesArray objectAtIndex:i];
					
					[tAlternativeSuggestions appendFormat:NSLocalizedStringFromTable(@", %@",@"CommonPropertyList",@""),tOtherAlternative];
				}
				
				if (i>1)
				{
					[tAlternativeSuggestions appendFormat:NSLocalizedStringFromTable(@" and %@",@"CommonPropertyList",@""),[tAlternativesArray lastObject]];
				}
			}
			
			tOSVersion=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_DEPRECATED_OS_VERSION];
			
			if ([tOSVersion length]==0)
			{
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ is deprecated.",@"CommonPropertyList",@""),tRealKey];
				
			}
			else
			{
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ is deprecated in Mac OS X v%@.",@"CommonPropertyList",@""),tRealKey,tOSVersion];
			}

			if (tAlternativeSuggestions!=nil)
			{
				tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" Use %@ instead.",@"CommonPropertyList",@""),tAlternativeSuggestions];
			}
			
			tArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_DEPRECATED,BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,nil];
			
			BM_REPORT_WARNING_TAGS(delegate,checkedFilePath_,tTitle,nil,tArray);
		}
		
		tDeprecatedNumber=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_PRIVATE];
		
		if ([tDeprecatedNumber boolValue]==YES)
		{
			NSArray * tArray;
			
			[self setProblemLevel:BM_PROBLEM_LEVEL_ERROR];
			
			tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Private key \"%@\" used",@"CommonPropertyList",@""),tRealKey];
			
			tArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_DEPRECATED,BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,nil];
			
			BM_REPORT_ERROR_TAGS(delegate,checkedFilePath_,tTitle,nil,tArray);
		}
		
		// Check Type
		
		tTypeString=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_TYPE];
		
		if (tTypeString!=nil)
		{
			NSNumber * tFormatNumber;
			NSNumber * tCanNotBeEmptyNumber;
			
			if ([inObject isKindOfClass:NSClassFromString(tTypeString)]==NO)
			{
				[self setProblemLevel:BM_PROBLEM_LEVEL_ERROR];
				
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Invalid object type for key \"%@\"",@"CommonPropertyList",@""),tRealKey];
				
				tDescription=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Object is a %@ but should be a %@",@"CommonPropertyList",@""),NSStringFromClass([inObject class]),tTypeString];
				
				[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
								   title:tTitle
							 description:tDescription];
				
				return;
			}
			
			// Can not be empty
			
			tCanNotBeEmptyNumber=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_CAN_NOT_BE_EMPTY];
			
			if ([tCanNotBeEmptyNumber boolValue]==YES)
			{
				if ([inObject length]==0)
				{
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Empty object for key \"%@\"",@"CommonPropertyList",@""),tRealKey];
					
					[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
									   title:tTitle
								 description:@""];
				}
			}
			
			// Format
			
			tFormatNumber=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_FORMAT];
		
			if (tFormatNumber!=nil)
			{
				NSString * tClassName;
				Class tClass;
				
				tClassName=[NSString stringWithFormat:@"BM%@FormatUtilities",tTypeString];
				
				tClass=NSClassFromString(tClassName);
				
				if (tClass!=nil)
				{
					if ([tClass object:inObject conformsToFormat:[tFormatNumber unsignedLongValue]]==NO)		// A FAIRE (PROTOCOL A DEFINIR)
					{
						NSNumber * tNumber;
						NSUInteger tProblemLevel;
						
						tNumber=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_SHOULD_CONFORM_TO_FORMAT];
						
						tProblemLevel=([tNumber boolValue]==YES) ? BM_PROBLEM_LEVEL_ERROR : BM_PROBLEM_LEVEL_WARNING;
						
						[self setProblemLevel:tProblemLevel];
						
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Non conforming object value for key \"%@\"",@"CommonPropertyList",@""),tRealKey];
						
						tDescription=@"";		// A COMPLETER
						
						[self reportProblemLevel:tProblemLevel
										   title:tTitle
									 description:tDescription];
	
						if (tProblemLevel==BM_PROBLEM_LEVEL_ERROR)
						{	
							return;
						}
					}
				}
			}
		}
		
		// Authorized Values
		
		tAuthorizedValues=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_AUTHORIZED_VALUES];
		
		if (tAuthorizedValues!=nil)
		{
			if ([tAuthorizedValues containsObject:inObject]==NO)
			{
				[self setProblemLevel:BM_PROBLEM_LEVEL_ERROR];
				
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unauthorized object value for key \"%@\"",@"CommonPropertyList",@""),tRealKey];
						
				tDescription=@"";		// A COMPLETER
						
				[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
								   title:tTitle
							 description:tDescription];
				
				return;
			}
		}
		
		if ([inKey isEqualToString:@"__ROOT__"]==YES)
		{
			inKey=@"";
		}
		
		// Children
		
		if ([inObject isKindOfClass:[NSDictionary class]]==YES)
		{
			NSArray * tOnlyAuthorizedKeysArray;
			NSMutableArray * tRequiredKeysArray;
			NSUInteger tCount;
			NSEnumerator * tKeyEnumerator;
			
			tOnlyAuthorizedKeysArray=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_AUTHORIZED_CHILDREN_KEYS];
			
			tCount=[tOnlyAuthorizedKeysArray count];
			
			if (tCount>0)
			{
				NSMutableArray * tAllKeysMutable;
				
				tAllKeysMutable=[[[inObject allKeys] mutableCopy] autorelease];
				
				[tAllKeysMutable removeObjectsInArray:tOnlyAuthorizedKeysArray];
				
				tCount=[tAllKeysMutable count];
				
				if (tCount>0)
				{
					NSUInteger i;
					
					[self setProblemLevel:BM_PROBLEM_LEVEL_ERROR];
							
					for(i=0;i<tCount;i++)
					{
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unauthorized key \"%@\" used for the \"%@\" dictionary",@"CommonPropertyList",@""),[tAllKeysMutable objectAtIndex:i],tRealKey];	
						
						tDescription=@""; // A COMPLETER
							
						[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
									   title:tTitle
								 description:tDescription];
					}
					
					return;
				}
			}
			
			tRequiredKeysArray=[[[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_REQUIRED_CHILDREN_KEYS] mutableCopy] autorelease];
			
			tCount=[tRequiredKeysArray count];
			
			if (tCount>0)
			{
				[tRequiredKeysArray removeObjectsInArray:[inObject allKeys]];
				
				tCount=[tRequiredKeysArray count];
				
				if (tCount>0)
				{
					NSUInteger i;
					
					[self setProblemLevel:BM_PROBLEM_LEVEL_ERROR];
							
					for(i=0;i<tCount;i++)
					{
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Missing required \"%@\" for the \"%@\" dictionary",@"CommonPropertyList",@""),[tRequiredKeysArray objectAtIndex:i],tRealKey];	
						
						tDescription=@""; // A COMPLETER
						
						[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
										   title:tTitle
									 description:tDescription];
					}
					
					return;
				}
			}
			
			tKeyEnumerator=[inObject keyEnumerator];
			
			if (tKeyEnumerator!=nil)
			{
				NSString * tKey;
				
				while (tKey=[tKeyEnumerator nextObject])
				{
					[self checkObject:[inObject objectForKey:tKey] forKey:[NSString stringWithFormat:@"%@.%@",inKey,tKey] supportDeviceSpecificKey:inSupportDeviceSpecificKey];
					
					if ([self problemLevel]==BM_PROBLEM_LEVEL_ERROR)
					{
						return;
					}
				}
			}
		}
		else if ([inObject isKindOfClass:[NSArray class]]==YES)
		{
			NSString * tVirtualName;
			NSArray * tTypesArray;
			NSUInteger tCount;
			
			tTypesArray=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_AUTHORIZED_CHILDREN_TYPES];
			
			tCount=[tTypesArray count];
			
			if (tCount>0)
			{
				NSEnumerator * tObjectEnumerator;
				
				tObjectEnumerator=[inObject objectEnumerator];
				
				if (tObjectEnumerator!=nil)
				{
					id tObject;
					NSUInteger j;
					
					while (tObject=[tObjectEnumerator nextObject])
					{
						for(j=0;j<tCount;j++)
						{
							if ([tObject isKindOfClass:NSClassFromString([tTypesArray objectAtIndex:j])]==YES)
							{
								break;
							}
						}
					
						if (j==tCount)
						{
							tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Incorrect object type(s) for the \"%@\" array",@"CommonPropertyList",@""),tRealKey];
						
							tDescription=@""; // A COMPLETER
									
							[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
											   title:tTitle
										 description:tDescription];
							
							if ([self problemLevel]==BM_PROBLEM_LEVEL_ERROR)
							{
								return;
							}
						}
					}
				}
			}
			
			// Virtual Names
			
			tVirtualName=[tKeyCheckList objectForKey:BM_PROPERTYLIST_KEY_CHILDREN_VIRTUAL_KEY];
			
			if (tVirtualName!=nil)
			{
				NSUInteger i;
				
				tCount=[inObject count];
				
				for(i=0;i<tCount;i++)
				{
					[self checkObject:[inObject objectAtIndex:i] forKey:[NSString stringWithFormat:@"%@.%@",inKey,tVirtualName] supportDeviceSpecificKey:inSupportDeviceSpecificKey];
					
					if ([self problemLevel]==BM_PROBLEM_LEVEL_ERROR)
					{
						return;
					}
				}
			}
		}
	}
	/*else
	{
		if (inRoot==YES)
		{
			
		}
	}*/
}

- (BOOL) checkPropertyListFileAtPath:(NSString *) inPath withDelegate:(id) inDelegate
{
	return [self checkPropertyListFileAtPath:inPath withDelegate:inDelegate supportDeviceSpecificKey:NO];
}

- (BOOL) checkPropertyListFileAtPath:(NSString *) inPath withDelegate:(id) inDelegate supportDeviceSpecificKey:(BOOL) inSupportDeviceSpecificDevice
{
	NSData * tData;
	
	delegate=inDelegate;
	
	problemLevel_=0;
	
	[checkedFilePath_ release];
	
	checkedFilePath_=[inPath retain];
	
	tData=[NSData dataWithContentsOfFile:inPath];
	
	if (tData!=nil)
	{
		id tRootObject;
		NSPropertyListFormat tFormat;
		NSString * tErrorString;
		
		tRootObject=[NSPropertyListSerialization propertyListFromData:tData 
													 mutabilityOption:NSPropertyListImmutable
															   format:&tFormat
													 errorDescription:&tErrorString];
		
		if (tRootObject!=nil)
		{
			[self checkObject:tRootObject forKey:@"__ROOT__" supportDeviceSpecificKey:inSupportDeviceSpecificDevice];
			
			return ([self problemLevel]==0);
		}
		else
		{
			UInt32 tLineNumber;
			
			[tErrorString release];
			
			[self setProblemLevel:BM_PROBLEM_LEVEL_ERROR];
			
			FindParsingErrorWithData((CFDataRef) tData,(CFStringRef *) &tErrorString,&tLineNumber);
			
			if (tErrorString!=nil)
			{
				NSDictionary * tExtraDictionary;
				NSString * tLocalizedErrorString;
				
				tLocalizedErrorString=NSLocalizedStringFromTable(tErrorString,@"CommonPropertyList",@"");
				
				if (tLineNumber==-1)
				{
					tExtraDictionary=nil;
				}
				else
				{
					tLocalizedErrorString=[NSString stringWithFormat:tLocalizedErrorString,tLineNumber];
					
					tExtraDictionary=[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:tLineNumber] forKey:BM_PROBLEM_EXTRA_LINE_NUMBER];
				}
				
				[BMReportingUtilities reportProblemTo:delegate
												 file:checkedFilePath_
												level:BM_PROBLEM_LEVEL_ERROR
												title:tLocalizedErrorString
										  description:nil
												 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST]
											   extras:tExtraDictionary];
				
				[tErrorString release];
			}
			else
			{
				[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
								   title:NSLocalizedStringFromTable(@"Does not know how to read .plist file",@"CommonPropertyList",@"")
							 description:@""];
			}
		}
	}
	else
	{
		[self setProblemLevel:BM_PROBLEM_LEVEL_ERROR];
		
		[self reportProblemLevel:BM_PROBLEM_LEVEL_ERROR
						   title:NSLocalizedStringFromTable(@"Can not read file",@"Common",@"")
					 description:NSLocalizedStringFromTable(@"",@"Common",@"")];
	}
	
	return NO;
}

@end
