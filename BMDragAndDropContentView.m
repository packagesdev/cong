/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMDragAndDropContentView.h"


NSString * const BMDragAndDropContentViewDidChangeNotification=@"BMDragAndDropContentViewDidChangeNotification";

@implementation NSObject (BMDragAndDropContentViewNotification)

- (void) dropViewFilePathDidChange:(NSNotification *) inNotification
{
}

@end

@implementation BMDragAndDropContentView

- (id) initWithFrame:(NSRect) inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		// Register for Drop
		
		[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	}
	
	return self;
}

#pragma mark -

- (BOOL) isOpaque
{
	return YES;
}

- (void) drawRect:(NSRect) inRect
{
    NSBezierPath * tBezierPath;
	NSRect tBounds;
	NSImage * tImage;
	
	tBounds=[self bounds];	
	
	tBounds=NSInsetRect(tBounds,12,12);
	
	tBezierPath=[NSBezierPath bezierPathWithRoundedRect:tBounds xRadius:5 yRadius:5];
	
	if (tBezierPath!=nil)
	{
		CGFloat tArray[2]={10.0f,6.0f};
		
		if (highlighted_==NO)
		{
			[[NSColor colorWithCalibratedWhite:0.85f alpha:0.5f] set];
		}
		else
		{
			[[NSColor colorWithCalibratedWhite:0.7f alpha:0.5f] set];
		}

		[tBezierPath fill];
		
		[tBezierPath setLineDash:tArray count:2 phase:0.5f];
		
		[tBezierPath setLineWidth:3.0f];
		
		if (highlighted_==NO)
		{
			[[NSColor colorWithCalibratedWhite:0.6f alpha:0.5f] set];
		}
		else
		{
			[[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f] set];
			//[[NSColor colorWithCalibratedRed:181.0/255 green:213.0/255 blue:1.0 alpha:1.0] set];
			//[[NSColor alternateSelectedControlColor] set];
		}
		
		[tBezierPath stroke];
	}
	
	// Draw Icon
	
	if (highlighted_==NO)
	{
		static NSImage * sApplicationIcon=nil;
		
		if (sApplicationIcon==nil)
		{
			sApplicationIcon=[[NSImage imageNamed:@"applicationSmall"] copy];
		}
		
		tImage=sApplicationIcon;
	}
	else
	{
		static NSImage * sApplicationIconHighlighted=nil;
		
		if (sApplicationIconHighlighted==nil)
		{
			sApplicationIconHighlighted=[[NSImage imageNamed:@"applicationSmallHighlighted"] copy];
		}
		
		tImage=sApplicationIconHighlighted;
	}
	
	if (tImage!=nil)
	{
		NSSize tImageSize;
		
		tImageSize=[tImage size];
		
		[tImage drawInRect:NSMakeRect(round(NSMidX(tBounds)-tImageSize.width*0.5),round(NSMidY(tBounds)-tImageSize.height*0.5),tImageSize.width,tImageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	
	// A COMPLETER
}

#pragma mark -

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard * tPasteBoard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
	
    tPasteBoard = [sender draggingPasteboard];
	
    if ( [[tPasteBoard types] containsObject:NSFilenamesPboardType] )
    {
        if (sourceDragMask & NSDragOperationCopy)
        {
            NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
			
			if (tFiles!=nil && [tFiles count]==1)
			{
				NSString * tFilePath;
				MDItemRef tItemRef;
				BOOL isDirectory;\
				tFilePath=[tFiles objectAtIndex:0];
				
				tItemRef = MDItemCreate(kCFAllocatorDefault, (CFStringRef) tFilePath);
				
				if (tItemRef!=nil)
				{
					CFTypeRef tTypeRef;
					
					tTypeRef = MDItemCopyAttribute(tItemRef, kMDItemContentType);
					
					CFRelease(tItemRef);
					
					if (tTypeRef!=NULL)
					{
						NSArray * tSupportedUTIs;
						NSUInteger i,tCount;
						
						tSupportedUTIs=[NSArray arrayWithObjects:@"com.apple.framework",
																 @"com.apple.plugin",
																 @"com.apple.application-bundle",
																 @"com.apple.bundle",
																 @"com.apple.metadata-importer",
																 @"com.apple.automator-action",
																 @"com.apple.systempreference.prefpane",
																 nil];
						
						tCount=[tSupportedUTIs count];
						
						for(i=0;i<tCount;i++)
						{
							if (UTTypeConformsTo(tTypeRef, (CFStringRef) [tSupportedUTIs objectAtIndex:i])==TRUE)
							{
								highlighted_=YES;
								
								[self setNeedsDisplay:YES];
								
								CFRelease(tTypeRef);
								
								return NSDragOperationCopy;
							}
						}
						
						CFRelease(tTypeRef);
					}
				}
				
				// For annoying apps like FaceTime and Evernote
				
				if ([[tFilePath pathExtension] caseInsensitiveCompare:@"app"]==NSOrderedSame &&
					[[NSFileManager defaultManager] fileExistsAtPath:tFilePath isDirectory:&isDirectory]==YES && isDirectory==YES)
				{
					highlighted_=YES;
					
					[self setNeedsDisplay:YES];
					
					return NSDragOperationCopy;
				}
			}
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard * tPasteBoard;
	
    tPasteBoard = [sender draggingPasteboard];
	
    if ( [[tPasteBoard types] containsObject:NSFilenamesPboardType] )
    {
        NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
        
		if (tFiles!=nil && [tFiles count]==1)
		{
			NSString * tFilePath;
			
			tFilePath=[tFiles objectAtIndex:0];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:BMDragAndDropContentViewDidChangeNotification
																object:self
															  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:tFilePath,@"Path",nil]];
			
			return YES;
		}
    }
	
    return NO;
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	highlighted_=NO;
	
    [self setNeedsDisplay:YES];
    
    return YES;
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
    highlighted_=NO;
	
    [self setNeedsDisplay:YES];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}


@end
