//
//  IVConstants.h
//  iVisit 3D
//
//  Created by Bob on 03/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

typedef NS_ENUM (NSInteger, FaceTo) {
    FaceUnchange = -1,
    FaceToRight = 0,
    FaceToLeft,
    FaceToTop,
    FaceToBottom,
    FaceToFront,
    FaceToBack,
    FaceToCount
};

typedef NS_ENUM (NSUInteger, TRANSIT_TYPE) {
	TRANSIT_TYPE_OPEN = 0,
	TRANSIT_TYPE_CLOSE
};

#define TRANSIT_ZOOM_DURATION 0.3
#define TRANSIT_FADE_DURATION 0.5

typedef NS_ENUM (NSUInteger, IVDocType) {
    IVDocTypeUnkown = 0,
	IVDocTypePanoramaV4,
    IVDocTypePanoramaV5,
    IVDocTypePanorama360,
	IVDocTypeVRObject,
};

typedef NS_ENUM (NSUInteger, IVPanoramaAnnotationType) {
    IVPanoramaAnnotationTypeUnkown = 0,
    IVPanoramaAnnotationTypeCaptionImage,
    IVPanoramaAnnotationTypeCaptionVideo,
    IVPanoramaAnnotationTypeImage,
    IVPanoramaAnnotationTypeVideo,
    IVPanoramaAnnotationTypeOnlineWebsite,
    IVPanoramaAnnotationTypeCustom,
};

typedef NS_ENUM (NSUInteger, IVPanoramaNodeFontType) {
    IVPanoramaNodeFontTypeNormal = 0,
    IVPanoramaNodeFontTypeItalic,
    IVPanoramaNodeFontTypeBold,
    IVPanoramaNodeFontTypeBoldItalic
};

typedef NS_ENUM (NSUInteger, IVPanoramaNodeTitlePosition) {
    IVPanoramaNodeTitlePositionRight = 0,
    IVPanoramaNodeTitlePositionLeft,
    IVPanoramaNodeTitlePositionTop,
    IVPanoramaNodeTitlePositionBottom,
    IVPanoramaNodeTitlePositionUnknown
};

typedef NS_ENUM (NSUInteger, IVPanoramaLogoPosition) {
    IVPanoramaLogoPositionTopLeft = 0,
    IVPanoramaLogoPositionTopRight,
    IVPanoramaLogoPositionBottomLeft,
    IVPanoramaLogoPositionBottomRight
};
    
typedef struct {
    float x,y,z;
} Coordinate3D;

#define kSampleURL @"http://samples.ivisit360.com/ios/contenu.php"

#define kNodeSelectionDidChangeNotification @"kNodeSelectionDidChangeNotification"
#define kDirectoryDidFinishChangesNotification @"kDirectoryDidFinishChangesNotification"

#define kIsNotFirstTimeLaunch @"kIsNotFirstTimeLaunch"
#define kShowNodesListView @"kShowNodesListView"

#define kDocumentListInRecentOrder @"kDocumentListInRecentOrder"

#define PAGE_PROPORTION 1
#define WELCOME_PAGE_MARGIN_INSET_SCALE_RATIO 0.06f
#define WELCOME_PAGE_BORDER_INSET ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?6:4)
#define NODE_PAGE_MARGIN_INSET 6

#define BUTTON_HIGHLIGHT_COLOR [UIColor colorWithRed:0.059 green:0.482 blue:0.996 alpha:1.0]
//[UIColor colorWithRed:0.9608 green:0.3176 blue:0.0353 alpha:1.0]

#define rad2deg(x)		((x)*57.295779513082325)
#define deg2rad(x)		((x)* 0.017453292519943)

#define M_PI_D			6.283185307179586

#ifdef CGFLOAT_IS_DOUBLE
    #define CGCeil(X) ceil(X)
    #define CGFloor(X) floor(X)
    #define CGNearbyint(X) nearbyint(X)
    #define CGAbs(X) fabs(X)
#else
    #define CGCeil(X) ceilf(X)
    #define CGFloor(X) floorf(X)
    #define CGNearbyint(X) nearbyintf(X)
    #define CGAbs(X) fabsf(X)
#endif

#define DefaultsGet(type, key) ([[NSUserDefaults standardUserDefaults] type##ForKey:key])
#define DefaultsSet(Type, key, value) do {\
[[NSUserDefaults standardUserDefaults] set##Type:value forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];\
} while (0)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
