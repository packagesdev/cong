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
#import "TreeNode.h"

#define BM_LINEAR_TREE_TYPE_ROOT		0

#define BM_LINEAR_TREE_TYPE_FILE		1

#define BM_LINEAR_TREE_REPORT			2

#define BM_LINEAR_TREE_NODE(n)		((BMLinearTreeNode*) n)

#define BM_LINEAR_NODE_DATA(n) 	((BMLinearNodeData *)[BM_LINEAR_TREE_NODE((n)) nodeData])

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
@interface BMLinearNodeData: TreeNodeData
#else
@interface BMLinearNodeData: NSObject
#endif
{
	int type_;
	
	NSUInteger notes_;
	
	NSUInteger warnings_;
	
	NSUInteger errors_;
	
	NSInteger level_;
	
    id reportDictionary_;
	
	NSString * filePath_;
	
	BOOL descriptionVisible_;
}

+ (id) nodeOfType:(int) inType withReport:(id) inReportDictionary ofLevel:(NSInteger) inLevel;

- (id) initWithType:(int) inType withReport:(id) inReportDictionary ofLevel:(NSInteger) inLevel;

+ (id) rootNode;

- (BOOL) isLeaf;

- (NSUInteger) notes;

- (NSUInteger) warnings;

- (NSUInteger) errors;

- (NSInteger) level;

- (void) setLevel:(NSInteger) inLevel;

- (BOOL) descriptionVisible;

- (void) setDescriptionVisible:(BOOL) inBool;

- (NSString *) filePath;

- (void) setFilePath:(NSString *) inFilePath;

- (int) type;

- (void) setType:(int) inType;

- (NSDictionary *) report;

- (void) setReport:(id) inReportDictionary;

- (void) incrementNotes:(NSUInteger) inNotes warnings:(NSUInteger) inWarnings errors:(NSUInteger) inErrors;

@end

@interface BMLinearTreeNode : TreeNode
{

}

- (void) insertSortedChildReverse:(BMLinearTreeNode *) inChild;

+ (id) buildTree;

+ (id) duplicateTree:(BMLinearTreeNode *) inTree limitedToScopes:(NSIndexSet *) inScopeSet searchPattern:(NSString *) inPattern hash:(NSMutableDictionary *) inHash;

@end
