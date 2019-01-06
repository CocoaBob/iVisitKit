//
//  TBXML+CBAdditions.m
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

#import "TBXML+CBAdditions.h"

@implementation TBXML(CBAdditions)

+ (void)handleElement:(TBXMLElement *)element handlers:(id)handlerOrHandlers context:(void *)context stop:(BOOL *)stop {
    if (handlerOrHandlers && element) {
        if ([handlerOrHandlers isKindOfClass:NSClassFromString(@"NSBlock")]) {
            ((TBXMLElementHandler)handlerOrHandlers)(element, context, stop);
        }
        else {
            // Handle current element
            TBXMLElementHandler elementHandler = handlerOrHandlers[kHandler];
            if (elementHandler) elementHandler(element, context, stop);

            // Handle sub elements
            TBXMLElement *childElement = element->firstChild;
            while (childElement) {
                BOOL stopLoop = NO;
                NSString *elementName = [TBXML elementName:childElement];
                elementName = [elementName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                id childHandlerOrHandlers = handlerOrHandlers[elementName];
                if (!childHandlerOrHandlers) childHandlerOrHandlers = handlerOrHandlers[kAnyNode];
                if (childHandlerOrHandlers) [TBXML handleElement:childElement handlers:childHandlerOrHandlers context:context stop:&stopLoop];
                childElement = stopLoop?nil:childElement->nextSibling;
            }
        }
    }
}

+ (void)exportAttributes:(TBXMLAttribute *)attribute toDictionary:(NSMutableDictionary **)dictionary {
    while (attribute) {
        [(*dictionary) setObject:[TBXML attributeValue:attribute] forKey:[TBXML attributeName:attribute]];
        attribute = attribute->next;
    }
}

+ (void)exportElements:(TBXMLElement *)element toDictionary:(NSMutableDictionary **)dictionary {
    while (element) {
        [(*dictionary) setObject:[TBXML textForElement:element] forKey:[TBXML elementName:element]];
        element = element->nextSibling;
    }
}

@end
