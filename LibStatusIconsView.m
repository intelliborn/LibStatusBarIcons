/*

LibStatusIconsView.h ...
Copyright (C) 2010  Intelliborn <support@intelliborn.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License (LGPL) as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

// LibStatusIconsView uses mobilesubstrate to hook into each individual StatusBar in iOS4.  It hooks into the Battery display, and makes it larger/smaller as icons are added/removed.
// Email github@intelliborn.com or contact psuskeels with any change requests.
//
// TODO: Use the battery percent if available


#include "LibStatusIconsView.h"
#include "Hooker.h"

#define PADDING 2

int globalWidth;


IntelliStatusIconsView* instance;
id candidateBatteryView;
#import <SystemConfiguration/SystemConfiguration.h>
SCDynamicStoreRef storeRef;
@implementation IntelliStatusIconsManager

#define VERSION "0.7"
#define DEBUGME 1

-(id) init
{
	self = [super init];
	imageNamesArray = [[NSMutableArray alloc] init];
	imageNamesDict = [[NSMutableDictionary alloc] init];
	intelliViewsArray = [[NSMutableArray alloc] init];
	return self;
}

-(id) getIntelliStatusIconsView
{
	// SpringBoard creates and release their stuff.. let's not cache
	id newView = [[[IntelliStatusIconsView alloc] init] autorelease];
	[newView copyNames: imageNamesArray];
	[newView layoutSubviews];
	[intelliViewsArray addObject: newView];
	#ifdef DEBUME
	NSLog(@"Current intelliview count: %d", [intelliViewsArray count]);
	#endif
	return newView;
}

-(void) removeIntelliStatusIconsView: (id) removeView
{
	[intelliViewsArray removeObject: removeView];
}


+(IntelliStatusIconsManager*) sharedInstance
{
	if (instance == nil)
	{
		instance = [[IntelliStatusIconsManager alloc] init];
	}
	return instance;
}

-(void) redoForStyleChange
{

	for (int x=0; x < [intelliViewsArray count]; x++)
	{
		[[intelliViewsArray objectAtIndex: x] layoutSubviews];
	}
}

-(void)doRealAddStatusBarImageName: (NSString*) imageName
{
	#ifdef DEBUME
	NSLog(@"doRealAddStatusBarImageName: %@", imageName);
	#endif
	bool repost = false;

	if (![imageNamesDict objectForKey: imageName])
	{
		[imageNamesArray addObject: imageName];
		[imageNamesDict setObject: imageName forKey: imageName];

		for (int x=0; x < [intelliViewsArray count]; x++)
		{
			[[intelliViewsArray objectAtIndex: x] doAddIconImageName: imageName];
		}
	}
}

-(void)doRealRemoveStatusBarImageName: (NSString*) imageName
{
	#ifdef DEBUME
	NSLog(@"doRealRemoveStatusBarImageName: %@", imageName);
	#endif
	if ([imageNamesDict objectForKey: imageName])
	{
		[imageNamesArray removeObject: imageName];
		[imageNamesDict removeObjectForKey: imageName];
		//NSLog(@"removed it from dict");
		for (int x=0; x < [intelliViewsArray count]; x++)
		{
			[[intelliViewsArray objectAtIndex: x] doRemoveIconImageName: imageName];
		}
	}
}


-(void) addRemoveImages: (NSArray*) finalImagesList
{

	NSMutableDictionary* allCurrentImagesDict = [[imageNamesDict mutableCopy] autorelease];
	for (int x=0; x< [finalImagesList count]; x++)
	{
		NSString* iconName = [finalImagesList objectAtIndex: x];
		[allCurrentImagesDict removeObjectForKey: iconName];
		// this will check if really needs add
		[self doRealAddStatusBarImageName: iconName];
	}

	// remvoe what shouldn't be theree
	NSArray* allCurrentImagesArray = [allCurrentImagesDict allValues];
	for (int x=0; x< [allCurrentImagesArray count]; x++)
	{
		NSString* iconName = [allCurrentImagesArray objectAtIndex: x];
		#ifdef DEBUME
		NSLog(@"REMOVING: %@", iconName);
		#endif
		// this will check if really needs add
		[self doRealRemoveStatusBarImageName: iconName];
	}
}


-(void) sendIntelliStatusBarsAction: (int) action forImage: (NSString*) imageName
{
	NSMutableArray *allIcons = [[[(NSMutableArray *)SCDynamicStoreCopyValue(storeRef,(CFStringRef)INTELLI_DYNAMIC_DICT ) autorelease] mutableCopy] autorelease];
	if (allIcons == nil)
	{
		allIcons = [[[NSMutableArray alloc] init] autorelease];
	}
	if (action == INTELLISB_ADD_IMAGE)
	{
		if (![allIcons containsObject: imageName])
		{
			[allIcons addObject: imageName];
		}
	}
	else
	{
		if ([allIcons containsObject: imageName])
		{
			[allIcons removeObject: imageName];
		}
	}
	SCDynamicStoreSetValue(storeRef, INTELLI_DYNAMIC_DICT, allIcons);
}


-(void) reloadImages
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	if (storeRef != nil)
	{
		NSArray *allStatusIconsArray = (NSArray *)SCDynamicStoreCopyValue(storeRef,(CFStringRef)INTELLI_DYNAMIC_DICT );
		#ifdef DEBUME
		NSLog(@"ALL STATUS ICONS ARE: %@", allStatusIconsArray);
		#endif
		if (allStatusIconsArray != nil)
		{
			[self performSelectorOnMainThread: @selector(addRemoveImages:)  withObject: allStatusIconsArray waitUntilDone: NO];
			[allStatusIconsArray release];
		}
	}


	[pool release];

}

@implementation IntelliStatusIconsView

-(id) init
{
	self = [super init];
	[self setUserInteractionEnabled: false];
	imageNames = [[NSMutableArray alloc] init];
	imagesViewsDict = [[NSMutableDictionary alloc] init];
	return self;
}

-(void) copyNames: (NSMutableArray*) names
{
	[imageNames addObjectsFromArray: names];
}
-(void) removeFromSuperview
{
	#ifdef DEBUME
	NSLog(@"Being removed from %@", [self superview]);
	#endif
	[super removeFromSuperview];
	[instance removeIntelliStatusIconsView: self];
}

-(void)doAddIconImageName: (NSString*) imageName
{
	#ifdef DEBUME
	NSLog(@"doAddIconImageName: %@", imageName);
	#endif
	bool repost = false;

	if (![imageNames containsObject: imageName])
	{
		[imageNames addObject: imageName];
		[self layoutSubviews];
	}
}


-(void)doRemoveIconImageName: (NSString*) imageName
{
	//NSLog(@"doRealRemoveStatusBarImageName: ", imageName);
	int foundIndex = -1;
	for (int x=0; x < [imageNames count]; x++)
	{
		if ([[imageNames objectAtIndex: x] isEqualToString: imageName])
		{
			foundIndex = x;
			break;
		}
	}
	if (foundIndex >= 0)
	{
		[imageNames removeObjectAtIndex: foundIndex];
		id imageView = [imagesViewsDict objectForKey: imageName];
		if (imageView != nil)
		{
			needsReLayout = true;
			[imagesViewsDict removeObjectForKey: imageName];
			[imageView removeFromSuperview];
		}
	}
	[self layoutSubviews];
}

-(void) layoutSubviews
{
	[super layoutSubviews];
	// for all of them.
	int currentStyle = -1;

	@try
	{
		id superview = [self superview] ;
		[superview setFrame: [superview frame]];
		id manager = [superview layoutManager];
		currentStyle = [[manager foregroundView] foregroundStyle];
		[[manager foregroundView] reflowItemViews: true suppressCenterAnimation: true];
	}
	@catch (NSException* e)
	{
		NSLog(@"Error while resetting layout: %@", e);
	}
	if (currentStyle == -1)
	{
		// try status bar
		id statusBar =[[UIApplication sharedApplication] statusBar];
		int currentStyle = [statusBar currentStyle];
	}
	//NSLog(@"  Layoutsubviews - current style %d", currentStyle);
	float totalWidth = 0;

	for (int x= 0; x < [imageNames count]; x++)
	{

		NSString* imageName = [imageNames objectAtIndex: x];
		NSString* imagePath = nil;
		UIImageView* imageView = [imagesViewsDict objectForKey: imageName];
		bool needsUpdate = false;
		if (imageView != nil)
		{
			// we already have an image view for this imagename
			// need to see if the style has changed.
			if ([imageView tag]	!= currentStyle)
			{
				needsUpdate = true;
			}

		}
		else
		{
			needsUpdate = true;
		}

		if (needsUpdate)
		{
			if (currentStyle  == 2)
			{
				imagePath = [NSString stringWithFormat: @"/System/Library/CoreServices/SpringBoard.app/FSO_%@", imageName];
			}
			else
			{
				imagePath = [NSString stringWithFormat: @"/System/Library/CoreServices/SpringBoard.app/Default_%@", imageName];
			}

			UIImage* image = [UIImage imageAtPath: imagePath];
			if (image != nil)
			{

				if (imageView == nil)
				{
					imageView = [[[UIImageView alloc] initWithImage: image] autorelease];
					[imageView setTag: currentStyle];
					[imagesViewsDict setObject: imageView forKey: imageName];
					[self addSubview: imageView];
					needsReLayout = true;
				}
				else
				{
					[imageView setImage: image];

				}
			}
			else
			{
				NSLog(@"IntelliStatus: ** Could not add image name: %@. Does not exist", imageName);
			}
		}
		//NSLog(@"IMage frame: %@", imageView);
		totalWidth += [imageView frame].size.width + PADDING;
	}
	globalWidth = totalWidth+22 + PADDING;
	if (needsReLayout)
	{
		#ifdef DEBUME
		NSLog(@" -- setting self size %d", (int)totalWidth);
		#endif
		[self setSize: CGSizeMake(totalWidth, 20)];

		// doesn't matter what we set it to-- it'll override
		@try
		{
			id superview = [self superview] ;
			[superview setFrame: [superview frame]];
			id manager = [superview layoutManager];
			//NSLog(@"Got layout :%@", manager);
			[[manager foregroundView] reflowItemViews: true suppressCenterAnimation: true];
		}
		@catch (NSException* e)
		{
			NSLog(@"Error while resetting layout: %@", e);
		}
		// Need to set each view --
		float lastInsertPoint = totalWidth;
		for (int x= [imageNames count]-1; x >= 0 ; x--)
		{
			NSString* imageName = [imageNames objectAtIndex: x];
			UIImageView* imageView = [imagesViewsDict objectForKey: imageName];
			CGRect frame = [imageView frame];
			// modify x adjust for padding
			int padding = 0;
			frame.origin.x = lastInsertPoint - frame.size.width - PADDING;
			lastInsertPoint = frame.origin.x;
			//NSLog(@" Inserting %@ at %f", imageName, frame.origin.x);
			[imageView setFrame: frame];


		}

	}

}


@end

@implementation NSObject (IntelliStatusBarIcons)

int lastStyle;
-(void) UIStatusBar_setStyle: (int) style
{
	[self UIStatusBar_setStyle: (int) style];
	if (lastStyle != style)
	{
		[instance redoForStyleChange];
	}

}

-(void)NewSpring_addStatusBarImageNamed: (NSString*) imageName
{
	// broadcast
	 if (instance == nil)
	 {
		 [IntelliStatusIconsManager sharedInstance];
	 }
	[instance doRealAddStatusBarImageName: imageName];
	[instance sendIntelliStatusBarsAction: INTELLISB_ADD_IMAGE forImage: imageName];
}


-(void)NewSpring_removeStatusBarImageNamed: (NSString*) imageName
{
	 if (instance == nil)
	 {
		 [IntelliStatusIconsManager sharedInstance];
	 }
	[instance doRealRemoveStatusBarImageName: imageName];
	// broadcast
	[instance sendIntelliStatusBarsAction: INTELLISB_REMOVE_IMAGE forImage: imageName];
}

-(CGRect) UIStatusBarBatteryItemView_frame
{
	CGRect frame = [self UIStatusBarBatteryItemView_frame];
	CGRect rect = [[UIWindow keyWindow] frame];
	int windowWidth = rect.size.width;
	if ([UIApp interfaceOrientation] == 4 ||[UIApp interfaceOrientation] == 3)
	{
		windowWidth = rect.size.height;
	}

	if (windowWidth == 0)
	{
		// might have issue in landscape!
		CGRect screen = [UIHardware fullScreenApplicationContentRect];
		windowWidth = screen.size.width;
		if ([UIApp interfaceOrientation] == 4 ||[UIApp interfaceOrientation] == 3)
		{
			windowWidth = screen.size.height;
		}
	}
	// this might be an issue when removing
	if (globalWidth != 0)
	{
		int startX = windowWidth - globalWidth - 3;
		if (frame.size.width != globalWidth || frame.origin.x != startX)
		{
			frame.size.width = globalWidth;
			frame.origin.x = startX;
			[self setFrame: frame];
		}
	}
	return frame;
}

-(void) UIStatusBarBatteryItemView_setVisible:(BOOL)visible frame:(struct CGRect)frame duration:(double)arg3
{
	if (visible)
	{
		#ifdef DEBUME
		NSLog(@" Setting visible %@", self);
		#endif
		 if (instance == nil)
		 {
			 [IntelliStatusIconsManager sharedInstance];
		 }
	}
	if (visible == true)
	{
		// assuming not using tag -- could check all subviews just in case
		if ([self tag] != 121512)
		{
			[self setTag: 121512];
			id newView = [instance getIntelliStatusIconsView];
			[self addSubview: newView];
			// this will reset the frame
		}
		frame = [(UIView*)self frame];
		//NSLog(@"Setting frame x to %d width %d", (int)frame.origin.x, (int)frame.size.width);
	}
	[self UIStatusBarBatteryItemView_setVisible:(BOOL)visible frame:(struct CGRect)frame duration:(double)arg3];

}

@end



static void changesCallBack( SCDynamicStoreRef store, CFArrayRef changedKeys, void *info )
{
	#ifdef DEBUME
	NSLog(@"GOT CALLBACK FROM DYNAMIC SOTRE*************************");
	#endif
	[instance reloadImages];

}

void initializeListener()
{

	storeRef = SCDynamicStoreCreate(kCFAllocatorDefault, (CFStringRef)@"LibStatusBar", changesCallBack, NULL);
	if (storeRef != nil)
	{
		CFStringRef key = SCDynamicStoreKeyCreateNetworkGlobalEntity(NULL, kSCDynamicStoreDomainState, kSCEntNetIPv4);
		CFStringRef keyDNS = SCDynamicStoreKeyCreateNetworkGlobalEntity(NULL, kSCDynamicStoreDomainState, kSCEntNetDNS);

		SCDynamicStoreSetNotificationKeys(storeRef, (CFArrayRef)[NSArray arrayWithObjects: INTELLI_DYNAMIC_DICT,nil], NULL);
		NSLog(@" Initialized listener for icon updates");
		CFRunLoopSourceRef storeRLSource = SCDynamicStoreCreateRunLoopSource(NULL, storeRef, 0);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), storeRLSource, kCFRunLoopCommonModes);
		CFRelease(storeRLSource);
	}



}

void StatusInit()
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	NSLog(@"Initializing LibStatusBarIcons v"VERSION" (Note Devs - still in dev!)");

	[NSClassFromString(@"UIStatusBarBatteryItemView") insertHook: @selector(frame) withMethod: @selector(UIStatusBarBatteryItemView_frame) error:nil];
	[NSClassFromString(@"UIStatusBarBatteryItemView") insertHook: @selector(setVisible:frame:duration:) withMethod: @selector(UIStatusBarBatteryItemView_setVisible:frame:duration:) error:nil];
	[NSClassFromString(@"UIStatusBar") insertHook: @selector(_setStyle:) withMethod: @selector(UIStatusBar_setStyle:) error:nil];
	[NSClassFromString(@"UIApplication") insertHook: @selector(addStatusBarImageNamed:) withMethod: @selector(NewSpring_addStatusBarImageNamed:) error:nil];
	[NSClassFromString(@"UIApplication") insertHook: @selector(removeStatusBarImageNamed:) withMethod: @selector(NewSpring_removeStatusBarImageNamed:) error:nil];

	initializeListener();
	[[IntelliStatusIconsManager sharedInstance] reloadImages];
	[pool release];
}
