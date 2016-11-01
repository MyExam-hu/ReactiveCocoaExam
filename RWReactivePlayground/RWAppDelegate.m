//
//  RWAppDelegate.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWAppDelegate.h"
#import "MainViewController.h"

@implementation RWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // style the navigation bar
  UIColor* navColor = [UIColor colorWithRed:0.175f green:0.458f blue:0.831f alpha:1.0f];
  [[UINavigationBar appearance] setBarTintColor:navColor];
  [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
  [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
  
  // make the status bar white
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
  
    self.window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    MainViewController *vc =[[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    
    UINavigationController * nav=[[UINavigationController alloc] initWithRootViewController:vc];
    nav.navigationBarHidden=YES;
    self.rootViewController=vc;
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
  
  return YES;
}

@end
