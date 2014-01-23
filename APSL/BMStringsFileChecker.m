/*
 * Copyright (c) 2005 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*	CFPropertyList.h
 Copyright (c) 1998-2005, Apple, Inc. All rights reserved.
 */

#import "BMStringsFileChecker.h"
#import "BMReportingUtilities.h"

typedef struct
{
    const unichar *begin; // first character of the XML to be parsed
    const unichar *curr;  // current parse location
    const unichar *end;   // the first character _after_ the end of the XML
	const unichar * startOfLine;   // the first character _after_ the end of the XML
    CFStringRef errorString;
	UInt32 lineNumber;
	NSUInteger errorNumber;
} BMParsingStruct;

// warning: doesn't have a good idea of Unicode line separators
static UInt32 lineNumber(BMParsingStruct *pInfo)
{
    const unichar *p = pInfo->begin;
    UInt32 count = 1;
	
    while (p < pInfo->curr)
	{
        if (*p == '\r')
		{
            count ++;
            if (*(p + 1) == '\n')
                p ++;
        }
		else if (*p == '\n')
		{
            count ++;
        }
		
        p ++;
    }
	
    return count;
}

#define isValidUnquotedStringCharacter(x) (((x) >= 'a' && (x) <= 'z') || ((x) >= 'A' && (x) <= 'Z') || ((x) >= '0' && (x) <= '9') || (x) == '_' || (x) == '$' || (x) == '/' || (x) == ':' || (x) == '.' || (x) == '-')

static void BMadvanceToNonSpace(BMParsingStruct *pInfo)
{
    unichar ch2;
	
    while (pInfo->curr < pInfo->end)
	{
		ch2 = *(pInfo->curr);
        pInfo->curr ++;
		
        if (ch2 >= 9 && ch2 <= 0x0d) continue;	// tab, newline, vt, form feed, carriage return
		
        if (ch2 == ' ' || ch2 == 0x2028 || ch2 == 0x2029) continue;	// space and Unicode line sep, para sep
		
		if (ch2 == '/')
		{
			if (pInfo->curr >= pInfo->end)
			{
				// whoops; back up and return
				pInfo->curr --;
				
				return;
			}
			else if (*(pInfo->curr) == '/')
			{
				pInfo->curr ++;
				
				while (pInfo->curr < pInfo->end)
				{	// go to end of comment line
					unichar ch3 = *(pInfo->curr);
					
					if (ch3 == '\n' || ch3 == '\r' || ch3 == 0x2028 || ch3 == 0x2029) break;
					pInfo->curr ++;
				}
			}
			else if (*(pInfo->curr) == '*')
			{	// handle /* ... */
				pInfo->curr ++;
				
				while (pInfo->curr < pInfo->end)
				{
					ch2 = *(pInfo->curr);
					
					pInfo->curr ++;
					
					if (ch2 == '*' && pInfo->curr < pInfo->end && *(pInfo->curr) == '/')
					{
						pInfo->curr ++; // advance past the '/'
						break;
					}
				}
			}
			else
			{
				pInfo->curr --;
				return;
			}
        }
		else
		{
            pInfo->curr --;
            return;
        }
    }
}

static unichar BMgetSlashedChar(BMParsingStruct *pInfo)
{
    unichar ch = *(pInfo->curr);
	
    pInfo->curr ++;
	
    switch (ch)
	{
		case '0':
		case '1':	
		case '2':	
		case '3':	
		case '4':	
		case '5':	
		case '6':	
		case '7': 
		{
			uint8_t num = ch - '0';
			unichar result;
			UInt32 usedCharLen;
			/* three digits maximum to avoid reading \000 followed by 5 as \5 ! */
			
			if ((ch = *(pInfo->curr)) >= '0' && ch <= '7')
			{ // we use in this test the fact that the buffer is zero-terminated
				pInfo->curr ++;
				num = (num << 3) + ch - '0';
				if ((pInfo->curr < pInfo->end) && (ch = *(pInfo->curr)) >= '0' && ch <= '7')
				{
					pInfo->curr ++;
					num = (num << 3) + ch - '0';
				}
			}
			
			CFStringEncodingBytesToUnicode(kCFStringEncodingNextStepLatin, 0, &num, sizeof(uint8_t), NULL,  &result, 1, &usedCharLen);
			
			return (usedCharLen == 1) ? result : 0;
		}
			
		case 'U':
		{
			unsigned num = 0, numDigits = 4;	/* Parse four digits */
			while (pInfo->curr < pInfo->end && numDigits--)
			{
				if (((ch = *(pInfo->curr)) < 128) && isxdigit(ch))
				{ 
					pInfo->curr ++;
					num = (num << 4) + ((ch <= '9') ? (ch - '0') : ((ch <= 'F') ? (ch - 'A' + 10) : (ch - 'a' + 10)));
				}
			}
			return num;
		}
			
		case 'a':	return '\a';	// Note: the meaning of '\a' varies with -traditional to gcc
		case 'b':	return '\b';
		case 'f':	return '\f';
		case 'n':	return '\n';
		case 'r':	return '\r';
		case 't':	return '\t';
		case 'v':	return '\v';
		case '"':	return '\"';
		case '\n':	return '\n';
    }
	
    return ch;
}

static void BMcatFromMarkToBuf(const UniChar *mark, const UniChar *buf, CFMutableStringRef *string, CFAllocatorRef allocator )
{
    if (!(*string))
	{
        *string = CFStringCreateMutable(allocator, 0);
    }
	
    CFStringAppendCharacters(*string, mark, buf-mark);
}

static CFStringRef BMparseQuotedPlistString(BMParsingStruct *pInfo, unichar quote)
{
    CFMutableStringRef str = NULL;
	const unichar *startMark = pInfo->curr;
    const unichar *mark = pInfo->curr;
	
    while (pInfo->curr < pInfo->end)
	{
		unichar ch = *(pInfo->curr);
		
        if (ch == quote) break;
		
        if (ch == '\\')
		{
            BMcatFromMarkToBuf(mark, pInfo->curr, &str, NULL);
			
			pInfo->curr ++;
			
            ch = BMgetSlashedChar(pInfo);
			
			CFStringAppendCharacters(str, &ch, 1);
			
            mark = pInfo->curr;
		}
		else
		{
			// Note that the original NSParser code was much more complex at this point, but it had to deal with 8-bit characters in a non-UniChar stream.  We always have UniChar (we translated the data by the system encoding at the very beginning, hopefully), so this is safe.
			
			pInfo->curr ++;
		}
    }
	
    if (pInfo->end <= pInfo->curr)
	{
        if (str) CFRelease(str);
		
		pInfo->curr = startMark;
			
		pInfo->errorNumber=BMSTRINGSFILECHECK_ERROR_REACHED_END_OF_STRING_WHILE_PARSING_QUOTED_STRING;
		
		pInfo->lineNumber=lineNumber(pInfo);
		
        return NULL;
    }
	
	if (!str)
	{
		BMcatFromMarkToBuf(mark, pInfo->curr, &str, NULL);
    }
	else
	{
        if (mark != pInfo->curr)
		{
            BMcatFromMarkToBuf(mark, pInfo->curr, &str, NULL);
        }
    }
	
    pInfo->curr ++;  // Advance past the quote character before returning.
	
	return str;
}

static CFStringRef BMparseUnquotedPlistString(BMParsingStruct *pInfo)
{
    const unichar *mark = pInfo->curr;
	
    while (pInfo->curr < pInfo->end)
	{
        unichar ch = *pInfo->curr;
		
        if (isValidUnquotedStringCharacter(ch))
		{
			pInfo->curr ++;
        }
		else
		{
			break;
		}
	}
	
    if (pInfo->curr != mark)
	{
        CFMutableStringRef str = CFStringCreateMutable(NULL, 0);
		CFStringAppendCharacters(str, mark, pInfo->curr - mark);
		return str;
    }
	
    pInfo->errorNumber = BMSTRINGSFILECHECK_ERROR_REACHED_END_OF_STRING;
	
	pInfo->lineNumber=0;
	
    return NULL;
}

static CFStringRef BMparsePlistString(BMParsingStruct *pInfo, BOOL requireObject)
{
    unichar ch;
	
    BMadvanceToNonSpace(pInfo);
	
    if (pInfo->curr >= pInfo->end)
	{
		if (requireObject==YES)
		{
			pInfo->errorNumber=BMSTRINGSFILECHECK_ERROR_REACHED_END_OF_STRING;
		}
		
		return NULL;
	}
	
	pInfo->startOfLine=pInfo->curr;
	
    ch = *(pInfo->curr);
	
    if (ch == '\'' || ch == '\"')
	{
        pInfo->curr ++;
		
        return BMparseQuotedPlistString(pInfo, ch);
    }
	else if (isValidUnquotedStringCharacter(ch))
	{
        return BMparseUnquotedPlistString(pInfo);
    }
	
	if (requireObject==YES)
	{
		//pInfo->errorString = CFStringCreateWithFormat(pInfo->allocator, NULL, CFSTR("Invalid string character at line %d"), lineNumber(pInfo));
			
		pInfo->errorNumber=BMSTRINGSFILECHECK_ERROR_INCOMPLETE_ENTRY;
			
		pInfo->lineNumber=lineNumber(pInfo);
    }
	
	return NULL;
}


#undef isValidUnquotedStringCharacter

@implementation BMStringsFileChecker

+ (id) stringsFileChecker
{
	BMStringsFileChecker * tStringsFileChecker;
	
	tStringsFileChecker=[BMStringsFileChecker new];
	
	return [tStringsFileChecker autorelease];
}

- (void) dealloc
{
	[path_ release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) parseString:(NSString *) inString
{
	if (inString!=nil)
	{
		CFStringRef tKey = NULL;
		BMParsingStruct tParsingStruct;
		BMParsingStruct * tParsingStructPtr=&tParsingStruct;
		NSUInteger tLength;
		UniChar * tBuffer;
		NSMutableSet * tMutableSet;
		NSString * tTitle=nil;
		
		tLength=[inString length];
		
		tBuffer=(UniChar *) CFStringGetCharactersPtr((CFStringRef) inString);
		
		if (tBuffer==NULL)
		{
			tBuffer=(UniChar *) malloc(tLength*sizeof(UniChar));
			
			if (tBuffer!=NULL)
			{
				CFStringGetCharacters((CFStringRef) inString,CFRangeMake(0,tLength),tBuffer);
				inString=nil;
			}
		}
		
		tParsingStructPtr->begin=tBuffer;
		tParsingStructPtr->end=tBuffer+tLength;
		tParsingStructPtr->curr=tBuffer;
		
		
		tParsingStructPtr->lineNumber=0;
		tParsingStructPtr->errorNumber=BMSTRINGSFILECHECK_ERROR_NO_ERROR;
		
		tKey = BMparsePlistString(tParsingStructPtr, NO);
		
		tMutableSet=[NSMutableSet set];
		
		while (tKey!=NULL)
		{
			// Check duplicate keys
			
			if ([tMutableSet containsObject:(NSString *) tKey]==NO)
			{
				[tMutableSet addObject:(NSString *) tKey];
			}
			else
			{
				const unichar * tempCur;
				
				tempCur=tParsingStructPtr->curr;
				
				tParsingStructPtr->curr=tParsingStructPtr->startOfLine;
				
				tParsingStructPtr->lineNumber=lineNumber(tParsingStructPtr);
				
				tParsingStructPtr->curr=tempCur;
				
				
				
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Key \"%@\" is redefined at line %lu",@"CommonString",@""),(NSString *) tKey,tParsingStructPtr->lineNumber];
				
				
				[BMReportingUtilities reportProblemTo:delegate
												 file:path_
												level:BM_PROBLEM_LEVEL_WARNING
												title:tTitle
										  description:@""
												 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
											   extras:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:tParsingStructPtr->lineNumber] forKey:BM_PROBLEM_EXTRA_LINE_NUMBER]];
				
			}

			// A COMPLETER
			
			CFRelease(tKey);
			
			BMadvanceToNonSpace(tParsingStructPtr);
			
			if (*tParsingStructPtr->curr == ';')
			{
				/* This is a strings file using the shortcut format */
				/* although this check here really applies to all plists. */
				
			}
			else if (*tParsingStructPtr->curr == '=')
			{
				CFStringRef tValue;
				
				tParsingStructPtr->curr ++;
				
				tValue=BMparsePlistString(tParsingStructPtr, YES);
				
				if (tValue==NULL)
				{
					break;
				}
				
				CFRelease(tValue);
			}
			else
			{
				tParsingStructPtr->errorNumber = BMSTRINGSFILECHECK_ERROR_UNEXPECTED_CHARACTER_EQUAL_OR_SEMICOLON_WANTED;
				
				tParsingStructPtr->lineNumber=lineNumber(tParsingStructPtr);
				
				break;
			}
			
			tKey = NULL;
			
			tParsingStructPtr->lineNumber=lineNumber(tParsingStructPtr);
			
			BMadvanceToNonSpace(tParsingStructPtr);
			
			if (*tParsingStructPtr->curr == ';')
			{
				tParsingStructPtr->curr ++;
				
				tKey = BMparsePlistString(tParsingStructPtr, NO);
			}
			else
			{
				tParsingStructPtr->errorNumber = BMSTRINGSFILECHECK_ERROR_UNEXPECTED_CHARACTER_SEMICOLON_WANTED;
			}
		}
		
		if (inString==nil)
		{
			free(tBuffer);
		}
		
		if (tParsingStructPtr->errorNumber!=BMSTRINGSFILECHECK_ERROR_NO_ERROR)
		{
			/*NSString * tDescription;*/
			
			switch(tParsingStructPtr->errorNumber)
			{
				case BMSTRINGSFILECHECK_ERROR_MISSGING_OPENING_QUOTE:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Missing opening quote (\") at line %lu",@"CommonString",@""),tParsingStructPtr->lineNumber];
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:path_
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:@""
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
												   extras:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:tParsingStructPtr->lineNumber] forKey:BM_PROBLEM_EXTRA_LINE_NUMBER]];
					
					break;
					
				case BMSTRINGSFILECHECK_ERROR_REACHED_END_OF_STRING_WHILE_PARSING_QUOTED_STRING:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Missing closing quote (\") at line %lu",@"CommonString",@""),tParsingStructPtr->lineNumber];
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:path_
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:@""
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
												   extras:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:tParsingStructPtr->lineNumber] forKey:BM_PROBLEM_EXTRA_LINE_NUMBER]];
					
					break;
					
				case BMSTRINGSFILECHECK_ERROR_REACHED_END_OF_STRING_IN_COMMENT:
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:path_
													level:BM_PROBLEM_LEVEL_ERROR
													title:NSLocalizedStringFromTable(@"Unexpected end of file reached. A comment may not be closed.",@"CommonString",@"")
											  description:@""
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
												   extras:nil];
					
					break;
					
					
				case BMSTRINGSFILECHECK_ERROR_REACHED_END_OF_STRING:
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:path_
													level:BM_PROBLEM_LEVEL_ERROR
													title:NSLocalizedStringFromTable(@"Unexpected end of file reached",@"CommonString",@"")
											  description:@""
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
												   extras:nil];
					
					break;
					
				case BMSTRINGSFILECHECK_ERROR_INCOMPLETE_ENTRY:
				case BMSTRINGSFILECHECK_ERROR_MISSING_FINAL_SEMICOLON:
				case BMSTRINGSFILECHECK_ERROR_UNEXPECTED_CHARACTER_SEMICOLON_WANTED:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Missing semicolon (;) at line %lu",@"CommonString",@""),tParsingStructPtr->lineNumber];
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:path_
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:@""
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
												   extras:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:tParsingStructPtr->lineNumber] forKey:BM_PROBLEM_EXTRA_LINE_NUMBER]];
					
					break;
					
				case BMSTRINGSFILECHECK_ERROR_UNEXPECTED_CHARACTER_EQUAL_OR_SEMICOLON_WANTED:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Missing semicolon (;) or equal (=) at line %lu",@"CommonString",@""),tParsingStructPtr->lineNumber];
					
					// A COMPLETER
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:path_
													level:BM_PROBLEM_LEVEL_ERROR
													title:tTitle
											  description:@""
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
												   extras:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:tParsingStructPtr->lineNumber] forKey:BM_PROBLEM_EXTRA_LINE_NUMBER]];
					
					break;
					
				case BMSTRINGSFILECHECK_ERROR_INVALID_UTF8_DATA:
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:path_
													level:BM_PROBLEM_LEVEL_ERROR
													title:NSLocalizedStringFromTable(@"Encoding issue",@"CommonString",@"")
											  description:@""
													 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
												   extras:nil];
					
					break;
			}
		}
		else
		{
			return YES;
		}
	}
	
	return NO;
}

#pragma mark -

- (BOOL) checkStringsFileAtPath:(NSString *) inPath withDelegate:(id) inDelegate
{
	if (inPath!=nil)
	{
		NSData * tData;
		
		[path_ release];
		
		path_=[inPath copy];
		
		delegate=inDelegate;
		
		tData=[NSData dataWithContentsOfFile:inPath];
		
		if (tData!=nil)
		{
			const unsigned char	* tBytes;
			NSUInteger tLength;
			NSStringEncoding tEncoding;
			NSString * tFileContent;
			
			tBytes=[tData bytes];
			
			tLength=[tData length];
			
			if (tLength > 6 &&
				(tBytes[0] == 'b' &&
				 tBytes[1] == 'p' &&
				 tBytes[2] == 'l' &&
				 tBytes[3] == 'i' &&
				 tBytes[4] == 's' &&
				 tBytes[5] == 't'))
            {
				// Binary Property List
				
				/*[BMReportingUtilities reportProblemTo:delegate
												 file:path_
												level:BM_PROBLEM_LEVEL_NOTE
												title:NSLocalizedStringFromTable(@"Binary property list format is not the recommended format for .strings files.",@"CommonString",@"")
										  description:@""
												 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
											   extras:nil];*/
				
				return YES;
            }
			else if (tLength > 2 &&
					 ((tBytes[0] == 0xFF && tBytes[1] == 0xFE) ||
					  (tBytes[0] == 0xFE && tBytes[1] == 0xFF)))
            {
				tEncoding = NSUnicodeStringEncoding;
            }
			else if (tLength > 2 && 
					 tBytes[0] == 0xEF && 
					 tBytes[1] == 0xBB &&
					 tBytes[2] == 0xBF)
            {
				tEncoding = NSUTF8StringEncoding;
            }
			else
            {
				tEncoding = NSASCIIStringEncoding;
            }
			
			tFileContent=[[NSString alloc] initWithData:tData encoding:tEncoding];
			
			if (tFileContent==nil && tEncoding==NSASCIIStringEncoding)
			{
				tEncoding = [NSString defaultCStringEncoding];
				
				tFileContent=[[NSString alloc] initWithData:tData encoding:tEncoding];
			}
			
			if (tFileContent!=nil)
			{
				[tFileContent autorelease];
				
				if ([tFileContent length]==0)
				{
					return YES;
				}
				else
				{
					// Check if it's actually a propertyList or a traditional format
					
					if ([tFileContent hasPrefix:@"<?xml"]==YES ||
						[tFileContent hasPrefix:@"<!DOCTYPE"]==YES ||
						[tFileContent hasPrefix:@"<plist"]==YES)
					{
						// It's probably a PropertyList format
						
						[BMReportingUtilities reportProblemTo:delegate
														 file:path_
														level:BM_PROBLEM_LEVEL_NOTE
														title:NSLocalizedStringFromTable(@"XML property list format is not the recommended format for .strings files.",@"CommonString",@"")
												  description:@""
														 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
													   extras:nil];
						
						return YES;
					}
					else
					{
						if (tEncoding != NSUnicodeStringEncoding)
						{
							[BMReportingUtilities reportProblemTo:delegate
															 file:path_
															level:BM_PROBLEM_LEVEL_NOTE
															title:NSLocalizedStringFromTable(@"It is recommended to use UTF-16 encoding for .strings file.",@"CommonString",@"")
													  description:@""
															 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
														   extras:nil];
						}
						
						// It's probably a traditional format
						
						return [self parseString:tFileContent];
					}
				}
			}
			else
			{
				[BMReportingUtilities reportProblemTo:delegate
												 file:path_
												level:BM_PROBLEM_LEVEL_ERROR
												title:NSLocalizedStringFromTable(@"Encoding issue",@"CommonString",@"")
										  description:@""
												 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
											   extras:nil];
			}
		}
		else
		{
			[BMReportingUtilities reportProblemTo:delegate
											 file:path_
											level:BM_PROBLEM_LEVEL_ERROR
											title:NSLocalizedStringFromTable(@"Can not read file",@"Common",@"")
									  description:@""
											 tags:[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_STRINGS]
										   extras:nil];
		}
	}
	
	return NO;
}

@end
