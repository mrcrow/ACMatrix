//
//  ViewController.m
//  MatrixTest
//
//  Created by Wenzhi WU on 26/5/2019.
//  Copyright © 2019 Wenzhi WU. All rights reserved.
//

#import "ViewController.h"
#import "ACMatrix.h"

@interface ViewController ()
@property (nonatomic, copy) ACMatrix    *matrix;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    ACMatrix *input = [ACMatrix rows:3 columns:3 values:4.0, 7.0, 2.0,
                                                        6.0, 5.0, 1.0,
                                                        2.0, 7.0, 3.0];
    NSLog(@"%@", input);
    
    ACMatrix *result = input.plus(input.scaleBy(3));
    NSLog(@"%@", result.print(YES));
}


@end
