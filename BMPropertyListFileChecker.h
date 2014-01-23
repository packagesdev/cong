/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

extern NSString * const BM_PROPERTYLIST_KEY_TYPE;

extern NSString * const BM_PROPERTYLIST_KEY_FORMAT;

extern NSString * const BM_PROPERTYLIST_KEY_SHOULD_CONFORM_TO_FORMAT;

extern NSString * const BM_PROPERTYLIST_KEY_DEPRECATED;

extern NSString * const BM_PROPERTYLIST_KEY_DEPRECATED_OS_VERSION;

extern NSString * const BM_PROPERTYLIST_KEY_DEPRECATED_ALTERNATIVES;

extern NSString * const BM_PROPERTYLIST_KEY_PRIVATE;

extern NSString * const BM_PROPERTYLIST_KEY_CAN_NOT_BE_EMPTY;

extern NSString * const BM_PROPERTYLIST_KEY_CHILDREN_VIRTUAL_KEY;

extern NSString * const BM_PROPERTYLIST_KEY_AUTHORIZED_CHILDREN_TYPES;

extern NSString * const BM_PROPERTYLIST_KEY_AUTHORIZED_CHILDREN_KEYS;

extern NSString * const BM_PROPERTYLIST_KEY_REQUIRED_CHILDREN_KEYS;

extern NSString * const BM_PROPERTYLIST_KEY_AUTHORIZED_VALUES;



@interface BMPropertyListFileChecker : NSObject
{
	NSDictionary * checkListDictionary_;
	
	NSString * checkedFilePath_;
	
	id delegate;
	
	NSUInteger problemLevel_;
}

- (id) initWithCheckListAtPath:(NSString *) inPath;

- (NSUInteger) problemLevel;

- (void) checkObject:(id) inObject forKey:(NSString *) inKey;

- (void) checkObject:(id) inObject forKey:(NSString *) inKey supportDeviceSpecificKey:(BOOL) inSupportDeviceSpecificKey;

- (BOOL) checkPropertyListFileAtPath:(NSString *) inPath withDelegate:(id) inDelegate;

- (BOOL) checkPropertyListFileAtPath:(NSString *) inPath withDelegate:(id) inDelegate supportDeviceSpecificKey:(BOOL) inSupportDeviceSpecificDevice;

@end
