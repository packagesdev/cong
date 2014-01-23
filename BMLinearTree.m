/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMLinearTree.h"

#import "BMReportingConstants.h"

@implementation BMLinearNodeData

+ (id) nodeOfType:(int) inType withReport:(id) inReportDictionary ofLevel:(NSInteger) inLevel
{
	return [[[BMLinearNodeData alloc] initWithType:inType withReport:inReportDictionary ofLevel:inLevel] autorelease];;
}

- (id) initWithType:(int) inType withReport:(id) inReportDictionary ofLevel:(NSInteger) inLevel
{
	self=[super init];
    
    if (self!=nil)
    {
        type_=inType;
		
		level_=inLevel;
		
		reportDictionary_=[inReportDictionary retain];
    }
    
    return self;
}

+ (id) rootNode
{
    return [BMLinearNodeData  nodeOfType:BM_LINEAR_TREE_TYPE_ROOT withReport:nil ofLevel:0];
}

- (void) dealloc
{
	[reportDictionary_ release];
	
	[filePath_ release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) isLeaf
{
    if (type_==BM_LINEAR_TREE_REPORT)
	{
		return YES;
	}
    
    return NO;
}

- (int) type
{
    return type_;
}

- (void) setType:(int) inType
{
    type_=inType;
}

- (NSUInteger) notes
{
	return notes_;
}

- (NSUInteger) warnings
{
	return warnings_;
}

- (NSUInteger) errors
{
	return errors_;
}

- (NSInteger) level
{
	return level_;
}

- (void) setLevel:(NSInteger) inLevel
{
	level_=inLevel;
}

- (BOOL) descriptionVisible
{
	return descriptionVisible_;
}

- (void) setDescriptionVisible:(BOOL) inBool
{
	descriptionVisible_=inBool;
}

- (NSString *) filePath
{
	return [[filePath_ retain] autorelease];
}

- (void) setFilePath:(NSString *) inFilePath
{
	[filePath_ release];
	
	filePath_=[inFilePath retain];
}

- (NSDictionary *) report
{
	return [[reportDictionary_ retain] autorelease];
}

- (void) setReport:(id) inReportDictionary
{
	[reportDictionary_ release];
	
	reportDictionary_=[inReportDictionary retain];
}

- (void) incrementNotes:(NSUInteger) inNotes warnings:(NSUInteger) inWarnings errors:(NSUInteger) inErrors
{
	notes_+=inNotes;
	
	warnings_+=inWarnings;
	
	errors_+=inErrors;
}

@end

@implementation BMLinearTreeNode

- (void) setNodeParent:(TreeNode *) inParent
{
    [super setNodeParent:inParent];
	
	if (inParent!=nil)
	{
		BMLinearNodeData * tNodeData;
		
		tNodeData=BM_LINEAR_NODE_DATA(self);
		
		if ([tNodeData type]==BM_LINEAR_TREE_REPORT)
		{
			BMLinearNodeData * tNodeParentData;
			NSInteger tLevel;
			
			tLevel=[tNodeData level];
			
			tNodeParentData=BM_LINEAR_NODE_DATA(inParent);
			
			if ([tNodeParentData level]<tLevel)
			{
				[tNodeParentData setLevel:tLevel];
			}
			
			[tNodeParentData incrementNotes:(tLevel==BM_PROBLEM_LEVEL_NOTE) ? 1 : 0
								   warnings:(tLevel==BM_PROBLEM_LEVEL_WARNING) ? 1 : 0
									 errors:(tLevel==BM_PROBLEM_LEVEL_ERROR) ? 1 : 0];
		}
	}
}

- (void) insertSortedChildReverse:(BMLinearTreeNode *) inChild
{
    NSArray * tChildren;
    NSUInteger tIndex=NSNotFound;
    
    tChildren=[self children];
    
    if (tChildren!=nil)
    {
        NSUInteger i,tCount;
        BMLinearNodeData * tNode;
        NSComparisonResult tResult;
        NSString * tName;
        
        tName=[BM_LINEAR_NODE_DATA(inChild) filePath];
        
        tCount=[tChildren count];
        
		for(i=tCount;i>0;i--)
        {
            tNode=BM_LINEAR_NODE_DATA([tChildren objectAtIndex:i-1]);
            
            tResult=[tName compare:[tNode filePath] options:NSCaseInsensitiveSearch];
            
            if (tResult!=NSOrderedAscending)
            {
                tIndex=i;
                break;
            }
        }
        
        if (tIndex==NSNotFound)
        {
            tIndex=0;
        }
    }
    else
    {
        tIndex=0;
    }
    
    [self insertChild:inChild atIndex:tIndex];
}

+ (id) buildTree
{
    BMLinearTreeNode * rootNode=nil;
    
    rootNode=[[BMLinearTreeNode alloc] initWithData:[BMLinearNodeData rootNode]
                                            parent:nil
                                          children:[NSArray array]];
    
    return [rootNode autorelease];
}

+ (id) duplicateTree:(BMLinearTreeNode *) inTree limitedToScopes:(NSIndexSet *) inScopeSet searchPattern:(NSString *) inPattern hash:(NSMutableDictionary *) inHash
{
	BMLinearTreeNode * nRootNode=nil;
    
    nRootNode=[[BMLinearTreeNode alloc] initWithData:[BMLinearNodeData rootNode]
											 parent:nil
										   children:[NSArray array]];
	
	if (nRootNode!=nil)
	{
		NSArray * tFilesChildren;
		NSUInteger i,tFilesCount;
		
		tFilesChildren=[inTree children];
		
		tFilesCount=[tFilesChildren count];
		
		for(i=0;i<tFilesCount;i++)
		{
			BMLinearNodeData * tNodeData;
			
			tNodeData=BM_LINEAR_NODE_DATA([tFilesChildren objectAtIndex:i]);
			
			if (([tNodeData notes]>0 && [inScopeSet containsIndex:BM_PROBLEM_LEVEL_NOTE]==YES) ||
				([tNodeData warnings]>0 && [inScopeSet containsIndex:BM_PROBLEM_LEVEL_WARNING]==YES) ||
				([tNodeData errors]>0 && [inScopeSet containsIndex:BM_PROBLEM_LEVEL_ERROR]==YES))
			{
				BMLinearNodeData * tFileLinearData;
				
				tFileLinearData=[BMLinearNodeData nodeOfType:BM_LINEAR_TREE_TYPE_FILE withReport:nil ofLevel:-1];
				
				if (tFileLinearData!=nil)
				{
					BMLinearTreeNode * tFileTreeNode;
					
					[tFileLinearData setFilePath:[tNodeData filePath]];
					
					tFileTreeNode=[[BMLinearTreeNode alloc] initWithData:tFileLinearData
																  parent:nil
																children:[NSArray array]];
					
					if (tFileTreeNode!=nil)
					{
						NSArray * tReportsChildren;
						
						[nRootNode insertSortedChildReverse: tFileTreeNode];
						
						[inHash setObject:tFileTreeNode forKey:[tNodeData filePath]];
						
						[tFileTreeNode release];
						
						tReportsChildren=[[tFilesChildren objectAtIndex:i] children];
						
						for(BMLinearTreeNode * tTreeNode in tReportsChildren)
						{
							tNodeData=BM_LINEAR_NODE_DATA(tTreeNode);
							
							if ([inScopeSet containsIndex:[tNodeData level]]==YES)
							{
								BMLinearTreeNode * tReportTreeNode;
								BMLinearNodeData * tReportLinearData;
								
								tReportLinearData=tNodeData;
								
								tReportTreeNode=[[BMLinearTreeNode alloc] initWithData:tReportLinearData
																				parent:nil
																			  children:[NSArray array]];
								
								if (tReportTreeNode!=nil)
								{
									[tFileTreeNode insertChild: tReportTreeNode
													   atIndex: [tFileTreeNode numberOfChildren]];
									
									[tReportTreeNode release];
								}
							}
						}
					}
				}
			}
		}
	}
	
	return [nRootNode autorelease];
}

@end
