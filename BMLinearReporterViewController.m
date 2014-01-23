/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMLinearReporterViewController.h"
#import "BMLinearReportCell.h"

#define SAFE_LINEAR_TREE_NODE(n) 	((BMLinearTreeNode*)((n!=nil)?(n):(displayTree_)))

@implementation BMLinearReporterViewController

- (void) awakeFromNib
{
	NSTableColumn * tTableColumn;
	
	cachedScopeButtons_=[[NSArray alloc] initWithObjects:IBallScope_,IBerrorsScope_,IBwarningsScope_,IBnotesScope_,nil];
	
	scopeSetAll_=[NSMutableIndexSet new];
	
	[scopeSetAll_ addIndex:BM_PROBLEM_LEVEL_NOTE];
	
	[scopeSetAll_ addIndex:BM_PROBLEM_LEVEL_WARNING];
	
	[scopeSetAll_ addIndex:BM_PROBLEM_LEVEL_ERROR];
	
	scopeSet_=[[NSMutableIndexSet alloc] initWithIndexSet:scopeSetAll_];
	
	[IBallScope_ setState:NSOnState];
	
	[IBerrorsScope_ setState:NSOffState];
	
	[IBwarningsScope_ setState:NSOffState];
	
	[IBnotesScope_ setState:NSOffState];
	
	tTableColumn=[IBoutlineView_ tableColumnWithIdentifier:@"Report"];
	
	if (tTableColumn!=nil)
	{
		BMLinearReportCell * tProtoypeCell;
					
		tProtoypeCell=[[BMLinearReportCell alloc] initTextCell:@""];
					
		if (tProtoypeCell!=nil)
		{
			[tTableColumn setDataCell:tProtoypeCell];
			
			[tProtoypeCell release];
		}
	}
	
	[IBoutlineView_ setDoubleAction:@selector(revealSelectedIssues:)];
	[IBoutlineView_ setTarget:self];
	
	[IBoutlineView_ setAutoresizesOutlineColumn:NO];
	
	// A COMPLETER
	
	// Register for notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:[self view]];
}

- (id) initWithReportingDictionary:(NSDictionary *) inDictionary
{
	self=[super initWithReportingDictionary:inDictionary];
	
	if (self!=nil)
	{
		[self removeControllerDefaultForKey:[self disclosedStateKey]];
		
		[iconsCache_ release];
		
		iconsCache_=[[NSMutableDictionary alloc] initWithCapacity:10];
		
		if ([NSBundle loadNibNamed:@"BMBundleLinearReporterView" owner:self]==YES)
		{
		}
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[itemsToExpand_ release];
	
	[iconsCache_ release];
	
	[storageTree_ release];
	
	[storageTreeHash_ release];
	
	[displayTree_ release];
	
	[displayTreeHash_ release];
	
	[scopeSetAll_ retain];
	
	[scopeSet_ release];
	
	[cachedScopeButtons_ release];
	
	// A COMPLETER
	
	[IBcheckingView_ release];
	
	[IBnoGlitchesView_ release];

	[super dealloc];
}

#pragma mark -

- (NSString *) disclosedStateKey
{
	return @"LinearReport";
}

- (void) prepareData
{
	storageTree_=[BMLinearTreeNode buildTree];
	
	if (storageTree_!=nil)
	{
		storageTreeHash_=[[NSMutableDictionary alloc] initWithCapacity:100];
		
		if (storageTreeHash_==nil)
		{
			storageTree_=nil;
		}
		else
		{
			NSEnumerator * tKeyEnumerator;
			
			tKeyEnumerator=[reportDictionary_ keyEnumerator];
			
			if (tKeyEnumerator!=nil)
			{
				NSString * tFilePath;
				
				while (tFilePath=[tKeyEnumerator nextObject])
				{
					BMLinearNodeData * tFileLinearData;
					
					tFileLinearData=[BMLinearNodeData nodeOfType:BM_LINEAR_TREE_TYPE_FILE withReport:nil ofLevel:BM_PROBLEM_LEVEL_NOTE];
					
					if (tFileLinearData!=nil)
					{
						BMLinearTreeNode * tFileTreeNode;
						
						[tFileLinearData setFilePath:tFilePath];
						
						tFileTreeNode=[[BMLinearTreeNode alloc] initWithData:tFileLinearData
																	  parent:nil
																	children:[NSArray array]];
									
						if (tFileTreeNode!=nil)
						{
							NSDictionary * tLevelsDictionary;
							
							[storageTree_ insertSortedChildReverse:tFileTreeNode];
									   
							[storageTreeHash_ setObject:tFileTreeNode forKey:tFilePath];
							
							tLevelsDictionary=[reportDictionary_ objectForKey:tFilePath];
						
							if (tLevelsDictionary!=nil)
							{
								NSEnumerator * tLevelKeyEnumerator;
								
								tLevelKeyEnumerator=[tLevelsDictionary keyEnumerator];
								
								if (tLevelKeyEnumerator!=nil)
								{
									NSNumber * tLevelNumber;
									
									while (tLevelNumber=[tLevelKeyEnumerator nextObject])
									{
										NSArray * tReportArray;
										NSUInteger i,tCount;
										NSInteger tLevelValue;
										
										tLevelValue=[tLevelNumber longValue];

										
										tReportArray=[tLevelsDictionary objectForKey:tLevelNumber];
										
										tCount=[tReportArray count];
										
										for(i=0;i<tCount;i++)
										{
											NSDictionary * tReportDictionary;
											BMLinearNodeData * tReportLinearData;
											
											
											tReportDictionary=[tReportArray objectAtIndex:i];
											
											tReportLinearData=[BMLinearNodeData nodeOfType:BM_LINEAR_TREE_REPORT withReport:tReportDictionary ofLevel:tLevelValue];
											
											if (tReportLinearData!=nil)
											{
												BMLinearTreeNode * tReportTreeNode;
												
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
								else
								{
									// Low Memory
									
									// A COMPLETER
								}
							}
							
							[tFileTreeNode release];
						}
					
					}
				}
			}
		
			[storageTree_ retain];
			
			displayTreeHash_=[[NSMutableDictionary alloc] initWithCapacity:100];
			
			if (displayTreeHash_!=nil)
			{
				displayTree_=[[BMLinearTreeNode duplicateTree:storageTree_ limitedToScopes:scopeSet_ searchPattern:nil hash:displayTreeHash_] retain];
			}
		}
	}
	else
	{
		storageTree_=nil;
	}
}

- (void) delayedRefresh:(id) inObject
{
	NSUInteger tCount;
    
    [IBoutlineView_ reloadData];
    
	tCount=[itemsToExpand_ count];
	
	if (tCount>0)
	{
        for(id tItem in itemsToExpand_)
        {
            [IBoutlineView_ expandItem:tItem];
        }
		
		[itemsToExpand_ removeAllObjects];
	}
	
	[itemsToExpand_ release];
	
	itemsToExpand_=nil;
}

#pragma mark -

- (id) outlineView:(NSOutlineView *) inOutlineView child:(NSInteger) inIndex ofItem:(id) inItem
{
	if (inOutlineView==IBoutlineView_)
	{
		if (displayTree_!=nil)
		{
			return [SAFE_LINEAR_TREE_NODE(inItem) childAtIndex:inIndex];
		}
    }
	
    return nil;
}

- (BOOL) outlineView:(NSOutlineView *) inOutlineView isItemExpandable:(id) inItem
{
    if (inOutlineView==IBoutlineView_)
	{
		BMLinearNodeData * tNodeData;
		
		tNodeData=BM_LINEAR_NODE_DATA(inItem);
		
		return ([tNodeData isLeaf]==NO);
	}
	
	return NO;

}

- (NSInteger) outlineView:(NSOutlineView *) inOutlineView numberOfChildrenOfItem:(id) inItem
{
    if (inOutlineView==IBoutlineView_)
	{
		if (displayTree_!=nil)
		{
			return [SAFE_LINEAR_TREE_NODE(inItem) numberOfChildren];
		}
    }
	
    return 0;
}

- (id) outlineView:(NSOutlineView *) inOutlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id) inItem
{
	if (inOutlineView==IBoutlineView_)
	{
		BMLinearNodeData * tNodeData;
		
		tNodeData=BM_LINEAR_NODE_DATA(inItem);
		
		if ([tNodeData type]==BM_LINEAR_TREE_TYPE_FILE)
		{
			NSUInteger tLength;
			
			tLength=[bundlePath_ length];
			
			return [@"." stringByAppendingPathComponent:[[tNodeData filePath] substringFromIndex:tLength]];
		}
		else if ([tNodeData type]==BM_LINEAR_TREE_REPORT)
		{
			return [[tNodeData report] objectForKey:BM_PROBLEM_TITLE];
		}
	}
	
	return nil;
}

- (NSString *) outlineView:(NSOutlineView *) inOutlineView toolTipForCell:(NSCell *) inCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *) inTableColumn item:(id) inItem mouseLocation:(NSPoint)mouseLocation
{
	if (inOutlineView==IBoutlineView_)
	{
		BMLinearNodeData * tNodeData;
		
		tNodeData=BM_LINEAR_NODE_DATA(inItem);
		
		if ([tNodeData type]==BM_LINEAR_TREE_TYPE_FILE)
		{
			return [tNodeData filePath];
		}
	}
	
	return nil;
}

- (void) outlineView:(NSOutlineView *) inOutlineView willDisplayCell:(id) inCell forTableColumn:(NSTableColumn *) inTableColumn item:(id) inItem
{
	if (inOutlineView==IBoutlineView_)
	{
		if ([[inTableColumn identifier] isEqualToString:@"Report"])
		{
			BMLinearNodeData * tNodeData;
			BMLinearReportCell * tReportCell;
			
			tReportCell=(BMLinearReportCell *) inCell;
			
			tNodeData=BM_LINEAR_NODE_DATA(inItem);
			
			if ([tNodeData type]==BM_LINEAR_TREE_TYPE_FILE)
			{
				NSString * tFilePath;
				NSImage * tIcon=nil;
				NSUInteger tLength;
				//NSDictionary * tReportDictionary;
				
				//tReportDictionary=[tNodeData report];
				
				[tReportCell setType:BM_LINEAR_CELL_TYPE_FILE];
				
				// Icon
				
				tFilePath=[tNodeData filePath];
				
				if (tFilePath!=nil)
				{
					tIcon=[iconsCache_ objectForKey:tFilePath];
					
					if (tIcon==nil)
					{
						tIcon=[[NSWorkspace sharedWorkspace] iconForFile:tFilePath];
						
						if (tIcon!=nil)
						{
							[tIcon setScalesWhenResized:YES];
						
							[tIcon setSize:NSMakeSize(32.0,32.0)];
						
							[iconsCache_ setObject:tIcon forKey:tFilePath];
						}
					}
				}
				
				[tReportCell setIcon:tIcon];
				
				// Text
				
				tLength=[bundlePath_ length];
				
				[tReportCell setTitle:[@"." stringByAppendingPathComponent:[[tNodeData filePath] substringFromIndex:tLength]]];
				
				
				// Notes, Warnings & Errors 
					
				[tReportCell setNotes:[tNodeData notes] warnings:[tNodeData warnings] errors:[tNodeData errors]];
			}
			else
			{
				NSDictionary * tReportDictionary;
				
				[tReportCell setType:BM_LINEAR_CELL_TYPE_REPORT];
				
				switch([tNodeData level])
				{
					case BM_PROBLEM_LEVEL_NOTE:
						
						[tReportCell setIcon:[BMLinearReportCell noteIcon]];
						
						break;
						
					case BM_PROBLEM_LEVEL_WARNING:
						
						[tReportCell setIcon:[BMLinearReportCell warningIcon]];
						
						break;

					case BM_PROBLEM_LEVEL_ERROR:
					
						[tReportCell setIcon:[BMLinearReportCell errorIcon]];
					
						break;

				}

				tReportDictionary=[tNodeData report];
				
				if (tReportDictionary!=nil)
				{
					NSString * tDescription;
					
					[tReportCell setTitle:[tReportDictionary objectForKey:BM_PROBLEM_TITLE]];
					
					[tReportCell setHighlightRange:NSMakeRange(NSNotFound,0)];
					
					tDescription=[tReportDictionary objectForKey:BM_PROBLEM_DESCRIPTION];
				
					if ([tDescription length]>0 /*&& [tNodeData descriptionVisible]==YES*/)
					{
						NSDictionary * tExtrasDictionary;
						
						tExtrasDictionary=[tReportDictionary objectForKey:BM_PROBLEM_EXTRAS];
						
						if (tExtrasDictionary!=nil)
						{
							NSString * tRangeString;
							
							tRangeString=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_HIGHLIGHT_TEXT_RANGE];
							
							if (tRangeString!=nil)
							{
								[tReportCell setHighlightRange:NSRangeFromString(tRangeString)];
							}
						}
						
						[tReportCell setDescription:tDescription];
					}
					else
					{
						[tReportCell setDescription:nil];
					}
				}
				else
				{
					[tReportCell setTitle:nil];
					
					[tReportCell setDescription:nil];
				}
			}
		}
	}
}

- (CGFloat) outlineView:(NSOutlineView *) inOutlineView heightOfRowByItem:(id) inItem
{
	if (inOutlineView==IBoutlineView_)
	{
		BMLinearNodeData * tNodeData;
		
		
		tNodeData=BM_LINEAR_NODE_DATA(inItem);
		
		if ([tNodeData type]==BM_LINEAR_TREE_TYPE_FILE)
		{
			return 36.0;
		}
		else
		{
			NSDictionary * tReportDictionary;
			NSString * tDescription=nil;
			NSTableColumn * tTableColumn;
			NSSize tSize;
			
			tReportDictionary=[tNodeData report];
			
            tSize.width=0.;
			tSize.height=20.0;
			
			tTableColumn=[inOutlineView tableColumnWithIdentifier:@"Report"];
			
			if (tTableColumn!=nil)
			{
				tSize.width=[tTableColumn width]-32.0;
			}
			
			/*if ([tNodeData descriptionVisible]==YES)*/
			{
				tDescription=[tReportDictionary objectForKey:BM_PROBLEM_DESCRIPTION];
			}
			
			return [BMLinearReportCell heightOfCellWithTitle:[tReportDictionary objectForKey:BM_PROBLEM_TITLE] description:tDescription frameSize:tSize];
		}
	}
	
	return 15.0;
}

#pragma mark -

- (void) expandItem:(BMLinearTreeNode *) inFileTree ifKeyOfDictionary:(NSMutableDictionary *) inDictionary
{
    if (inFileTree!=nil && [inDictionary count]>0)
	{
		if ([BM_LINEAR_NODE_DATA(inFileTree) isLeaf]==NO)
		{
            NSString * tFilePath;
            NSArray * tChildren;
            NSNumber * tNumber;

            tFilePath=[BM_LINEAR_NODE_DATA(inFileTree) filePath];

            [IBoutlineView_ expandItem:inFileTree];

            // Check children

            tChildren=[inFileTree children];

            for(BMLinearTreeNode * tFileTree in tChildren)
            {
                [self expandItem:tFileTree ifKeyOfDictionary:inDictionary];
            }

            tNumber=[inDictionary objectForKey:tFilePath];

            if (tNumber==nil || [tNumber boolValue]==NO)
            {
                [IBoutlineView_ collapseItem:inFileTree];
            }
		}
	}
}

- (void) restoreDisclosedStates
{
    NSDictionary * tDictionary;

    tDictionary=[self controllerDefaultForKey:[self disclosedStateKey]];

    if (tDictionary!=nil)
    {
        NSMutableDictionary * tDictionaryCopy;

        tDictionaryCopy=[tDictionary mutableCopy];

        if (tDictionaryCopy!=nil)
        {
            NSArray * tChildren;

            tChildren=[displayTree_ children];

            for(BMLinearTreeNode * tFileTree in tChildren)
            {
                [self expandItem:tFileTree ifKeyOfDictionary:tDictionaryCopy];
            }

            [tDictionaryCopy release];
        }
    }
}

#pragma mark -

- (void) revealSelectedIssues:(id) sender
{
	NSIndexSet * tIndexSet;
	
	tIndexSet=[IBoutlineView_ selectedRowIndexes];
	
	if ([tIndexSet count]>0)
	{
		NSUInteger tIndex;
		
		tIndex=[tIndexSet firstIndex];
		
		while (tIndex!=NSNotFound)
		{
			BMLinearTreeNode * tNode;
			
			tNode=[IBoutlineView_ itemAtRow:tIndex];
			
			if (tNode!=nil)
			{
				NSString * tAbsolutePath=nil;
                
				BMLinearNodeData * tNodeData=BM_LINEAR_NODE_DATA(tNode);
				
				if ([tNodeData type]==BM_LINEAR_TREE_REPORT)
				{
					NSDictionary * tReportDictionary=[tNodeData report];
					
					tAbsolutePath=[BM_LINEAR_NODE_DATA([tNode nodeParent]) filePath];
					
					NSDictionary * tExtrasDictionary=[tReportDictionary objectForKey:BM_PROBLEM_EXTRAS];
					
					NSNumber * tLineNumber=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_LINE_NUMBER];
					
					if (tLineNumber!=nil)
					{
#define XED_PATH	@"/usr/bin/xed"
						
						// Look for xed
						
						if ([[NSFileManager defaultManager] fileExistsAtPath:XED_PATH]==YES)
						{
							NSTask * tTask;
						
							tTask=[[NSTask new] autorelease];
						
							if (tTask!=nil)
							{
								[tTask setLaunchPath:XED_PATH];
								
								[tTask setArguments:[NSArray arrayWithObjects:@"-l",[tLineNumber stringValue],tAbsolutePath,nil]];
								
								[tTask launch];
								
								return;
							}
						}
					}
					
					[[NSWorkspace sharedWorkspace] selectFile:tAbsolutePath inFileViewerRootedAtPath:@""];
				}
				else if ([tNodeData type]==BM_LINEAR_TREE_TYPE_FILE)
				{
					tAbsolutePath=[tNodeData filePath];
					
					[[NSWorkspace sharedWorkspace] selectFile:tAbsolutePath inFileViewerRootedAtPath:@""];
				}
			}
			
			tIndex=[tIndexSet indexGreaterThanIndex:tIndex];
		}
	}
}

- (void) _switchedToScope:(id) sender
{
	NSUInteger i,tCount;
	NSInteger tTag=-1;
	
	if ([sender isKindOfClass:[NSMenuItem class]]==YES)
	{
		tTag=[sender tag];
	}
	
	tCount=[cachedScopeButtons_ count];
	
	for(i=0;i<tCount;i++)
	{
		NSButton * tButton;
		
		tButton=[cachedScopeButtons_ objectAtIndex:i];
		
		if (tButton!=sender)
		{
			if (tTag!=-1)
			{
				if ([tButton tag]==tTag)
				{
					[tButton setState:NSOnState];
					
					continue;
				}
			}
			
			[tButton setState:NSOffState];
		}
	}
}

- (IBAction) switchScope:(id) sender
{
	[scopeSet_ removeAllIndexes];
	
	if ([sender tag]==7)
	{
		[scopeSet_ addIndexes:scopeSetAll_];
	}
	else
	{
		[scopeSet_ addIndex:[sender tag]];
	}
	
	[self _switchedToScope:sender];
	
	[displayTreeHash_ release];
	
	[displayTree_ release];
	
	displayTreeHash_=[[NSMutableDictionary alloc] initWithCapacity:100];
	
	if (displayTreeHash_!=nil)
	{
		displayTree_=[[BMLinearTreeNode duplicateTree:storageTree_ limitedToScopes:scopeSet_ searchPattern:nil hash:displayTreeHash_] retain];
	}
	
	// A COMPLETER (Gestion de la selection + disclosure)
	
	[IBoutlineView_ reloadData];
	
	[self restoreDisclosedStates];
}

#pragma mark -

- (void) didReceiveNewReport:(NSDictionary *) inReportDictionary forFileAtPath:(NSString *) inPath level:(NSNumber *) inLevelNumber
{
	if (inReportDictionary!=nil && inPath!=nil && inLevelNumber!=nil)
	{
		BMLinearTreeNode * tFileTreeNode;
		NSInteger tLevelValue;
		
		tLevelValue=[inLevelNumber longValue];
		
		tFileTreeNode=[storageTreeHash_ objectForKey:inPath];
		
		if (tFileTreeNode==nil)
		{
			BMLinearNodeData * tFileLinearData;
			
			tFileLinearData=[BMLinearNodeData nodeOfType:BM_LINEAR_TREE_TYPE_FILE withReport:nil ofLevel:tLevelValue];
			
			if (tFileLinearData!=nil)
			{
				[tFileLinearData setFilePath:inPath];
				
				tFileTreeNode=[[BMLinearTreeNode alloc] initWithData:tFileLinearData
															  parent:nil
															children:[NSArray array]];
							
				if (tFileTreeNode!=nil)
				{
					[storageTree_ insertSortedChildReverse: tFileTreeNode];
							   
					[storageTreeHash_ setObject:tFileTreeNode forKey:inPath];
					
					[tFileTreeNode release];
				}
			}
		}
		
		if (tFileTreeNode!=nil)
		{
			BMLinearNodeData * tFileLinearData;
			
			tFileLinearData=BM_LINEAR_NODE_DATA(tFileTreeNode);
			
			if (tFileLinearData!=nil)
			{
				BMLinearNodeData * tReportLinearData;
				
				tReportLinearData=[BMLinearNodeData nodeOfType:BM_LINEAR_TREE_REPORT withReport:inReportDictionary ofLevel:tLevelValue];
				
				if (tReportLinearData!=nil)
				{
					BMLinearTreeNode * tReportTreeNode;
					
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
		
		if ([scopeSet_ containsIndex:tLevelValue]==YES)
		{
			BOOL isNewFile=NO;
						
			tFileTreeNode=[displayTreeHash_ objectForKey:inPath];
			
			if (tFileTreeNode==nil)
			{
				BMLinearNodeData * tFileLinearData;
				
				tFileLinearData=[BMLinearNodeData nodeOfType:BM_LINEAR_TREE_TYPE_FILE withReport:nil ofLevel:tLevelValue];
				
				if (tFileLinearData!=nil)
				{
					[tFileLinearData setFilePath:inPath];
					
					tFileTreeNode=[[BMLinearTreeNode alloc] initWithData:tFileLinearData
																  parent:nil
																children:[NSArray array]];
					
					if (tFileTreeNode!=nil)
					{
						[displayTree_ insertSortedChildReverse: tFileTreeNode];
						
						[displayTreeHash_ setObject:tFileTreeNode forKey:inPath];
						
						[tFileTreeNode release];
						
						isNewFile=YES;
					}
				}
			}
			
			if (tFileTreeNode!=nil)
			{
				BMLinearNodeData * tFileLinearData;
				
				tFileLinearData=BM_LINEAR_NODE_DATA(tFileTreeNode);
				
				if (tFileLinearData!=nil)
				{
					BMLinearNodeData * tReportLinearData;
					
					tReportLinearData=[BMLinearNodeData nodeOfType:BM_LINEAR_TREE_REPORT withReport:inReportDictionary ofLevel:tLevelValue];
					
					if (tReportLinearData!=nil)
					{
						BMLinearTreeNode * tReportTreeNode;
						
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
			
			if (isNewFile==YES)
			{
				[itemsToExpand_ addObject:tFileTreeNode];
			}
		
			/*[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedRefresh:) object:nil];
		
			[self performSelector:@selector(delayedRefresh:) withObject:nil afterDelay:0.1];*/
		}
	}
}

- (BOOL) canSwitchScope
{
	return (noGlitchesFound_==NO);
}

- (void) analysisWillStart
{
	NSRect tBounds;
	NSRect tFrame;
	
	[super analysisWillStart];
	
	
	
	[storageTree_ release];
	
	storageTree_=nil;
	
	[displayTree_ release];
	
	displayTree_=nil;
	
	[IBoutlineView_ setHidden:YES];
    
    [IBoutlineView_ deselectAll:nil];
    
    [IBoutlineView_ reloadData];
	
	if (outlineSubView_!=nil)
	{
		[outlineSubView_ removeFromSuperview]; 
	}
	
	outlineSubView_=IBcheckingView_;
	
	tBounds=[IBoutlineView_ bounds];
	
	tFrame=[outlineSubView_ frame];
	
	tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
	tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
	
	[outlineSubView_ setFrame:tFrame];
    
	[self.view addSubview:outlineSubView_];
	
	[IBallScope_ setEnabled:NO];
	
	[IBerrorsScope_ setEnabled:NO];
	
	[IBwarningsScope_ setEnabled:NO];
	
	[IBnotesScope_ setEnabled:NO];
	
	[IBspinningIndicator_ startAnimation:nil];
	
	[itemsToExpand_ release];
	
	itemsToExpand_=[[NSMutableArray alloc] initWithCapacity:10];
	
	[self prepareData];
}

- (void) analysisDidStart
{
	// A COMPLETER
}

- (void) analysisDidComplete
{
	[storageTreeHash_ release];
	
	storageTreeHash_=nil;
	
	[displayTreeHash_ release];
	
	displayTreeHash_=nil;
	
	if (outlineSubView_!=nil)
	{
		[IBspinningIndicator_ stopAnimation:nil];
		
		[outlineSubView_ removeFromSuperview]; 
	}
	
	if ([reportDictionary_ count]==0)
	{
		NSRect tBounds;
		NSRect tFrame;
		
		outlineSubView_=IBnoGlitchesView_;
		
		noGlitchesFound_=YES;
		
		tBounds=[IBoutlineView_ bounds];
		
		tFrame=[outlineSubView_ frame];
		
		tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
		tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
		
		[outlineSubView_ setFrame:tFrame];
		
		[self.view addSubview:outlineSubView_];
	}
	else
	{
		[IBoutlineView_ setHidden:NO];
        
        outlineSubView_=nil;
		
		noGlitchesFound_=NO;
		
		[IBallScope_ setEnabled:YES];
		
		[IBerrorsScope_ setEnabled:YES];
		
		[IBwarningsScope_ setEnabled:YES];
		
		[IBnotesScope_ setEnabled:YES];
		
		[self delayedRefresh:nil];
        
        [[[self view] window] setViewsNeedDisplay:YES];
	}
}

#pragma mark -

- (void) outlineViewFrameDidChange:(NSNotification *) inNotification
{
	if (outlineSubView_!=nil)
	{
		NSRect tBounds;
		NSRect tFrame;
		
		tBounds=[IBoutlineView_ bounds];
		
		tFrame=[outlineSubView_ frame];
		
		tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
		tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
		
		[outlineSubView_ setFrame:tFrame];
	}
	
	if (noGlitchesFound_==NO)
	{
		[IBoutlineView_ noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[IBoutlineView_ numberOfRows])]];
	}
}

- (void) outlineViewItemDidExpand:(NSNotification *) inNotification
{
	if (inNotification!=nil)
	{
		NSDictionary * tUserInfo;
		
		tUserInfo=[inNotification userInfo];
		
		if (tUserInfo!=nil)
		{
			BMLinearTreeNode * tTreeNode;
			
			tTreeNode=(BMLinearTreeNode *) [tUserInfo objectForKey:@"NSObject"];
			
			if (tTreeNode!=nil)
			{
				NSString * tFilePath;
				
				tFilePath=[BM_LINEAR_NODE_DATA(tTreeNode) filePath];
				
				if (tFilePath!=nil)
				{
					NSMutableDictionary * tDisclosedDictionary;
					NSString * tKey;
					
					tKey=[self disclosedStateKey];
					
					tDisclosedDictionary=[self controllerDefaultForKey:tKey];
					
					if (tDisclosedDictionary==nil)
					{
						tDisclosedDictionary=[NSMutableDictionary dictionary];
						
						if (tDisclosedDictionary!=nil)
						{
							[self setControllerDefault:tDisclosedDictionary forKey:tKey];
						}
						else
						{
							NSLog(@"[BMLinearReporterViewController outlineViewItemDidExpand:] Low memory");
						}
					}
					
					if (tDisclosedDictionary!=nil)
					{
						[tDisclosedDictionary setObject:[NSNumber numberWithBool:YES] forKey:tFilePath];
					}
				}
			}
		}
	}
}

- (void) outlineViewItemWillCollapse:(NSNotification *) inNotification
{
	if (inNotification!=nil)
	{
		NSDictionary * tUserInfo;
		
		tUserInfo=[inNotification userInfo];
		
		if (tUserInfo!=nil)
		{
			BMLinearTreeNode * tTreeNode;
			
			tTreeNode=(BMLinearTreeNode *) [tUserInfo objectForKey:@"NSObject"];
			
			if (tTreeNode!=nil)
			{
				NSString * tFilePath;
				
				tFilePath=[BM_LINEAR_NODE_DATA(tTreeNode) filePath];
				
				if (tFilePath!=nil)
				{
					NSMutableDictionary * tDisclosedDictionary;
					
					tDisclosedDictionary=[self controllerDefaultForKey:[self disclosedStateKey]];
					
					if (tDisclosedDictionary!=nil)
					{
						[tDisclosedDictionary removeObjectForKey:tFilePath];
					}
				}
			}
		}
	}
}

@end
