//
//  Appearance.m
//  Milestons
//
//  Created by Dalton on 5/2/15.
//  Copyright (c) 2015 Dalton. All rights reserved.
//

#import "Appearance.h"
#import "ViewController.h"

@implementation Appearance


+ (void)initializeAppearanceDefaults {
    
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:193/255.0 green:0/255.0 blue:16/255.0 alpha:1]];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:193/255.0 green:0/255.0 blue:16/255.0 alpha:1]];
    
    [[UIToolbar appearance] setBarTintColor:[UIColor whiteColor]];
    
    [[UIToolbar appearance] setTintColor:[UIColor colorWithRed:74/255.0 green:75/255.0 blue:76/255.0 alpha:1]];
    
    [[UILabel appearance] setTextColor:[UIColor colorWithRed:74/255.0 green:75/255.0 blue:76/255.0 alpha:1]];
    
    [[UINavigationBar appearance] setTranslucent:NO];
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor whiteColor],
                                                        NSForegroundColorAttributeName,
                                                        [UIFont fontWithName:@"SystemFont" size: 22.0],
                                                        NSFontAttributeName,
                                                        nil]];
    
}


@end
