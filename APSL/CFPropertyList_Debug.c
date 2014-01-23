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
/*	CFPropertyList.c
	Copyright 1999-2002, Apple, Inc. All rights reserved.
	Responsibility: Christopher Kane
*/

#include "CFPropertyList_Debug.h"
#include <CoreFoundation/CFDate.h>
#include <CoreFoundation/CFNumber.h>
#include <CoreFoundation/CFSet.h>
#include "CFInternal_Debug.h"

#include <limits.h>
#include <float.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>

Boolean __CFDebugIsWhitespace(UniChar theChar)
{
    return ((theChar < 0x21) || (theChar > 0x7E && theChar < 0xA1) || (theChar >= 0x2000 && theChar <= 0x200B) || (theChar == 0x3000)) ? true : false;
}

#define PLIST_IX    0
#define ARRAY_IX    1
#define DICT_IX     2
#define KEY_IX      3
#define STRING_IX   4
#define DATA_IX     5
#define DATE_IX     6
#define REAL_IX     7
#define INTEGER_IX  8
#define TRUE_IX     9
#define FALSE_IX    10
#define DOCTYPE_IX  11
#define CDSECT_IX   12

#define PLIST_TAG_LENGTH	5
#define ARRAY_TAG_LENGTH	5
#define DICT_TAG_LENGTH		4
#define KEY_TAG_LENGTH		3
#define STRING_TAG_LENGTH	6
#define DATA_TAG_LENGTH		4
#define DATE_TAG_LENGTH		4
#define REAL_TAG_LENGTH		4
#define INTEGER_TAG_LENGTH	7
#define TRUE_TAG_LENGTH		4
#define FALSE_TAG_LENGTH	5
#define DOCTYPE_TAG_LENGTH	7
#define CDSECT_TAG_LENGTH	9


static const UniChar CFXMLPlistTags[13][10]= {
{'p', 'l', 'i', 's', 't',   '\0', '\0', '\0', '\0', '\0'},
{'a', 'r', 'r', 'a', 'y',   '\0', '\0', '\0', '\0', '\0'},
{'d', 'i', 'c', 't',  '\0', '\0', '\0', '\0', '\0', '\0'},
{'k', 'e', 'y', '\0', '\0', '\0', '\0', '\0', '\0', '\0'},
{'s', 't', 'r', 'i', 'n', 'g',    '\0', '\0', '\0', '\0'},
{'d', 'a', 't', 'a',  '\0', '\0', '\0', '\0', '\0', '\0'},
{'d', 'a', 't', 'e',  '\0', '\0', '\0', '\0', '\0', '\0'},
{'r', 'e', 'a', 'l',  '\0', '\0', '\0', '\0', '\0', '\0'},
{'i', 'n', 't', 'e', 'g', 'e', 'r',     '\0', '\0', '\0'},
{'t', 'r', 'u', 'e',  '\0', '\0', '\0', '\0', '\0', '\0'},
{'f', 'a', 'l', 's', 'e',   '\0', '\0', '\0', '\0', '\0'},
{'D', 'O', 'C', 'T', 'Y', 'P', 'E',     '\0', '\0', '\0'},
{'<', '!', '[', 'C', 'D', 'A', 'T', 'A', '[',       '\0'}
};

typedef struct {
    const UniChar *begin; // first character of the XML to be parsed
    const UniChar *curr;  // current parse location
    const UniChar *end;   // the first character _after_ the end of the XML
    CFStringRef errorString;
    UInt32 errorLine;
	CFMutableSetRef stringSet;  // set of all strings involved in this parse; allows us to share non-mutable strings in the returned plist
    CFMutableStringRef tmpString; // Mutable string with external characters that functions can feel free to use as temporary storage as the parse progresses
    char _padding[3];
} _CFDebugXMLPlistParseInfo;


/* Base-64 encoding/decoding */

/* The base-64 encoding packs three 8-bit bytes into four 7-bit ASCII
 * characters.  If the number of bytes in the original data isn't divisable
 * by three, "=" characters are used to pad the encoded data.  The complete
 * set of characters used in base-64 are:
 *
 *      'A'..'Z' => 00..25
 *      'a'..'z' => 26..51
 *      '0'..'9' => 52..61
 *      '+'      => 62
 *      '/'      => 63
 *      '='      => pad
 */

// Write the inputData to the mData using Base 64 encoding

// ========================================================================

//
// ------------------------- Reading plists ------------------
// 

static void debug_skipInlineDTD(_CFDebugXMLPlistParseInfo *pInfo);

static CFTypeRef debug_parseXMLElement(_CFDebugXMLPlistParseInfo *pInfo, Boolean *isKey);

// warning: doesn't have a good idea of Unicode line separators
static UInt32 debug_lineNumber(_CFDebugXMLPlistParseInfo *pInfo)
{
    const UniChar *p = pInfo->begin;
    UInt32 count = 1;
    while (p < pInfo->curr) {
        if (*p == '\r') {
            count ++;
            if (*(p + 1) == '\n')
                p ++;
        } else if (*p == '\n') {
            count ++;
        }
        p ++;
    }
    return count;
}

// warning: doesn't have a good idea of Unicode white space
CF_INLINE void debug_skipWhitespace(_CFDebugXMLPlistParseInfo *pInfo)
{
    while (pInfo->curr < pInfo->end)
	{
        switch (*(pInfo->curr))
		{
            case ' ':
            case '\t':
            case '\n':
            case '\r':
                pInfo->curr ++;
                continue;
            default:
                return;
        }
    }
}

/* All of these advance to the end of the given construct and return a pointer to the first character beyond the construct.  If the construct doesn't parse properly, NULL is returned. */

// pInfo should be just past "<!--"
static void debug_skipXMLComment(_CFDebugXMLPlistParseInfo *pInfo)
{
    const UniChar *p = pInfo->curr;
    const UniChar *end = pInfo->end - 3; // Need at least 3 characters to compare against
    
	while (p < end)
	{
        if (*p == '-' && *(p+1) == '-' && *(p+2) == '>') {
            pInfo->curr = p+3;
            return;
        }
        p ++; 
    }
	
    pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Unterminated comment started on line %d", CFStringGetSystemEncoding());
	pInfo->errorLine=debug_lineNumber(pInfo);

}

// stringToMatch and buf must both be of at least len
static Boolean debug_matchString(const UniChar *buf, const UniChar *stringToMatch, UInt32 len)
{
    switch (len) {
	case 10: if (buf[9] != stringToMatch[9]) return false;
	case 9: if (buf[8] != stringToMatch[8]) return false;
	case 8: if (buf[7] != stringToMatch[7]) return false;
	case 7: if (buf[6] != stringToMatch[6]) return false;
	case 6: if (buf[5] != stringToMatch[5]) return false;
	case 5: if (buf[4] != stringToMatch[4]) return false;
	case 4: if (buf[3] != stringToMatch[3]) return false;
	case 3: if (buf[2] != stringToMatch[2]) return false;
	case 2: if (buf[1] != stringToMatch[1]) return false;
	case 1: if (buf[0] != stringToMatch[0]) return false;
	case 0: return true;
    }
    return false; // internal error
}

// pInfo should be set to the first character after "<?"
static void debug_skipXMLProcessingInstruction(_CFDebugXMLPlistParseInfo *pInfo) {
    const UniChar *begin = pInfo->curr, *end = pInfo->end - 2; // Looking for "?>" so we need at least 2 characters
    while (pInfo->curr < end)
	{
        if (*(pInfo->curr) == '?' && *(pInfo->curr+1) == '>')
		{
            pInfo->curr += 2;
            return;
        }
		
        pInfo->curr ++; 
    }
    pInfo->curr = begin;
    pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF while parsing the processing instruction begun on line %d", CFStringGetSystemEncoding());
	pInfo->errorLine=debug_lineNumber(pInfo);
}

// first character should be immediately after the "<!"
static void debug_skipDTD(_CFDebugXMLPlistParseInfo *pInfo)
{
    // First pass "DOCTYPE"
    if (pInfo->end - pInfo->curr < DOCTYPE_TAG_LENGTH || !debug_matchString(pInfo->curr, CFXMLPlistTags[DOCTYPE_IX], DOCTYPE_TAG_LENGTH))
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Malformed DTD on line %d", CFStringGetSystemEncoding());
		pInfo->errorLine=debug_lineNumber(pInfo);
        return;
    }
    pInfo->curr += DOCTYPE_TAG_LENGTH;
    debug_skipWhitespace(pInfo);

    // Look for either the beginning of a complex DTD or the end of the DOCTYPE structure
    while (pInfo->curr < pInfo->end)
	{
        UniChar ch = *(pInfo->curr);
        if (ch == '[') break; // inline DTD
        if (ch == '>') {  // End of the DTD
            pInfo->curr ++;
            return;
        }
        pInfo->curr ++;
    }
    if (pInfo->curr == pInfo->end)
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF while parsing DTD", CFStringGetSystemEncoding());
		
		return;
    }

    // *Sigh* Must parse in-line DTD
    debug_skipInlineDTD(pInfo);
    if (pInfo->errorString)  return;
    debug_skipWhitespace(pInfo);
    if (pInfo->errorString) return;
    if (pInfo->curr < pInfo->end)
	{
        if (*(pInfo->curr) == '>')
		{
            pInfo->curr ++;
        }
		else
		{
            pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c on line %%d while parsing DTD"), *(pInfo->curr));
			pInfo->errorLine=debug_lineNumber(pInfo);
        }
    }
	else
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF while parsing DTD", CFStringGetSystemEncoding());
    }
}

static void debug_skipPERef(_CFDebugXMLPlistParseInfo *pInfo)
{
    const UniChar *p = pInfo->curr;
    while (p < pInfo->end) {
        if (*p == ';') {
            pInfo->curr = p+1;
            return;
        }
        p ++;
    }
    pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF while parsing percent-escape sequence begun on line %d", CFStringGetSystemEncoding());
	pInfo->errorLine=debug_lineNumber(pInfo);
}

// First character should be just past '['
static void debug_skipInlineDTD(_CFDebugXMLPlistParseInfo *pInfo)
{
    while (!pInfo->errorString && pInfo->curr < pInfo->end)
	{
        UniChar ch;
        debug_skipWhitespace(pInfo);
        ch = *pInfo->curr;
        if (ch == '%')
		{
            pInfo->curr ++;
            debug_skipPERef(pInfo);
        }
		else if (ch == '<')
		{
            pInfo->curr ++;
            if (pInfo->curr >= pInfo->end)
			{
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF while parsing inline DTD", CFStringGetSystemEncoding());
				
                return;
            }
            ch = *(pInfo->curr);
            if (ch == '?') {
                pInfo->curr ++;
                debug_skipXMLProcessingInstruction(pInfo);
            } else if (ch == '!') {
                if (pInfo->curr + 2 < pInfo->end && (*(pInfo->curr+1) == '-' && *(pInfo->curr+2) == '-')) {
                    pInfo->curr += 3;
                    debug_skipXMLComment(pInfo);
                } else {
                    // Skip the myriad of DTD declarations of the form "<!string" ... ">"
                    pInfo->curr ++; // Past both '<' and '!'
                    while (pInfo->curr < pInfo->end) {
                        if (*(pInfo->curr) == '>') break;
                        pInfo->curr ++;
                    }
                    if (*(pInfo->curr) != '>') {
                        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF while parsing inline DTD", CFStringGetSystemEncoding());
						
                        return;
                 
   }
                    pInfo->curr ++;
                }
            } else {
                pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c on line %%d while parsing inline DTD"), ch);
				pInfo->errorLine=debug_lineNumber(pInfo);
                return;
            }
        } else if (ch == ']') {
            pInfo->curr ++;
            return;
        } else {
            pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c on line %%d while parsing inline DTD"), ch);
			pInfo->errorLine=debug_lineNumber(pInfo);
            return;
        }
    }
    if (!pInfo->errorString)
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF while parsing inline DTD", CFStringGetSystemEncoding());
}

/* A bit wasteful to do everything with unichars (since we know all the characters we're going to see are 7-bit ASCII), but since our data is coming from or going to a CFString, this prevents the extra cost of converting formats. */

static const signed char __CFPLDataDecodeTable[128] = {
    /* 000 */ -1, -1, -1, -1, -1, -1, -1, -1,
    /* 010 */ -1, -1, -1, -1, -1, -1, -1, -1,
    /* 020 */ -1, -1, -1, -1, -1, -1, -1, -1,
    /* 030 */ -1, -1, -1, -1, -1, -1, -1, -1,
    /* ' ' */ -1, -1, -1, -1, -1, -1, -1, -1,
    /* '(' */ -1, -1, -1, 62, -1, -1, -1, 63,
    /* '0' */ 52, 53, 54, 55, 56, 57, 58, 59,
    /* '8' */ 60, 61, -1, -1, -1,  0, -1, -1,
    /* '@' */ -1,  0,  1,  2,  3,  4,  5,  6,
    /* 'H' */  7,  8,  9, 10, 11, 12, 13, 14,
    /* 'P' */ 15, 16, 17, 18, 19, 20, 21, 22,
    /* 'X' */ 23, 24, 25, -1, -1, -1, -1, -1,
    /* '`' */ -1, 26, 27, 28, 29, 30, 31, 32,
    /* 'h' */ 33, 34, 35, 36, 37, 38, 39, 40,
    /* 'p' */ 41, 42, 43, 44, 45, 46, 47, 48,
    /* 'x' */ 49, 50, 51, -1, -1, -1, -1, -1
};

static CFDataRef __CFPLDataDecode(_CFDebugXMLPlistParseInfo *pInfo) {
    int tmpbufpos = 0;
    int tmpbuflen = 64;
    uint8_t *tmpbuf;
    int numeq = 0;
    int acc = 0;
    int cntr = 0;

    // GrP GC: collector shouldn't scan this raw data
    tmpbuf = CFAllocatorAllocate(kCFAllocatorDefault, tmpbuflen, 1);
    for (; pInfo->curr < pInfo->end; pInfo->curr++) {
        UniChar c = *(pInfo->curr);
        if (c == '<') {
            break;
	}
        if ('=' == c) {
            numeq++;
        } else if (!isspace(c)) {
            numeq = 0;
        }
        if (__CFPLDataDecodeTable[c] < 0)
            continue;
        cntr++;
        acc <<= 6;
        acc += __CFPLDataDecodeTable[c];
        if (0 == (cntr & 0x3)) {
            if (tmpbuflen <= tmpbufpos + 2) {
                tmpbuflen <<= 2;
                tmpbuf = CFAllocatorReallocate(kCFAllocatorDefault, tmpbuf, tmpbuflen, 1);
            }
            tmpbuf[tmpbufpos++] = (acc >> 16) & 0xff;
            if (numeq < 2)
                tmpbuf[tmpbufpos++] = (acc >> 8) & 0xff;
            if (numeq < 1)
                tmpbuf[tmpbufpos++] = acc & 0xff;
        }
    }
    
	return CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (char const *) tmpbuf, tmpbufpos, kCFAllocatorDefault);
}

// content ::== (element | CharData | Reference | CDSect | PI | Comment)*
// In the context of a plist, CharData, Reference and CDSect are not legal (they all resolve to strings).  Skipping whitespace, then, the next character should be '<'.  From there, we figure out which of the three remaining cases we have (element, PI, or Comment).
static CFTypeRef debug_getContentObject(_CFDebugXMLPlistParseInfo *pInfo, Boolean *isKey)
{
    if (isKey) *isKey = false;
	
    while (!pInfo->errorString && pInfo->curr < pInfo->end)
	{
        debug_skipWhitespace(pInfo);
		
        if (pInfo->curr >= pInfo->end)
		{
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
			
			return NULL;
        }
		
        if (*(pInfo->curr) != '<')
		{
            pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c on line %%d"), *(pInfo->curr));
			pInfo->errorLine=debug_lineNumber(pInfo);
            
			return NULL;
        }
		
        pInfo->curr ++;
		
        if (pInfo->curr >= pInfo->end)
		{
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
			
			return NULL;
        }
		
        switch (*(pInfo->curr))
		{
            case '?':
                // Processing instruction
                debug_skipXMLProcessingInstruction(pInfo);
                break;
            case '!':
                // Could be a comment
                if (pInfo->curr+2 >= pInfo->end)
				{
                    pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
					
					return NULL;
                }
                if (*(pInfo->curr+1) == '-' && *(pInfo->curr+2) == '-')
				{
                    pInfo->curr += 2;
                    debug_skipXMLComment(pInfo);
                }
				else
				{
                    pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
					
					return NULL;
                }
                break;
            case '/':
                // Whoops!  Looks like we got to the end tag for the element whose content we're parsing
                pInfo->curr --; // Back off to the '<'
                return NULL;
            default:
                // Should be an element
                return debug_parseXMLElement(pInfo, isKey);
        }
    }
	
    // Do not set the error string here; if it wasn't already set by one of the recursive parsing calls, the caller will quickly detect the failure (b/c pInfo->curr >= pInfo->end) and provide a more useful one of the form "end tag for <blah> not found"
    return NULL;
}

static void debug_catFromMarkToBuf(const UniChar *mark, const UniChar *buf, CFMutableStringRef *string, CFAllocatorRef allocator )
{
    if (!(*string))
	{
        *string = CFStringCreateMutable(allocator, 0);
    }
	
    CFStringAppendCharacters(*string, mark, buf-mark);
}

static void debug_parseCDSect_pl(_CFDebugXMLPlistParseInfo *pInfo, CFMutableStringRef string)
{
    const UniChar *end, *begin;
	
    if (pInfo->end - pInfo->curr < CDSECT_TAG_LENGTH)
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
		
        return;
    }
	
    if (!debug_matchString(pInfo->curr, CFXMLPlistTags[CDSECT_IX], CDSECT_TAG_LENGTH))
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered improper CDATA opening at line %d", CFStringGetSystemEncoding());
		pInfo->errorLine=debug_lineNumber(pInfo);
		
        return;
    }
	
    pInfo->curr += CDSECT_TAG_LENGTH;
    begin = pInfo->curr; // Marks the first character of the CDATA content
    end = pInfo->end-2; // So we can safely look 2 characters beyond p
    while (pInfo->curr < end)
	{
        if (*(pInfo->curr) == ']' && *(pInfo->curr+1) == ']' && *(pInfo->curr+2) == '>')
		{
           // Found the end!
            CFStringAppendCharacters(string, begin, pInfo->curr-begin);
            pInfo->curr += 3;
            return;
        }
        pInfo->curr ++;
    }
	
    // Never found the end mark
    pInfo->curr = begin;
    pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Could not find end of CDATA started on line %d", CFStringGetSystemEncoding());
	pInfo->errorLine=debug_lineNumber(pInfo);
}

// Only legal references are {lt, gt, amp, apos, quote, #ddd, #xAAA}
static void parseEntityReference_pl(_CFDebugXMLPlistParseInfo *pInfo, CFMutableStringRef string)
{
    int len;
    UniChar ch;
    pInfo->curr ++; // move past the '&';
    len = pInfo->end - pInfo->curr; // how many characters we can safely scan
    if (len < 1)
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
		
        return;
    }
	
    switch (*(pInfo->curr))
	{
        case 'l':  // "lt"
            if (len >= 3 && *(pInfo->curr+1) == 't' && *(pInfo->curr+2) == ';')
			{
                ch = '<';
                pInfo->curr += 3;
                break;
            }
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unknown ampersand-escape sequence at line %d", CFStringGetSystemEncoding());
			pInfo->errorLine=debug_lineNumber(pInfo);
			
            return;
			
        case 'g': // "gt"
            if (len >= 3 && *(pInfo->curr+1) == 't' && *(pInfo->curr+2) == ';')
			{
                ch = '>';
                pInfo->curr += 3;
                break;
            }
			
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unknown ampersand-escape sequence at line %d", CFStringGetSystemEncoding());
			pInfo->errorLine=debug_lineNumber(pInfo);
			
            return;
        case 'a': // "apos" or "amp"
            if (len < 4) {   // Not enough characters for either conversion
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
				
                return;
            }
            if (*(pInfo->curr+1) == 'm') {
                // "amp"
                if (*(pInfo->curr+2) == 'p' && *(pInfo->curr+3) == ';') {
                    ch = '&';
                    pInfo->curr += 4;
                    break;
                }
            } else if (*(pInfo->curr+1) == 'p') {
                // "apos"
                if (len > 4 && *(pInfo->curr+2) == 'o' && *(pInfo->curr+3) == 's' && *(pInfo->curr+4) == ';') {
                    ch = '\'';
                    pInfo->curr += 5;
                    break;
                }
            }
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unknown ampersand-escape sequence at line %d", CFStringGetSystemEncoding());

            return;
        case 'q':  // "quote"
            if (len >= 5 && *(pInfo->curr+1) == 'u' && *(pInfo->curr+2) == 'o' && *(pInfo->curr+3) == 't' && *(pInfo->curr+4) == ';') {
                ch = '\"';
                pInfo->curr += 5;
                break;
            }
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unknown ampersand-escape sequence at line %d", CFStringGetSystemEncoding());

            return;
        case '#':
        {
            uint16_t num = 0;
            Boolean isHex = false;
            if ( len < 4) {  // Not enough characters to make it all fit!  Need at least "&#d;"
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());

                return;
            }
            pInfo->curr ++;
            if (*(pInfo->curr) == 'x') {
                isHex = true;
                pInfo->curr ++;
            }
            while (pInfo->curr < pInfo->end) {
                ch = *(pInfo->curr);
                pInfo->curr ++;
                if (ch == ';') {
                    CFStringAppendCharacters(string, &num, 1);
                    return;
                }
                if (!isHex) num = num*10;
                else num = num << 4;
                if (ch <= '9' && ch >= '0') {
                    num += (ch - '0');
                } else if (!isHex) {
                    pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c at line %%d"), ch);
					pInfo->errorLine=debug_lineNumber(pInfo);
					
                    return;
                } else if (ch >= 'a' && ch <= 'f') {
                    num += 10 + (ch - 'a');
                } else if (ch >= 'A' && ch <= 'F') {
                    num += 10 + (ch - 'A');
                } else {
                    pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c at line %%d"), ch);
					pInfo->errorLine=debug_lineNumber(pInfo);
					
                    return;                    
                }
            }
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
			
            return;
        }
        default:
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unknown ampersand-escape sequence at line %d", CFStringGetSystemEncoding());
			pInfo->errorLine=debug_lineNumber(pInfo);
			
            return;
    }
	
    CFStringAppendCharacters(string, &ch, 1);
}

// String could be comprised of characters, CDSects, or references to one of the "well-known" entities ('<', '>', '&', ''', '"')
// returns a retained object in *string.
static CFStringRef debug_getString(_CFDebugXMLPlistParseInfo *pInfo)
{
    const UniChar *mark = pInfo->curr; // At any time in the while loop below, the characters between mark and p have not yet been added to *string
    CFMutableStringRef string = NULL;
    while (!pInfo->errorString && pInfo->curr < pInfo->end) {
        UniChar ch = *(pInfo->curr);
        if (ch == '<') {
	    if (pInfo->curr + 1 >= pInfo->end) break;
            // Could be a CDSect; could be the end of the string
            if (*(pInfo->curr+1) != '!') break; // End of the string
            debug_catFromMarkToBuf(mark, pInfo->curr, &string, kCFAllocatorDefault);
            debug_parseCDSect_pl(pInfo, string);
            mark = pInfo->curr;
        } else if (ch == '&') {
            debug_catFromMarkToBuf(mark, pInfo->curr, &string, kCFAllocatorDefault);
            parseEntityReference_pl(pInfo, string);
            mark = pInfo->curr;
        } else {
            pInfo->curr ++;
        }
    }

    if (pInfo->errorString) {
        if (string) CFRelease(string);
        return NULL;
    }
    if (!string) {
        string = CFStringCreateMutable(kCFAllocatorDefault, 0);
            CFStringAppendCharacters(string, mark, pInfo->curr - mark);
            return string;
    }
    debug_catFromMarkToBuf(mark, pInfo->curr, &string, kCFAllocatorDefault);
    
    return string;
}

static Boolean debug_checkForCloseTag(_CFDebugXMLPlistParseInfo *pInfo, const UniChar *tag, CFIndex tagLen)
{
    if (pInfo->end - pInfo->curr < tagLen + 3)
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
		
        return false;
    }
    if (*(pInfo->curr) != '<' || *(++pInfo->curr) != '/')
	{
        pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c on line %%d"), *(pInfo->curr));
		pInfo->errorLine=debug_lineNumber(pInfo);
        return false;
    }
    pInfo->curr ++;
	
    if (!debug_matchString(pInfo->curr, tag, tagLen))
	{
        CFStringRef str = CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault, tag, tagLen, kCFAllocatorNull);
        pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Close tag on line %%d does not match open tag <%@>"), str);
        pInfo->errorLine=debug_lineNumber(pInfo);
		
		CFRelease(str);
        return false;
    }
    pInfo->curr += tagLen;
    debug_skipWhitespace(pInfo);
    if (pInfo->curr == pInfo->end)
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());

        return false;
    }
    if (*(pInfo->curr) != '>')
	{
        pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unexpected character %c on line %%d"), *(pInfo->curr));
		pInfo->errorLine=debug_lineNumber(pInfo);
        return false;
    }
    pInfo->curr ++;
    return true;
}

// pInfo should be set to the first content character of the <plist>
static CFTypeRef debug_parsePListTag(_CFDebugXMLPlistParseInfo *pInfo)
{
    CFTypeRef result, tmp = NULL;
    const UniChar *save;
    result = debug_getContentObject(pInfo, NULL);
	
    if (!result)
	{
        if (!pInfo->errorString) pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered empty plist tag", CFStringGetSystemEncoding());

        return NULL;
    }
	
    save = pInfo->curr; // Save this in case the next step fails
    tmp = debug_getContentObject(pInfo, NULL);
    
	if (tmp)
	{
        // Got an extra object
        CFRelease(tmp);
        CFRelease(result);
        pInfo->curr = save;
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected element at line %d (plist can only include one object)", CFStringGetSystemEncoding());
		pInfo->errorLine=debug_lineNumber(pInfo);
        return NULL;
    }
	
    if (pInfo->errorString)
	{
        // Parse failed catastrophically
        CFRelease(result);
        return NULL;
    }
	
    if (debug_checkForCloseTag(pInfo, CFXMLPlistTags[PLIST_IX], PLIST_TAG_LENGTH))
	{
        return result;
    }
	
    CFRelease(result);
	
    return NULL;
}

static CFTypeRef debug_parseArrayTag(_CFDebugXMLPlistParseInfo *pInfo)
{
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    CFTypeRef tmp = debug_getContentObject(pInfo, NULL);
    
	while (tmp)
	{
        CFArrayAppendValue(array, tmp);
        CFRelease(tmp);
        tmp = debug_getContentObject(pInfo, NULL);
    }
	
    if (pInfo->errorString) { // debug_getContentObject encountered a parse error
        CFRelease(array);
        return NULL;
    }
	
    if (debug_checkForCloseTag(pInfo, CFXMLPlistTags[ARRAY_IX], ARRAY_TAG_LENGTH))
	{
		return array;
    }
	
    CFRelease(array);
	
    return NULL;
}

static CFTypeRef debug_parseDictTag(_CFDebugXMLPlistParseInfo *pInfo)
{
    CFMutableDictionaryRef dict = NULL;
    CFTypeRef key=NULL, value=NULL;
    Boolean gotKey;
    const UniChar *base = pInfo->curr;
	
    key = debug_getContentObject(pInfo, &gotKey);
	
    while (key)
	{
        if (!gotKey)
		{
            if (key) CFRelease(key);
            if (dict) CFRelease(dict);
			
            pInfo->curr = base;
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Found non-key inside <dict> at line %d", CFStringGetSystemEncoding());
			pInfo->errorLine=debug_lineNumber(pInfo);
			
            return NULL;
        }
		
        value = debug_getContentObject(pInfo, NULL);
        if (!value)
		{
            if (key) CFRelease(key);
            if (dict) CFRelease(dict);
            if (!pInfo->errorString)
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Value missing for key inside <dict> at line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
            return NULL;
        }
		
		if (NULL == dict) {
			dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			_CFDictionarySetCapacity(dict, 10);
		}
		
        CFDictionarySetValue(dict, key, value);
        CFRelease(key);
        key = NULL;
        CFRelease(value);
        value = NULL;
        base = pInfo->curr;
        key = debug_getContentObject(pInfo, &gotKey);
    }
	
	if (pInfo->errorString==NULL)
	{
		if (debug_checkForCloseTag(pInfo, CFXMLPlistTags[DICT_IX], DICT_TAG_LENGTH))
		{
			if (NULL == dict)
			{
				dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			}
			else
			{
				CFIndex cnt = CFDictionaryGetCount(dict);
				
				if (1 == cnt)
				{
					CFTypeRef val = CFDictionaryGetValue(dict, CFSTR("CF$UID"));
					if (val && CFGetTypeID(val) == CFNumberGetTypeID())
					{
						CFTypeRef uid;
						uint32_t v;
						CFNumberGetValue(val, kCFNumberSInt32Type, &v);
						uid = (CFTypeRef)_CFKeyedArchiverUIDCreate(kCFAllocatorDefault, v);
						CFRelease(dict);
						return uid;
					}
				}
			}
			
			return dict;
		}
	}
	
    if (dict) CFRelease(dict);
    
	return NULL;
}

static CFTypeRef debug_parseDataTag(_CFDebugXMLPlistParseInfo *pInfo) {
    CFDataRef result;
    const UniChar *base = pInfo->curr;
    result = __CFPLDataDecode(pInfo);
    if (!result) {
        pInfo->curr = base;
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Could not interpret <data> at line %d (should be base64-encoded)", CFStringGetSystemEncoding());
		pInfo->errorLine=debug_lineNumber(pInfo);
        return NULL;
    }
    if (debug_checkForCloseTag(pInfo, CFXMLPlistTags[DATA_IX], DATA_TAG_LENGTH)) return result;
    CFRelease(result);
    return NULL;
}

CF_INLINE Boolean debug_read2DigitNumber(_CFDebugXMLPlistParseInfo *pInfo, int8_t *result) {
    UniChar ch1, ch2;
    if (pInfo->curr + 2 >= pInfo->end) return false;
    ch1 = *pInfo->curr;
    ch2 = *(pInfo->curr + 1);
    pInfo->curr += 2;
    if (!isdigit(ch1) || !isdigit(ch2)) return false;
    *result = (ch1 - '0')*10 + (ch2 - '0');
    return true;
}

// YYYY '-' MM '-' DD 'T' hh ':' mm ':' ss 'Z'
static CFTypeRef debug_parseDateTag(_CFDebugXMLPlistParseInfo *pInfo) {
    CFGregorianDate date;
    int8_t num;
    Boolean badForm = false;

    date.year = 0;
    while (pInfo->curr < pInfo->end && isdigit(*pInfo->curr)) {
        date.year = 10*date.year + (*pInfo->curr) - '0';
        pInfo->curr ++;
    }
    if (pInfo->curr >= pInfo->end || *pInfo->curr != '-') {
        badForm = true;
    } else {
        pInfo->curr ++;
    }

    if (!badForm && debug_read2DigitNumber(pInfo, &date.month) && pInfo->curr < pInfo->end && *pInfo->curr == '-') {
        pInfo->curr ++;
    } else {
        badForm = true;
    }

    if (!badForm && debug_read2DigitNumber(pInfo, &date.day) && pInfo->curr < pInfo->end && *pInfo->curr == 'T') {
        pInfo->curr ++;
    } else {
        badForm = true;
    }

    if (!badForm && debug_read2DigitNumber(pInfo, &date.hour) && pInfo->curr < pInfo->end && *pInfo->curr == ':') {
        pInfo->curr ++;
    } else {
        badForm = true;
    }

    if (!badForm && debug_read2DigitNumber(pInfo, &date.minute) && pInfo->curr < pInfo->end && *pInfo->curr == ':') {
        pInfo->curr ++;
    } else {
        badForm = true;
    }

    if (!badForm && debug_read2DigitNumber(pInfo, &num) && pInfo->curr < pInfo->end && *pInfo->curr == 'Z') {
        date.second = num;
        pInfo->curr ++;
    } else {
        badForm = true;
    }

    if (badForm) {
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Could not interpret <date> at line %d", CFStringGetSystemEncoding());
		pInfo->errorLine=debug_lineNumber(pInfo);
        return NULL;
    }
    if (!debug_checkForCloseTag(pInfo, CFXMLPlistTags[DATE_IX], DATE_TAG_LENGTH)) return NULL;
    return CFDateCreate(kCFAllocatorDefault, CFGregorianDateGetAbsoluteTime(date, NULL));
}

static CFTypeRef debug_parseRealTag(_CFDebugXMLPlistParseInfo *pInfo) {
    CFStringRef str = debug_getString(pInfo);
    SInt32 idx, len;
    double val;
    CFNumberRef result;
    CFStringInlineBuffer buf;
    if (!str) {
        if (!pInfo->errorString)
            pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered empty <real> on line %d"), CFStringGetSystemEncoding());
			pInfo->errorLine=debug_lineNumber(pInfo);
        return NULL;
    }
    
    
	if (kCFCompareEqualTo == CFStringCompare(str, CFSTR("nan"), kCFCompareCaseInsensitive)) {
	    CFRelease(str);
	    return (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) ? CFRetain(kCFNumberNaN) : NULL;
	}
	if (kCFCompareEqualTo == CFStringCompare(str, CFSTR("+infinity"), kCFCompareCaseInsensitive)) {
	    CFRelease(str);
	    return (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) ? CFRetain(kCFNumberPositiveInfinity) : NULL;
	}
	if (kCFCompareEqualTo == CFStringCompare(str, CFSTR("-infinity"), kCFCompareCaseInsensitive)) {
	    CFRelease(str);
	    return (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) ? CFRetain(kCFNumberNegativeInfinity) : NULL;
	}
	if (kCFCompareEqualTo == CFStringCompare(str, CFSTR("infinity"), kCFCompareCaseInsensitive)) {
	    CFRelease(str);
	    return (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) ? CFRetain(kCFNumberPositiveInfinity) : NULL;
	}
	if (kCFCompareEqualTo == CFStringCompare(str, CFSTR("-inf"), kCFCompareCaseInsensitive)) {
	    CFRelease(str);
	    return (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) ? CFRetain(kCFNumberNegativeInfinity) : NULL;
	}
	if (kCFCompareEqualTo == CFStringCompare(str, CFSTR("inf"), kCFCompareCaseInsensitive)) {
	    CFRelease(str);
	    return (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) ? CFRetain(kCFNumberPositiveInfinity) : NULL;
	}
	if (kCFCompareEqualTo == CFStringCompare(str, CFSTR("+inf"), kCFCompareCaseInsensitive)) {
	    CFRelease(str);
	    return (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) ? CFRetain(kCFNumberPositiveInfinity) : NULL;
	}

    len = CFStringGetLength(str);
    CFStringInitInlineBuffer(str, &buf, CFRangeMake(0, len));
    idx = 0;
    if (!__CFStringScanDouble(&buf, NULL, &idx, &val) || idx != len) {
        CFRelease(str);
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered misformatted real on line %d", CFStringGetSystemEncoding());
        pInfo->errorLine = debug_lineNumber(pInfo);
		return NULL;
    }
    CFRelease(str);
    result = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &val);
    if (debug_checkForCloseTag(pInfo, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH)) return result;
    CFRelease(result);
    return NULL;
}

#define GET_CH	if (pInfo->curr == pInfo->end) {	\
			pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Premature end of file after <integer> on line %d", CFStringGetSystemEncoding()); \
			pInfo->errorLine = debug_lineNumber(pInfo); \
			return NULL;			\
		}					\
		ch = *(pInfo->curr)

static CFTypeRef debug_parseIntegerTag(_CFDebugXMLPlistParseInfo *pInfo) {
    bool isHex = false, isNeg = false, hadLeadingZero = false;
    int64_t value = (int64_t)0;
    UniChar ch = 0;

	// decimal_constant	S*(-|+)?S*[0-9]+		(S == space)
	// hex_constant		S*(-|+)?S*0[xX][0-9a-fA-F]+	(S == space)

    while (pInfo->curr < pInfo->end && __CFDebugIsWhitespace(*(pInfo->curr))) pInfo->curr++;
    GET_CH;
    if ('<' == ch) {
	pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered empty <integer> on line %d", CFStringGetSystemEncoding());
	pInfo->errorLine=debug_lineNumber(pInfo);
	return NULL;
    }
    if ('-' == ch || '+' == ch) {
	isNeg = ('-' == ch);
	pInfo->curr++;
	while (pInfo->curr < pInfo->end && __CFDebugIsWhitespace(*(pInfo->curr))) pInfo->curr++;
    }
    GET_CH;
    if ('0' == ch) {
	if (pInfo->curr + 1 < pInfo->end && ('x' == *(pInfo->curr + 1) || 'X' == *(pInfo->curr + 1))) {
	    pInfo->curr++;
	    isHex = true;
	} else {
	    hadLeadingZero = true;
	}
	pInfo->curr++;
    }
    GET_CH;
    while ('0' == ch)
	{
		hadLeadingZero = true;
		pInfo->curr++;
		GET_CH;
    }
    if ('<' == ch && hadLeadingZero)
	{	// nothing but zeros
		int32_t val = 0;
        
		if (!debug_checkForCloseTag(pInfo, CFXMLPlistTags[INTEGER_IX], INTEGER_TAG_LENGTH))
		{
	    // debug_checkForCloseTag() sets error string
	    return NULL;
        }
		
		return CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &val);
    }
	
    if ('<' == ch)
	{
		pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Incomplete <integer> on line %d", CFStringGetSystemEncoding());
		pInfo->errorLine=debug_lineNumber(pInfo);
		
		return NULL;
    }
	
    while ('<' != ch)
	{
		int64_t old_value = value;
		switch (ch)
		{
			case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
				value = (isHex ? 16 : 10) * value + (ch - '0');
				break;
			case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
				if (!isHex) {
				pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Hex digit in non-hex <integer> on line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
				return NULL;
				}
				value = 16 * value + (ch - 'a' + 10);
				break;
			case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
				if (!isHex) {
				pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Hex digit in non-hex <integer> on line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
				return NULL;
				}
				value = 16 * value + (ch - 'A' + 10);
				break;
			default:	// other character
				pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Unknown character '%c' (0x%x) in <integer> on line %%d"), ch, ch);
				pInfo->errorLine=debug_lineNumber(pInfo);
				return NULL;
		}
		
		if (isNeg && LLONG_MIN == value)
		{
			// overflow by one when isNeg gives the proper value, if we're done with the number
			if (pInfo->curr + 1 < pInfo->end && '<' == *(pInfo->curr + 1))
			{
				pInfo->curr++;
				isNeg = false;
				break;
			}
		}
		
		if (value < old_value)
		{
			pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered <integer> too large to represent on line %d", CFStringGetSystemEncoding());
			pInfo->errorLine=debug_lineNumber(pInfo);
			return NULL;
		}
		
		pInfo->curr++;
		GET_CH;
    }
	
    if (!debug_checkForCloseTag(pInfo, CFXMLPlistTags[INTEGER_IX], INTEGER_TAG_LENGTH))
	{
		// debug_checkForCloseTag() sets error string
		return NULL;
    }
	
    if (isNeg) value = -value;
    
	return CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &value);
}

#undef GET_CH

// Returned object is retained; caller must free.  pInfo->curr expected to point to the first character after the '<'
static CFTypeRef debug_parseXMLElement(_CFDebugXMLPlistParseInfo *pInfo, Boolean *isKey) {
    const UniChar *marker = pInfo->curr;
    int markerLength = -1;
    Boolean isEmpty;
    int markerIx = -1;
    
    if (isKey) *isKey = false;
    while (pInfo->curr < pInfo->end) {
        UniChar ch = *(pInfo->curr);
        if (ch == ' ' || ch ==  '\t' || ch == '\n' || ch =='\r') {
            if (markerLength == -1) markerLength = pInfo->curr - marker;
        } else if (ch == '>') {
            break;
        }
        pInfo->curr ++;
    }
    if (pInfo->curr >= pInfo->end) return NULL;
    isEmpty = (*(pInfo->curr-1) == '/');
    if (markerLength == -1)
        markerLength = pInfo->curr - (isEmpty ? 1 : 0) - marker;
    pInfo->curr ++; // Advance past '>'
    if (markerLength == 0) {
        // Back up to the beginning of the marker
        pInfo->curr = marker;
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Malformed tag on line %d", CFStringGetSystemEncoding());
		pInfo->errorLine=debug_lineNumber(pInfo);
        return NULL;
    }
    switch (*marker) {
        case 'a':   // Array
            if (markerLength == ARRAY_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[ARRAY_IX], ARRAY_TAG_LENGTH))
                markerIx = ARRAY_IX;
            break;
        case 'd': // Dictionary, data, or date; Fortunately, they all have the same marker length....
            if (markerLength != DICT_TAG_LENGTH)
                break;
            if (debug_matchString(marker, CFXMLPlistTags[DICT_IX], DICT_TAG_LENGTH))
                markerIx = DICT_IX;
            else if (debug_matchString(marker, CFXMLPlistTags[DATA_IX], DATA_TAG_LENGTH))
                markerIx = DATA_IX;
            else if (debug_matchString(marker, CFXMLPlistTags[DATE_IX], DATE_TAG_LENGTH))
                markerIx = DATE_IX;
            break;
        case 'f': // false (boolean)
            if (markerLength == FALSE_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[FALSE_IX], FALSE_TAG_LENGTH)) {
                markerIx = FALSE_IX;
            }
            break;
        case 'i': // integer
            if (markerLength == INTEGER_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[INTEGER_IX], INTEGER_TAG_LENGTH))
                markerIx = INTEGER_IX;
            break;
        case 'k': // Key of a dictionary
            if (markerLength == KEY_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[KEY_IX], KEY_TAG_LENGTH)) {
                markerIx = KEY_IX;
                if (isKey) *isKey = true;
            }
            break;
        case 'p': // Plist
            if (markerLength == PLIST_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[PLIST_IX], PLIST_TAG_LENGTH))
                markerIx = PLIST_IX;
            break;
        case 'r': // real
            if (markerLength == REAL_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[REAL_IX], REAL_TAG_LENGTH))
                markerIx = REAL_IX;
            break;
        case 's': // String
            if (markerLength == STRING_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[STRING_IX], STRING_TAG_LENGTH))
                markerIx = STRING_IX;
            break;
        case 't': // true (boolean)
            if (markerLength == TRUE_TAG_LENGTH && debug_matchString(marker, CFXMLPlistTags[TRUE_IX], TRUE_TAG_LENGTH))
                markerIx = TRUE_IX;
            break;
    }

    switch (markerIx) {
        case PLIST_IX:
            if (isEmpty) {
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered empty <plist> tag", CFStringGetSystemEncoding());

                return NULL;
            }
            return debug_parsePListTag(pInfo);
        case ARRAY_IX: 
            if (isEmpty) {
                return CFArrayCreate(kCFAllocatorDefault, NULL, 0, &kCFTypeArrayCallBacks);
            } else {
                return debug_parseArrayTag(pInfo);
            }
        case DICT_IX:
            if (isEmpty) {
                return CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
                
            } else {
                return debug_parseDictTag(pInfo);
            }
        case KEY_IX:
        case STRING_IX:
        {
            CFStringRef str;
            int tagLen = (markerIx == KEY_IX) ? KEY_TAG_LENGTH : STRING_TAG_LENGTH;
            if (isEmpty) {
                return CFStringCreateWithCharacters(kCFAllocatorDefault, NULL, 0);
            }
            str = debug_getString(pInfo);
            if (!str) return NULL; // debug_getString will already have set the error string
            if (!debug_checkForCloseTag(pInfo, CFXMLPlistTags[markerIx], tagLen)) {
                CFRelease(str);
                return NULL;
            }
            return str;
        }
        case DATA_IX:
            if (isEmpty) {
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered empty <data> on line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
                return NULL;
            } else {
                return debug_parseDataTag(pInfo);
            }
        case DATE_IX:
            if (isEmpty) {
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered empty <date> on line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
                return NULL;
            } else {
                return debug_parseDateTag(pInfo);
            }
        case TRUE_IX:
            if (!isEmpty) {
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered non-empty <true> tag on line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
                return NULL;
            } else {
                return CFRetain(kCFBooleanTrue);
            }
        case FALSE_IX:
            if (!isEmpty) {
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered non-empty <false> tag on line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
                return NULL;
            } else {
                return CFRetain(kCFBooleanFalse);
            }
        case REAL_IX:
            if (isEmpty) {
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered empty <real> on line %d", CFStringGetSystemEncoding());
				pInfo->errorLine=debug_lineNumber(pInfo);
                return NULL;
            } else {
                return debug_parseRealTag(pInfo);
            }
        case INTEGER_IX:
            if (isEmpty)
			{
                pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault,"Encountered empty <integer> on line %d", CFStringGetSystemEncoding());
                pInfo->errorLine=debug_lineNumber(pInfo);
				
				return NULL;
            }
			else
			{
                return debug_parseIntegerTag(pInfo);
            }
			
        default:
		{
            CFStringRef markerStr = CFStringCreateWithCharacters(kCFAllocatorDefault, marker, markerLength);
            pInfo->curr = marker;
            pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Encountered unknown tag %@ on line %%d"), markerStr);
			pInfo->errorLine=debug_lineNumber(pInfo);
           
			 CFRelease(markerStr);
            return NULL;
        }
    }
}

static CFTypeRef debug_parseXMLPropertyList(_CFDebugXMLPlistParseInfo *pInfo)
{
    while (!pInfo->errorString && pInfo->curr < pInfo->end)
	{
        UniChar ch;
        
		debug_skipWhitespace(pInfo);
		
        if (pInfo->curr+1 >= pInfo->end)
		{
            pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "No XML content found", CFStringGetSystemEncoding());

            return NULL;
        }
		
        if (*(pInfo->curr) != '<')
		{
            pInfo->errorString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Unexpected character %c at line %%d"), *(pInfo->curr));
			pInfo->errorLine=debug_lineNumber(pInfo);
            return NULL;
        }
		
        ch = *(++ pInfo->curr);
		
        if (ch == '!')
		{
            // Comment or DTD
            ++ pInfo->curr;
            if (pInfo->curr+1 < pInfo->end && *pInfo->curr == '-' && *(pInfo->curr+1) == '-')
			{
                // Comment
                pInfo->curr += 2;
                debug_skipXMLComment(pInfo);
            }
			else
			{
                debug_skipDTD(pInfo);
            }
        }
		else if (ch == '?')
		{
            // Processing instruction
            pInfo->curr++;
            debug_skipXMLProcessingInstruction(pInfo);
        }
		else
		{
            // Tag or malformed
            return debug_parseXMLElement(pInfo, NULL);
            // Note we do not verify that there was only one element, so a file that has garbage after the first element will nonetheless successfully parse
        }
    }
    // Should never get here
    if (!(pInfo->errorString))
	{
        pInfo->errorString = CFStringCreateWithCString(kCFAllocatorDefault, "Encountered unexpected EOF", CFStringGetSystemEncoding());
	}
	return NULL;
}

#pragma mark -

static CFStringEncoding debug_encodingForXMLData(CFDataRef data, CFStringRef *error)
{
    const uint8_t *bytes = (uint8_t *)CFDataGetBytePtr(data);
    UInt32 length = CFDataGetLength(data);
    const uint8_t *idx, *end;
    char quote;
    
    // Check for the byte order mark first
    if (length > 2 &&
        ((*bytes == 0xFF && *(bytes+1) == 0xFE) ||
         (*bytes == 0xFE && *(bytes+1) == 0xFF) ||
         *bytes == 0x00 || *(bytes+1) == 0x00)) // This clause checks for a Unicode sequence lacking the byte order mark; technically an error, but this check is recommended by the XML spec
        return kCFStringEncodingUnicode;
    
    // Scan for the <?xml.... ?> opening
    if (length < 5 || strncmp((char const *) bytes, "<?xml", 5) != 0) return kCFStringEncodingUTF8;
    idx = bytes + 5;
    end = bytes + length;
    // Found "<?xml"; now we scan for "encoding"
    while (idx < end)
	{
        uint8_t ch = *idx;
        const uint8_t *scan;
        
		if ( ch == '?' || ch == '>') return kCFStringEncodingUTF8;
        idx ++;
        scan = idx;
		
        if (ch == 'e' && *scan++ == 'n' && *scan++ == 'c' && *scan++ == 'o' && *scan++ == 'd' && *scan++ == 'i'
            && *scan++ == 'n' && *scan++ == 'g' && *scan++ == '=')
		{
            idx = scan;
            break;
        }
    }
	
    if (idx >= end) return kCFStringEncodingUTF8;
    quote = *idx;
    if (quote != '\'' && quote != '\"') return kCFStringEncodingUTF8;
    else
	{
        CFStringRef encodingName;
        const uint8_t *base = idx+1; // Move past the quote character
        CFStringEncoding enc;
        UInt32 len;
		
        idx ++;
        while (idx < end && *idx != quote) idx ++;
        if (idx >= end) return kCFStringEncodingUTF8;
        len = idx - base;
        if (len == 5 && (*base == 'u' || *base == 'U') && (base[1] == 't' || base[1] == 'T') && (base[2] == 'f' || base[2] == 'F') && (base[3] == '-') && (base[4] == '8'))
            return kCFStringEncodingUTF8;
			
        encodingName = CFStringCreateWithBytes(NULL, base, len, kCFStringEncodingISOLatin1, false);
		
        enc = CFStringConvertIANACharSetNameToEncoding(encodingName);
        
		if (enc != kCFStringEncodingInvalidId)
		{
            CFRelease(encodingName);
            return enc;
        }

        if (error)
		{
            *error = CFStringCreateWithFormat(NULL, NULL, CFSTR("Encountered unknown encoding (%@)"), encodingName);
        }
		
		CFRelease(encodingName);
		
        return 0;
    }
}

void FindParsingErrorWithData(CFDataRef xmlData, CFStringRef * outErrorString,UInt32 * outLineNumber)
{
    CFStringEncoding encoding;
    CFStringRef xmlString;
    UInt32 length;

    if (outErrorString!=NULL) *outErrorString = NULL;
	
    if (!xmlData || CFDataGetLength(xmlData) == 0)
	{
        if (outErrorString!=NULL)
		{
            *outErrorString = CFStringCreateCopy(kCFAllocatorDefault,CFSTR("Cannot parse a NULL or zero-length data"));
        }
		
        return;
    }
    
    encoding = debug_encodingForXMLData(xmlData, outErrorString); // 0 is an error return, NOT MacRoman.

    if (encoding == 0)
	{
        // Couldn't find an encoding; debug_encodingForXMLData already set *errorString if necessary
        // Note that debug_encodingForXMLData() will give us the right values for a standard plist, too.
        
		if (outErrorString!=NULL) *outErrorString = CFStringCreateCopy(kCFAllocatorDefault,CFSTR("Could not determine the encoding of the XML data"));
		
        return;
    }

    xmlString = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(xmlData), CFDataGetLength(xmlData), encoding, true);
	
    length = xmlString ? CFStringGetLength(xmlString) : 0;

    if (length>0)
	{
        _CFDebugXMLPlistParseInfo pInfoBuf;
        _CFDebugXMLPlistParseInfo *pInfo = &pInfoBuf;
        CFTypeRef result;
        UniChar *buf = (UniChar *) CFStringGetCharactersPtr(xmlString);
		
        if (!buf)
		{
            buf = (UniChar *)CFAllocatorAllocate(kCFAllocatorDefault, length * sizeof(UniChar), 0);
			
            CFStringGetCharacters(xmlString, CFRangeMake(0, length), buf);
			
            CFRelease(xmlString);
			
            xmlString = NULL;
        }
		
        pInfo->begin = buf;
        pInfo->end = buf+length;
        pInfo->curr = buf;
        pInfo->errorString = NULL;
		pInfo->errorLine=-1;
		pInfo->stringSet = NULL;
        pInfo->tmpString = NULL;
		
        
        // Haven't done anything XML-specific to this point.  However, the encoding we used to translate the bytes should be kept in mind; we used Unicode if the byte-order mark was present; UTF-8 otherwise.  If the system encoding is not UTF-8 or some variant of 7-bit ASCII, we'll be in trouble.....
        result = debug_parseXMLPropertyList(pInfo);
        
        if (!result)
		{
			// Reset pInfo so we can try again
            
			// Try pList
            
			if (outErrorString!=NULL && pInfo->errorString!=NULL) *outErrorString = CFStringCreateCopy(kCFAllocatorDefault, pInfo->errorString);
			
			if (outLineNumber!=NULL) *outLineNumber=pInfo->errorLine;
			
			if (pInfo->errorString) CFRelease(pInfo->errorString);
        }
		
        if (xmlString)
		{
            CFRelease(xmlString);
        }
		else
		{
            CFAllocatorDeallocate(kCFAllocatorDefault, (void *)pInfo->begin);
        }
		
        if (pInfo->stringSet) CFRelease(pInfo->stringSet);
		
        if (pInfo->tmpString) CFRelease(pInfo->tmpString);
    }
	else
	{
        if (xmlString)
		{
            CFRelease(xmlString);
        }
		
		if (outErrorString!=NULL)
		{
            *outErrorString = CFStringCreateCopy(kCFAllocatorDefault, CFSTR("Conversion of data failed. The file is not UTF-8, or in the encoding specified in XML header if XML."));
        }
		
    }
}