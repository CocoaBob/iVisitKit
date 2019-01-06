//
//  IVDocumentParser.h
//  iVisit 3D
//
//  Created by Bob on 04/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IVBaseDocument;

@interface IVDocumentParser : NSObject

@property (nonatomic, strong) IVBaseDocument *document;

- (IVDocumentParser *)initWithXMLData:(NSData *)xmlData;

@end
