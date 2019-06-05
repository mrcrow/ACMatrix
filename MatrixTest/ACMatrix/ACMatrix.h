//  Note: This license has also been called the "New BSD License" or "Modified BSD License". See also the 2-clause BSD
//  License.
//
//  Copyright © 2019 Wenzhi WU. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
//  following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
//  disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
//  following disclaimer in the documentation and/or other materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
//  products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
//  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Foundation/Foundation.h>


/**
 AC_M()

 Discussion:
    Shortcut declaration for empty matrix
 
 @param __row__ - number of rows in matrix
 @param __col__ - number of columns in matrix
 */
#define AC_M(__row__, __col__)  [ACMatrix rows:__row__ columns:__col__]


/**
 AC_MI

 Discussion:
    Shortcut declaration for identity matrix for specific demension
 
 @param __dim__ - matrix dimension
 */
#define AC_MI(__dim__)  [ACMatrix identityWithDimension:__dim__]


/**
 ACMatrixValueEnumerator
 
 Discussion:
 Matrix enumerator
 
 @param row - row index started with '0'
 @param column - column index started with '0'
 @param value - value in [row, column]
 */
typedef void (^ACMatrixValueEnumerator)(NSInteger row, NSInteger column, double value);


@interface ACMatrix : NSObject <NSCopying>


/**
 name
 
 Discussion:
    Name that determine matrix usage for debug output
 */
@property (nonatomic, copy) NSString *name;


/**
 rows
 
 Discussion:
    Determine number of rows in matrix
 */
@property (nonatomic, assign, readonly) NSInteger   rows;


/**
 columns
 
 Discussion:
    Deternmine number of columns in matrix
 */
@property (nonatomic, assign, readonly) NSInteger   columns;


/**
 initWithRows:columns:values:
 
 Discussion:
    Designate initializer for creating ACMatrix object
 
 @param row - number of rows
 @param column - number of columns
 @param value - matrix data
 */
- (instancetype)initWithRows:(NSInteger)row columns:(NSInteger)column values:(double)value, ...;


/**
 rows:columns:values:

 Discussion:
    Designate initializer for creating ACMatrix object
 
 @param row - number of rows
 @param column - number of columns
 @param value - matrix data
 */
+ (instancetype)rows:(NSInteger)row columns:(NSInteger)column values:(double)value, ...;


/**
 rows:columns:
 
 Discussion:
    Disignete initializer for creating empty ACMatrix object

 @param row - number of rows
 @param column - number of columns
 */
+ (instancetype)rows:(NSInteger)row columns:(NSInteger)column;


/**
 identityWithDimension:

 Discussion:
    Designate initializer for creating identify matrix of ACMatrix
 
 @param dimension - matrix dimension
 */
+ (instancetype)identityWithDimension:(NSInteger)dimension;


/**
 identity

 Discussion:
    Update matrix data to an identity matrix
 */
- (ACMatrix *)identity;


/**
 copy

 Discussion:
    Make a copy of matrix
 */
- (ACMatrix *)copy;


/**
 m
 
 Discussion:
    Get matrix value for position with row and column index,
    i.e., self.m(1, 1) to get value for position [1, 1]
 */
- (double (^)(NSInteger row, NSInteger column))m;


/**
 set
 
 Discussion:
    Set matrix value for position with row and column index,
    i.e., self.set(1, 1, 0.5) to set value for position [1, 1] with value 0.5
 */
- (ACMatrix *(^)(NSInteger row, NSInteger column, double value))set;


/**
 update
 
 Discussion:
    Update matrix data with sequenced value
 */
- (ACMatrix *(^)(double value, ...))update;


/**
 transpose

 Discussion:
    Get transpose matrix for current matrix,
    B = A^T
 */
- (ACMatrix *)transpose;


/**
 inverse

 Discussion:
    Get inverse matrix for current matrix,
    B = A^-1
 */
- (ACMatrix *)inverse;


/**
 plus
 
 Discussion:
    Add matrix with same dimension,
    C = A + B
 */
- (ACMatrix *(^)(ACMatrix *))plus;


/**
 minus
 
 Discussion:
    Minus matrix with same dimension,
    C = A - B
 */
- (ACMatrix *(^)(ACMatrix *))minus;


/**
 scaleBy
 
 Discussion:
    Scale matrix with scalar input,
    B = A * s
 */
- (ACMatrix *(^)(double))scaleBy;


/**
 multiplyBy
 
 Discussion:
    Dot multiply with matrix input,
    C = A • B
 */
- (ACMatrix *(^)(ACMatrix *))multiplyBy;


/**
 enumerator
 
 Discussion:
 Enumerator matrix value from m[0, 0] to m[row-1, column-1], from left to right, top to bottom
 */
- (void (^)(ACMatrixValueEnumerator))enumerator;


/**
 log
 
 Discussion:
    Print matrix info, YES for 6 digits accuracy log, otherwise 2 digits accuracy log
 */
- (NSString *(^)(BOOL))print;


@end
