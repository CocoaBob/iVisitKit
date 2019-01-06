//
//  IVBaseDataModel.h
//  iVisit 3D
//
//  Created by Bob on 05/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IVBaseDataModel : NSObject <NSCoding>

- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
- (id)valueForUndefinedKey:(NSString *)key;

- (NSUInteger)count;

- (id)objectForKey:(id)aKey;
- (id)objectForKeyedSubscript:(id <NSCopying>)key;

- (NSEnumerator *)keyEnumerator;

- (void)setObject:(id)anObject forKey:(id < NSCopying >)aKey;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

- (void)removeObjectForKey:(id)aKey;

@end
