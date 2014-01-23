#import "BMNibKeyedUnarchiver.h"

#import "BM_OSX_NSLocalizableString.h"

#import "BM_OSX_NSWindow.h"
#import "BM_OSX_NSWindowTemplate.h"

#import "BM_OSX_NSCell.h"
#import "BM_OSX_NSActionCell.h"
#import "BM_OSX_NSButtonCell.h"
#import "BM_OSX_NSPopUpButtonCell.h"
#import "BM_OSX_NSTextFieldCell.h"
#import "BM_OSX_NSTableHeaderCell.h"

#import "BM_OSX_NSView.h"
#import "BM_OSX_NSBox.h"
#import "BM_OSX_NSScrollView.h"
#import "BM_OSX_NSClipView.h"
#import "BM_OSX_NSCustomView.h"
#import "BM_OSX_NSControl.h"
#import "BM_OSX_NSButton.h"
#import "BM_OSX_NSPopUpButton.h"
#import "BM_OSX_NSTextField.h"

#import "BM_OSX_NSTabView.h"
#import "BM_OSX_NSTabViewItem.h"

#import "BM_OSX_NSMatrix.h"

#import "BM_OSX_NSTableColumn.h"
#import "BM_OSX_NSTableView.h"


#import "BM_OSX_NSMenuItem.h"
#import "BM_OSX_NSMenu.h"

#import "BM_OSX_NSIBObjectData.h"

#import "BM_OSX_NSCustomObject.h"
#import "BM_OSX_ArchivedObject.h"

#import "BM_OSX_NSButtonImageSource.h"

@implementation BMNibKeyedUnarchiver

- (id)initForReadingWithData:(NSData *)data
{
	id tResult=[super initForReadingWithData:data];
	
	if (tResult==nil)
	{
		NSLog(@"Oh Oh");
	}
	
	return tResult;
}

+ (NSDictionary *) supportedClasses
{
	static NSDictionary * sSupportedClassedCitionary=nil;
	
	if (sSupportedClassedCitionary==nil)
	{
		sSupportedClassedCitionary=[[NSDictionary alloc] initWithObjectsAndKeys://NSClassFromString(@"BM_OSX_ClassWapper"),@"NSClassSwapper",
                                                                                [NSDate class],@"NSDate",
                                                                                [NSNumber class],@"NSNumber",
                                                                                [NSMutableString class],@"NSMutableString",
                                                                                [NSString class],@"NSString",
                                                                                [NSArray class],@"NSArray",
                                                                                [NSMutableArray class],@"NSMutableArray",
                                                                                [NSDictionary class],@"NSDictionary",
                                                                                [NSMutableDictionary class],@"NSMutableDictionary",
                                                                                [NSSet class],@"NSSet",
                                                                                [NSMutableSet class],@"NSMutableSet",
                                                                                [BM_OSX_NSLocalizableString class],@"NSLocalizableString",
	
																			[BM_OSX_NSTableColumn class],@"NSTableColumn",
									
																			  [BM_OSX_NSResponder class],@"NSResponder",
									
																			// Windows
									
																			  [BM_OSX_NSWindow class],@"NSWindow",
																			  [BM_OSX_NSWindowTemplate class],@"NSWindowTemplate",
																			// Cells
									
																			  [BM_OSX_NSButtonImageSource class],@"NSButtonImageSource",
									
																			  [BM_OSX_NSCell class],@"NSCell",
																			  [BM_OSX_NSActionCell class],@"NSActionCell",
																			  [BM_OSX_NSButtonCell class],@"NSButtonCell",
																			  [BM_OSX_NSPopUpButtonCell class],@"NSPopUpButtonCell",
																			  [BM_OSX_NSTextFieldCell class],@"NSTextFieldCell",
																			  [BM_OSX_NSTableHeaderCell class],@"NSTableHeaderCell",
									
																			// Views
									
																			  
																			  [BM_OSX_NSView class],@"NSView",
                                                                                  [BM_OSX_NSBox class],@"NSBox",
                                                                                    [BM_OSX_NSScrollView class],@"NSScrollView",
                                    [BM_OSX_NSClipView class],@"NSClipView",
																			  [BM_OSX_NSCustomView class],@"NSCustomView",
																			  [BM_OSX_NSControl class],@"NSControl",
																			  [BM_OSX_NSButton class],@"NSButton",
																			  [BM_OSX_NSPopUpButton class],@"NSPopUpButton",
																			  [BM_OSX_NSTextField class],@"NSTextField",
																			  [BM_OSX_NSTableView class],@"NSTableView",
									
																			  [BM_OSX_NSMatrix class],@"NSMatrix",
																			  
																			  [BM_OSX_NSTabViewItem class],@"NSTabViewItem",
																			  [BM_OSX_NSTabView class],@"NSTabView",
																			
																			// Menus
									
																			  [BM_OSX_NSMenuItem class],@"NSMenuItem",
																			  [BM_OSX_NSMenu class],@"NSMenu",
									
									
																			  [BM_OSX_NSIBObjectData class],@"NSIBObjectData",
																			  [BM_OSX_NSCustomObject class],@"NSCustomObject",
																			  nil];
	}
	
	return sSupportedClassedCitionary;
}

- (Class) classForClassName:(NSString *) codedName
{
	Class tClass;
	
	tClass=[[BMNibKeyedUnarchiver supportedClasses] objectForKey:codedName];
	
	//NSLog(@"%@",codedName);
	
	if (tClass==nil)
	{
		//NSLog(@"Looking for %@",codedName);
		
		tClass=[BM_OSX_ArchivedObject class];
	}
	
	return tClass;
}

@end
