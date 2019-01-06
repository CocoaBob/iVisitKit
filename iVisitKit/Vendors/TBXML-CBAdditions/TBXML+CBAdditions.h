//
//  TBXML+CBAdditions.h
//  TBXML+CBAdditions
//  Version 1.0
//
//  Created by CcooaBob on 19/09/13.
//  Copyright (c) 2013 CcooaBob. All rights reserved.
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TBXML.h"

static NSString* const kAnyNode = @"kTBXMLAnyNodeName";
static NSString* const kHandler = @"kTBXMLCurrentNodeHandler";

typedef void (^TBXMLElementHandler)(TBXMLElement *element, void *context, BOOL *stop);

@interface TBXML(CBAdditions)

+ (void)handleElement:(TBXMLElement *)element handlers:(id)handlerOrHandlers context:(void *)context stop:(BOOL *)stop;
+ (void)exportAttributes:(TBXMLAttribute *)attribute toDictionary:(NSMutableDictionary **)dictionary;
+ (void)exportElements:(TBXMLElement *)element toDictionary:(NSMutableDictionary **)dictionary;

@end