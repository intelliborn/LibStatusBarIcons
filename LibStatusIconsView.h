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

#include <UIKit/UIKit.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>



#define INTELLISB_ADD_IMAGE 1024
#define INTELLISB_REMOVE_IMAGE 1025

#define INTELLI_DYNAMIC_DICT @"State:/LibStatusBar"

#define COMM_PORT 20601
#define SB_COMM_PORT 20602

struct IntelliStatusIconsViewComm
{
	int action;
	char imageName[100];
};

@interface IntelliStatusIconsView : UIView
{
    NSMutableArray *imageNames;
    NSMutableDictionary *imagesViewsDict;
    bool needsReLayout;
    id intelliStatusBarlocalPort;
}

- (id)init;
- (void)copyNames:(id)fp8;
- (void)removeFromSuperview;
- (void)doAddIconImageName:(id)fp8;
- (void)doRemoveIconImageName:(id)fp8;
- (void)layoutSubviews;

@end

@interface IntelliStatusIconsManager : NSObject
{
    NSMutableArray *imageNamesArray;
    NSMutableDictionary *imageNamesDict;
    NSMutableArray *intelliViewsArray;
    id intelliStatusBarlocalPort;
    id shimRemotePort;
    int sock;
    int sockForSB;
    struct sockaddr_in serverAddr;
}

+ (id)sharedInstance;
- (id)init;
- (id)getIntelliStatusIconsView;
- (void)removeIntelliStatusIconsView:(id)fp8;
- (void)redoForStyleChange;
- (void)doRealAddStatusBarImageName:(id)fp8;
- (void)doRealRemoveStatusBarImageName:(id)fp8;
- (void)addRemoveImages:(id)fp8;
- (void)sendIntelliStatusBarsAction:(int)fp8 forImage:(id)fp12;
- (void)reloadImages;

@end
/*
@interface  (IntelliStatusBarIcons)
- (void)UIStatusBar_setStyle:(int)fp8;
- (void)NewSpring_addStatusBarImageNamed:(id)fp8;
- (void)NewSpring_removeStatusBarImageNamed:(id)fp8;
- (struct CGRect)UIStatusBarBatteryItemView_frame;
- (void)UIStatusBarBatteryItemView_setVisible:(BOOL)fp8 frame:(struct CGRect)fp12 duration:(double)fp28;
@end*/
