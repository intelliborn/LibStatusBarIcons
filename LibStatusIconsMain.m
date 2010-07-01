/*

LibStatusIconsMain.m ...
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


// This program lets you publish add/remove requests from the commandline to LibStatusBarIcons
// Email github@intelliborn.com or contact psuskeels with any change requests.

#include "LibStatusIconsView.h"


void printUsage()
{
	printf(" LibStatusIcons usage: <add|remove> <image name>\n");
	exit(-1);
}
#import <SystemConfiguration/SystemConfiguration.h>
SCDynamicStoreRef storeRef;
int main(int argsc, char** argv)
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	if (argsc == 3)
	{
	   	struct IntelliStatusIconsViewComm statusBarComm;

		char* imageNameStr = argv[2];
		char* actionStr = argv[1];
		int action = -1;

		if (strncmp(actionStr, "add", 3) == 0)
		{
			action = INTELLISB_ADD_IMAGE;
		}
		else if (strncmp(actionStr, "remove", 6) == 0)
		{
			action = INTELLISB_REMOVE_IMAGE;
		}
		else
		{
			printUsage();
		}

		NSString* imageName = [NSString stringWithCString: imageNameStr encoding: NSASCIIStringEncoding];
		storeRef = SCDynamicStoreCreate(kCFAllocatorDefault, (CFStringRef)@"LibStatusPoster", NULL, NULL);
		if (storeRef != nil)
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
			NSLog(@"Successfully published %@\n", imageName);
		}
	}
	else
	{
		printUsage();
	}
	[pool release];
}



