//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import "ReactiveCocoa-umbrella.h"

@interface RWViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (nonatomic) BOOL passwordIsValid;
@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self updateUIState];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
  [self.usernameTextField addTarget:self action:@selector(usernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
  self.usernameTextField.delegate=self;
    
//    [[self.usernameTextField.rac_textSignal filter:^BOOL(NSString *value){
//          return value.length > 3;
//      }]
//     subscribeNext:^(id x){
//         NSLog(@"%@", x);
//     }];
    
//    RACSignal *usernameSourceSignal = self.usernameTextField.rac_textSignal;
//    RACSignal *filteredUsername =[usernameSourceSignal filter:^BOOL(id value){
//                                      NSString*text = value;
//                                      return text.length > 3;
//                                  }];
//    [filteredUsername subscribeNext:^(id x){
//        NSLog(@"%@", x);
//    }];
    
    [[[self.usernameTextField.rac_textSignal map:^id(NSString *text){
           return @(text.length);
       }]
      filter:^BOOL(NSNumber *length){
          return [length integerValue] > 3;
      }]
     subscribeNext:^(id x){
         NSLog(@"%@", x);
     }];
    
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
         return @([self isValidUsername:text]);
     }];
    RAC(self.usernameTextField, backgroundColor) = [validUsernameSignal map:^id(NSNumber *passwordValid){
        return[passwordValid boolValue] ? [UIColor clearColor]:[UIColor yellowColor];
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
         return @([self isValidPassword:text]);
     }];
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid){
         return[passwordValid boolValue] ? [UIColor clearColor]:[UIColor yellowColor];
     }];
    
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

- (IBAction)signInButtonTouched:(id)sender {
  // disable all UI controls
  self.signInButton.enabled = NO;
  self.signInFailureText.hidden = YES;
  
  // sign in
  [self.signInService signInWithUsername:self.usernameTextField.text
                            password:self.passwordTextField.text
                            complete:^(BOOL success) {
                              self.signInButton.enabled = YES;
                              self.signInFailureText.hidden = success;
                              if (success) {
                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
                              }
                            }];
}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid
- (void)updateUIState {
//  self.usernameTextField.backgroundColor = self.usernameIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.passwordTextField.backgroundColor = self.passwordIsValid ? [UIColor clearColor] : [UIColor yellowColor];
  self.signInButton.enabled = self.usernameIsValid && self.passwordIsValid;
}

- (void)usernameTextFieldChanged {
  self.usernameIsValid = [self isValidUsername:self.usernameTextField.text];
  [self updateUIState];
}

- (void)passwordTextFieldChanged {
  self.passwordIsValid = [self isValidPassword:self.passwordTextField.text];
  [self updateUIState];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (![string isEqualToString:@""]) {
        int ASCIICode=[string characterAtIndex:0];
        NSLog(@"%d",ASCIICode);
        //A->65 Z->90 a->97 z->122 0->48 9->57 .->46
        if (!((ASCIICode>=65 && ASCIICode<=90) || (ASCIICode>=97 && ASCIICode<=122))) {
            return NO;
        }
    }
    return YES;
}


@end
