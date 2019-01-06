//
//  IVStatusCenter.m
//  iVisit 3D
//
//  Created by Bob on 04/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVStatusCenter.h"

#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation IVStatusCenter

#pragma mark - Object Lifecycle

+ (instancetype)shared {
    static id __sharedInstance = nil;
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    return __sharedInstance;
}

+ (NSUInteger)totalMemoryAvailable {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return NSNotFound;
    } else {
        /* Stats in bytes */
        natural_t mem_used = (vm_stat.active_count +
                              vm_stat.inactive_count +
                              vm_stat.wire_count) * (natural_t)pagesize;
        natural_t mem_free = vm_stat.free_count * (natural_t)pagesize;
        natural_t mem_total = mem_used + mem_free;
        return mem_total;
    }
}

@end
