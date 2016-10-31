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

//@property (nonatomic) BOOL passwordIsValid;
//@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
//  [self updateUIState];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
//  [self.usernameTextField addTarget:self action:@selector(usernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
//  [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  
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
    
    //合并信号
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal] reduce:^id(NSNumber*usernameValid, NSNumber *passwordValid){
                          return @([usernameValid boolValue]&&[passwordValid boolValue]);
                      }];
    [signUpActiveSignal subscribeNext:^(NSNumber*signupActive){
        self.signInButton.enabled =[signupActive boolValue];
    }];
    
    //监听button事件
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x){
           self.signInButton.enabled =NO;
           self.signInFailureText.hidden =YES;
       }]
      flattenMap:^id(id x){
          return [self signInSignal];
      }]
     subscribeNext:^(NSNumber *signedIn){
         self.signInButton.enabled =YES;
         BOOL success =[signedIn boolValue];
         self.signInFailureText.hidden = success;
         if(success){
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
     }];
    
    // 1.遍历数组
    NSArray *numbers = @[@1,@2,@3,@4];
    [numbers.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"x=%@",x);
    }];
    
    NSDictionary *dict = @{@"name":@"xmg",@"age":@18};
    [dict.rac_sequence.signal subscribeNext:^(RACTuple *x) {
        // 解包元组，会把元组的值，按顺序给参数里面的变量赋值
        RACTupleUnpack(NSString *key,NSString *value) = x;
        // 相当于以下写法
        //NSString *key = x[0];
        //NSString *value = x[1];
        NSLog(@"key=%@ value=%@",key,value);
    }];
    
//    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        NSLog(@"发送请求");
//        return nil;
//    }];
//    // 2.订阅信号
//    [signal subscribeNext:^(id x) {
//        NSLog(@"接收数据");
//    }];
//    // 2.订阅信号
//    [signal subscribeNext:^(id x) {
//        NSLog(@"接收数据");
//    }];
//    运行结果，会执行两遍发送请求，也就是每次订阅都会发送一次请求
    
    // RACMulticastConnection:解决重复请求问题
    // 1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"发送请求");
        [subscriber sendNext:@1];
        return nil;
    }];
    // 2.创建连接
    RACMulticastConnection *connect = [signal publish];
    // 3.订阅信号，
    // 注意：订阅信号，也不能激活信号，只是保存订阅者到数组，必须通过连接,当调用连接，就会一次性调用所有订阅者的sendNext:
    [connect.signal subscribeNext:^(id x) {
        NSLog(@"订阅者一信号");
    }];
    [connect.signal subscribeNext:^(id x) {
        NSLog(@"订阅者二信号");
    }];
    // 4.连接,激活信号
    [connect connect];
    
    //把监听到的通知转换信号
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(id x) {
        NSLog(@"键盘弹出");
    }];
    
    // 2.KVO
    // 把监听view的center属性改变转换成信号，只要值改变就会发送信号
    // observer:可以传入nil
    [[self.view rac_valuesAndChangesForKeyPath:@"center" options:NSKeyValueObservingOptionNew observer:nil] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    // 6.处理多个请求，都返回结果的时候，统一做处理.
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 发送请求1
        [subscriber sendNext:@"发送请求1"];
        return nil;
    }];
    
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 发送请求2
        [subscriber sendNext:@"发送请求2"];
        return nil;
    }];
    
    // 使用注意：几个信号，参数一的方法就几个参数，每个参数对应信号发出的数据。
    [self rac_liftSelector:@selector(updateUIWithR1:r2:) withSignalsFromArray:@[request1,request2]];

}

// 更新UI
- (void)updateUIWithR1:(id)data r2:(id)data1{
    NSLog(@"更新UI%@  %@",data,data1);
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

//- (IBAction)signInButtonTouched:(id)sender {
//  // disable all UI controls
//  self.signInButton.enabled = NO;
//  self.signInFailureText.hidden = YES;
//  
//  // sign in
//  [self.signInService signInWithUsername:self.usernameTextField.text
//                            password:self.passwordTextField.text
//                            complete:^(BOOL success) {
//                              self.signInButton.enabled = YES;
//                              self.signInFailureText.hidden = success;
//                              if (success) {
//                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//                              }
//                            }];
//}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id subscriber){
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success){
             [subscriber sendNext:@(success)];
             [subscriber sendCompleted];
         }];
        return nil;
    }];
}

// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid
//- (void)updateUIState {
//  self.usernameTextField.backgroundColor = self.usernameIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.passwordTextField.backgroundColor = self.passwordIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.signInButton.enabled = self.usernameIsValid && self.passwordIsValid;
//}

//- (void)usernameTextFieldChanged {
//  self.usernameIsValid = [self isValidUsername:self.usernameTextField.text];
//  [self updateUIState];
//}

//- (void)passwordTextFieldChanged {
//  self.passwordIsValid = [self isValidPassword:self.passwordTextField.text];
//  [self updateUIState];
//}

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
