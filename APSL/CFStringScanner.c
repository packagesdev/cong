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
/*	CFStringScanner.c
	Copyright 1999-2002, Apple, Inc. All rights reserved.
	Responsibility: Ali Ozer
*/

#include <CoreFoundation/CFString.h>

#include <sys/types.h>

#include <limits.h>
#include <stdlib.h>
#include <string.h>

CF_INLINE UniChar __CFStringGetCharacterFromInlineBufferAux(CFStringInlineBuffer *buf, CFIndex idx) {
    if (buf->directBuffer) {
    //if (buf->directUniCharBuffer) {
	if (idx < 0 || idx >= buf->rangeToBuffer.length) return 0xFFFF;
        return buf->directBuffer[idx + buf->rangeToBuffer.location];
        //return buf->directUniCharBuffer[idx + buf->rangeToBuffer.location];
    }
    if (idx >= buf->bufferedRangeEnd || idx < buf->bufferedRangeStart) {
	if (idx < 0 || idx >= buf->rangeToBuffer.length) return 0xFFFF;
	if ((buf->bufferedRangeStart = idx - 4) < 0) buf->bufferedRangeStart = 0;
	buf->bufferedRangeEnd = buf->bufferedRangeStart + __kCFStringInlineBufferLength;
	if (buf->bufferedRangeEnd > buf->rangeToBuffer.length) buf->bufferedRangeEnd = buf->rangeToBuffer.length;
	CFStringGetCharacters(buf->theString, CFRangeMake(buf->rangeToBuffer.location + buf->bufferedRangeStart, buf->bufferedRangeEnd - buf->bufferedRangeStart), buf->buffer);
    }
    return buf->buffer[idx - buf->bufferedRangeStart];
}

CF_INLINE Boolean __CFCharacterIsADigit(UniChar ch) {
    return (ch >= '0' && ch <= '9') ? true : false;
}

/* Returns -1 on illegal value */
CF_INLINE SInt32 __CFCharacterNumericOrHexValue (UniChar ch) {
    if (ch >= '0' && ch <= '9') {
        return ch - '0';
    } else if (ch >= 'A' && ch <= 'F') {
        return ch + 10 - 'A';
    } else if (ch >= 'a' && ch <= 'f') {
        return ch + 10 - 'a';
    } else {
        return -1;
    }
}
               
/* Returns -1 on illegal value */
CF_INLINE SInt32 __CFCharacterNumericValue(UniChar ch) {
    return (ch >= '0' && ch <= '9') ? (ch - '0') : -1;
}

CF_INLINE UniChar __CFStringGetFirstNonSpaceCharacterFromInlineBuffer(CFStringInlineBuffer *buf, SInt32 *indexPtr) {
    UniChar ch;
    while (__CFDebugIsWhitespace(ch = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr))) (*indexPtr)++;
    return ch;
}

/* result is int64_t or int, depending on doLonglong
*/
__private_extern__ Boolean __CFStringScanInteger(CFStringInlineBuffer *buf, CFDictionaryRef locale, SInt32 *indexPtr, Boolean doLonglong, void *result) {
    Boolean doingLonglong = false;	/* Set to true if doLonglong, and we overflow an int... */
    Boolean neg = false;
    int intResult = 0;
    register int64_t longlongResult = 0;	/* ??? int64_t is slow when not in regs; I hope this does the right thing. */
    UniChar ch;

    ch = __CFStringGetFirstNonSpaceCharacterFromInlineBuffer(buf, indexPtr);

    if (ch == '-' || ch == '+') {
	neg = (ch == '-');
	(*indexPtr)++;
    	ch = __CFStringGetFirstNonSpaceCharacterFromInlineBuffer(buf, indexPtr);
    }	

    if (! __CFCharacterIsADigit(ch)) return false;	/* No digits, bail out... */
    do {
	if (doingLonglong) {
            if ((longlongResult >= LLONG_MAX / 10) && ((longlongResult > LLONG_MAX / 10) || (__CFCharacterNumericValue(ch) - (neg ? 1 : 0) >= LLONG_MAX - longlongResult * 10))) {
                /* ??? This might not handle LLONG_MIN correctly... */
                longlongResult = neg ? LLONG_MIN : LLONG_MAX;
                neg = false;
                while (__CFCharacterIsADigit(ch = __CFStringGetCharacterFromInlineBufferAux(buf, ++(*indexPtr))));	/* Skip remaining digits */
            } else {
                longlongResult = longlongResult * 10 + __CFCharacterNumericValue(ch);
                ch = __CFStringGetCharacterFromInlineBufferAux(buf, ++(*indexPtr));
            }
	} else {
            if ((intResult >= INT_MAX / 10) && ((intResult > INT_MAX / 10) || (__CFCharacterNumericValue(ch) - (neg ? 1 : 0) >= INT_MAX - intResult * 10))) {
                // Overflow, check for int64_t...
                if (doLonglong) {
                    longlongResult = intResult;
                    doingLonglong = true;
                } else {
                    /* ??? This might not handle INT_MIN correctly... */
                    intResult = neg ? INT_MIN : INT_MAX;
                    neg = false;
                    while (__CFCharacterIsADigit(ch = __CFStringGetCharacterFromInlineBufferAux(buf, ++(*indexPtr))));	/* Skip remaining digits */
                }
            } else {
                intResult = intResult * 10 + __CFCharacterNumericValue(ch);
                ch = __CFStringGetCharacterFromInlineBufferAux(buf, ++(*indexPtr));
            }
	}
    } while (__CFCharacterIsADigit(ch));

    if (result) {
        if (doLonglong) {
	    if (!doingLonglong) longlongResult = intResult;
	    *(int64_t *)result = neg ? -longlongResult : longlongResult;
	} else {
	    *(int *)result = neg ? -intResult : intResult;
	}
    }

    return true;
}

__private_extern__ Boolean __CFStringScanHex(CFStringInlineBuffer *buf, SInt32 *indexPtr, unsigned *result) {
    UInt32 value = 0;
    SInt32 curDigit;
    UniChar ch;

    ch = __CFStringGetFirstNonSpaceCharacterFromInlineBuffer(buf, indexPtr);
    /* Ignore the optional "0x" or "0X"; if it's followed by a non-hex, just parse the "0" and leave pointer at "x" */
    if (ch == '0') {
	ch = __CFStringGetCharacterFromInlineBufferAux(buf, ++(*indexPtr));
        if (ch == 'x' || ch == 'X') ch = __CFStringGetCharacterFromInlineBufferAux(buf, ++(*indexPtr));
	curDigit = __CFCharacterNumericOrHexValue(ch);
        if (curDigit == -1) {
	    (*indexPtr)--;	/* Go back over the "x" or "X" */
	    if (result) *result = 0;
            return true;	/* We just saw "0" */
        }
    } else {
	curDigit = __CFCharacterNumericOrHexValue(ch);
        if (curDigit == -1) return false;
    }    

    do {
        if (value > (UINT_MAX >> 4)) {	
	    value = UINT_MAX;	/* We do this over and over again, but it's an error case anyway */
        } else {
            value = (value << 4) + curDigit;
        }
	curDigit = __CFCharacterNumericOrHexValue(__CFStringGetCharacterFromInlineBufferAux(buf, ++(*indexPtr)));
    } while (curDigit != -1);

    if (result) *result = value;
    return true;
}

// Packed array of Boolean
static const char __CFNumberSet[16] = {
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  nul soh stx etx eot enq ack bel
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  bs  ht  nl  vt  np  cr  so  si
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  dle dc1 dc2 dc3 dc4 nak syn etb
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  can em  sub esc fs  gs  rs  us
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  sp   !   "   #   $   %   &   '
    0X28, // 0, 0, 0, 1, 0, 1, 0, 0, //  (   )   *   +   ,   -   .   /
    0XFF, // 1, 1, 1, 1, 1, 1, 1, 1, //  0   1   2   3   4   5   6   7
    0X03, // 1, 1, 0, 0, 0, 0, 0, 0, //  8   9   :   ;   <   =   >   ?
    0X20, // 0, 0, 0, 0, 0, 1, 0, 0, //  @   A   B   C   D   E   F   G
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  H   I   J   K   L   M   N   O
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  P   Q   R   S   T   U   V   W
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  X   Y   Z   [   \   ]   ^   _
    0X20, // 0, 0, 0, 0, 0, 1, 0, 0, //  `   a   b   c   d   e   f   g
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  h   i   j   k   l   m   n   o
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0, //  p   q   r   s   t   u   v   w
    0X00, // 0, 0, 0, 0, 0, 0, 0, 0  //  x   y   z   {   |   }   ~  del
};

__private_extern__ Boolean __CFStringScanDouble(CFStringInlineBuffer *buf, CFDictionaryRef locale, SInt32 *indexPtr, double *resultPtr) {
    #define STACK_BUFFER_SIZE 256
    #define ALLOC_CHUNK_SIZE 256 // first and subsequent malloc size.  Should be greater than STACK_BUFFER_SIZE
    char localCharBuffer[STACK_BUFFER_SIZE];
    char *charPtr = localCharBuffer;
    char *endCharPtr;
    UniChar decimalChar = '.';
    SInt32 numChars = 0;
    SInt32 capacity = STACK_BUFFER_SIZE;	// in chars
    double result;
    UniChar ch;
    CFAllocatorRef tmpAlloc = NULL;

#if 0
    if (locale != NULL) {
        CFStringRef decimalSeparator = [locale objectForKey: NSDecimalSeparator];
        if (decimalSeparator != nil) decimalChar = [decimalSeparator characterAtIndex:0];
    }
#endif
    ch = __CFStringGetFirstNonSpaceCharacterFromInlineBuffer(buf, indexPtr);
    // At this point indexPtr points at the first non-space char
#if 0
#warning need to allow, case insensitively, all of: "nan", "inf", "-inf", "+inf", "-infinity", "+infinity", "infinity";
#warning -- strtod() will actually do most or all of that for us
#define BITSFORDOUBLENAN	((uint64_t)0x7ff8000000000000)
#define BITSFORDOUBLEPOSINF	((uint64_t)0x7ff0000000000000)
#define BITSFORDOUBLENEGINF	((uint64_t)0xfff0000000000000)
    if ('N' == ch || 'n' == ch) {	// check for "NaN", case insensitively
        UniChar next1 = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + 1);
        UniChar next2 = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + 2);
        if (('a' == next1 || 'A' == next1) &&
            ('N' == next2 || 'n' == next2)) {
            *indexPtr += 3;
            if (resultPtr) *(uint64_t *)resultPtr = BITSFORDOUBLENAN;
            return true;
        }
    }
    if ('I' == ch || 'i' == ch) {	// check for "Inf", case insensitively
        UniChar next1 = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + 1);
        UniChar next2 = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + 2);
        if (('n' == next1 || 'N' == next1) &&
            ('f' == next2 || 'F' == next2)) {
            *indexPtr += 3;
            if (resultPtr) *(uint64_t *)resultPtr = BITSFORDOUBLEPOSINF;
            return true;
        }
    }
    if ('+' == ch || '-' == ch) {	// check for "+/-Inf", case insensitively
        UniChar next1 = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + 1);
        UniChar next2 = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + 2);
        UniChar next3 = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + 3);
        if (('I' == next1 || 'i' == next1) &&
            ('n' == next2 || 'N' == next2) &&
            ('f' == next3 || 'F' == next3)) {
            *indexPtr += 4;
            if (resultPtr) *(uint64_t *)resultPtr = ('-' == ch) ? BITSFORDOUBLENEGINF : BITSFORDOUBLEPOSINF;
            return true;
        }
    }
#endif
    do {
	if (ch >= 128 || (__CFNumberSet[ch >> 3] & (1 << (ch & 7))) == 0) {
            // Not in __CFNumberSet
	    if (ch != decimalChar) break;
            ch = '.';	// Replace the decimal character with something strtod will understand
        }
        if (numChars >= capacity - 1) {
	    capacity += ALLOC_CHUNK_SIZE;
	    if (tmpAlloc == NULL) tmpAlloc = kCFAllocatorDefault;
	    if (charPtr == localCharBuffer) {
		charPtr = CFAllocatorAllocate(tmpAlloc, capacity * sizeof(char), 0);
		memmove(charPtr, localCharBuffer, numChars * sizeof(char));
 	    } else {
		charPtr = CFAllocatorReallocate(tmpAlloc, charPtr, capacity * sizeof(char), 0);
	    }
        }
	charPtr[numChars++] = (char)ch;
	ch = __CFStringGetCharacterFromInlineBufferAux(buf, *indexPtr + numChars);
    } while (true);
    charPtr[numChars] = 0;	// Null byte for strtod

    result = strtod_l(charPtr, &endCharPtr, NULL);

    if (tmpAlloc) CFAllocatorDeallocate(tmpAlloc, charPtr);
    if (charPtr == endCharPtr) return false;
    *indexPtr += (endCharPtr - charPtr);
    if (resultPtr) *resultPtr = result; // only store result if we succeed
    
    return true;
}


#undef STACK_BUFFER_SIZE
#undef ALLOC_CHUNK_SIZE


