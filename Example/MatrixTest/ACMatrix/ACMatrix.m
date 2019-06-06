// Copyright © 2019 Wenzhi WU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. All advertising materials mentioning features or use of this software
//    must display the following acknowledgement:
//    This product includes software developed by the University of
//    California, Berkeley and its contributors.
// 4. Neither the name of the University nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.


#import "ACMatrix.h"
#import <Accelerate/Accelerate.h>

@interface ACMatrix ()


/**
 data
 
 Discussion:
    Matrix data for value storage
 */
@property (nonatomic, assign)   double  *data;


@end

@implementation ACMatrix

- (instancetype)init
{
    NSLog(@"Use \"initWithRows:columns:values:\" or \"columns:rows:values:\" to create ACMatrix object");
    return [self initWithRows:0 columns:0];
}

- (instancetype)initWithRows:(NSInteger)row columns:(NSInteger)column
{
    NSAssert(row > 0 && column > 0, @"row and coloum should both greater than 0");
    self = [super init];
    if (!self)  return nil;
    
    _columns = column;
    _rows = row;
    
    _data = (double *)malloc(sizeof(double) * row * column);
    memset((void *)_data, 0.0, sizeof(double) * row * column);
    
    return self;
}

- (instancetype)initWithRows:(NSInteger)row columns:(NSInteger)column values:(double)value, ...
{
    ACMatrix *matrix = [self initWithRows:row columns:column];
    if (!matrix) return nil;
    
    va_list list;
    va_start(list, value);
    matrix.data[0] = value;
    for (int i = 1; i < column * row; i++)
    {
        matrix.data[i] = va_arg(list, double);
    }
    
    va_end(list);
    return matrix;
}

+ (instancetype)rows:(NSInteger)row columns:(NSInteger)column
{
    return [[[self class] alloc] initWithRows:row columns:column];
}

+ (instancetype)rows:(NSInteger)row columns:(NSInteger)column values:(double)value, ...
{
    ACMatrix *matrix = [[[self class] alloc] initWithRows:row columns:column];
    if (!matrix) return nil;
    
    va_list list;
    va_start(list, value);
    matrix.data[0] = value;
    for (int i = 1; i < column * row; i++)
    {
        matrix.data[i] = va_arg(list, double);
    }
    
    va_end(list);
    return matrix;
}

+ (instancetype)identityWithDimension:(NSInteger)dimension
{
    ACMatrix *matrix = [[[self class] alloc] initWithRows:dimension columns:dimension];
    if (!matrix) return nil;
    return [matrix identity];
}

- (void)dealloc
{
    free(_data);
}

- (ACMatrix *)identity
{
    if (_columns != _rows)
    {
        NSLog(@"matrix is not a square matrix");
        return self;
    }
    
    for(int r = 0; r < _rows; r++)
    {
        for(int c = 0; c < _columns; c++)
        {
            _data[c + r * _columns] = r == c ? 1.0 : 0.0;
        }
    }
    
    return self;
}

- (ACMatrix *)copy
{
    ACMatrix *matrix = [[ACMatrix alloc] initWithRows:_rows columns:_columns];
    memcpy(matrix.data, _data, _rows * _columns * sizeof(double));
    return matrix;
}

- (double (^)(NSInteger, NSInteger))m
{
    return ^double(NSInteger rowIndex, NSInteger columnIndex) {
        return self.data[columnIndex + rowIndex * self.columns];
    };
}

- (ACMatrix *(^)(NSInteger, NSInteger, double))set
{
    return ^id(NSInteger rowIndex, NSInteger columnIndex, double value) {
        self.data[columnIndex + rowIndex * self.columns] = value;
        return self;
    };
}

- (ACMatrix *(^)(double, ...))update
{
    return ^id(double value, ...) {
        va_list list;
        va_start(list, value);
        self.data[0] = value;
        for(int i = 1; i < self.rows * self.columns; i++)
        {
            self.data[i] = va_arg(list, double);
        }
        
        va_end(list);
        return self;
    };
}

- (ACMatrix *)transpose
{
    ACMatrix *result = [ACMatrix rows:_columns columns:_rows];
    vDSP_mtransD(_data, 1, result.data, 1, _columns, _rows);
    return result;
}

- (ACMatrix *)inverse
{
    ACMatrix *temp = [self copy];
    
    __CLPK_integer error = 0;
    __CLPK_integer M = (__CLPK_integer)temp.rows;
    __CLPK_integer N = (__CLPK_integer)temp.columns;
    __CLPK_integer LDA = MAX(M, N);
    
    __CLPK_integer *pivot = (int *)malloc(MIN(M, N) * sizeof(__CLPK_integer));
    __CLPK_doublereal *workspace = (double *)malloc(MAX(M, N) * sizeof(__CLPK_doublereal));
    
    dgetrf_(&M, &N, temp.data, &LDA, pivot, &error);
    if (error)
    {
        NSLog(@"LU factorisation failed");
        free(pivot);
        free(workspace);
        return nil;
    }
    
    dgetri_(&N, temp.data, &N, pivot, workspace, &N, &error);
    if (error)
    {
        NSLog(@"Inversion failed");
        free(pivot);
        free(workspace);
        return nil;
    }
    
    free(pivot);
    free(workspace);
    
    ACMatrix *result = [[ACMatrix alloc] initWithRows:temp.columns columns:temp.rows];
    memcpy(result.data, temp.data, temp.rows * temp.columns * sizeof(double));
    return result;
}

- (ACMatrix *(^)(ACMatrix *))plus
{
    return ^id(ACMatrix *input) {
        NSAssert(self.columns == input.columns && self.rows == input.rows, @"plus failed: matrices should be in same dimension");
        ACMatrix *result = [ACMatrix rows:self.rows columns:self.columns];
        vDSP_vaddD(self.data, 1, input.data, 1, result.data, 1, self.rows * self.columns);
        return result;
    };
}

- (ACMatrix *(^)(ACMatrix *))minus
{
    return ^id(ACMatrix *input) {
        NSAssert(self.columns == input.columns && self.rows == input.rows, @"minus failed: matrices should be in same dimension");
        ACMatrix *result = [ACMatrix rows:self.rows columns:self.columns];
        double negetive = -1.0;
        vDSP_vsmaD(input.data, 1, &negetive, self.data, 1, result.data, 1, self.rows * self.columns);
        return result;
    };
}

- (ACMatrix *(^)(double))scaleBy
{
    return ^id(double scalar) {
        ACMatrix *result = [ACMatrix rows:self.rows columns:self.columns];
        vDSP_vsmulD(self.data, 1, &scalar, result.data, 1, self.rows * self.columns);
        return result;
    };
}

- (ACMatrix *(^)(ACMatrix *))multiplyBy
{
    return ^id(ACMatrix *input) {
        NSAssert(self.columns == input.rows, @"multiplyBy error: left matrix columns ≠ right matrix rows: %lu ≠ %lu", (unsigned long)self.columns, (unsigned long)input.rows);
        
        ACMatrix *result = [ACMatrix rows:self.rows columns:input.columns];
        vDSP_mmulD(self.data, 1, input.data, 1, result.data, 1, self.rows, input.columns, self.columns);
        return result;
    };
}

- (void (^)(ACMatrixValueEnumerator))enumerator
{
    return ^void(ACMatrixValueEnumerator output) {
        NSAssert(output, @"enumerator block should not be nil");
        for (int i = 0; i < self.rows; i++)
        {
            for (int j = 0; j < self.columns; j++)
            {
                output(i, j, self.m(i, j));
            }
        }
    };
}

- (NSString *)description
{
    return self.print(NO);
}

- (NSString *(^)(BOOL))print
{
    return ^NSString *(BOOL accurate) {
        NSString *log = self.name ? [NSString stringWithFormat:@"\n\t%@:\n\t", self.name] : @"\n\t";
        for (int i = 0; i < self.rows; i++)
        {
            NSString *row = @"";
            for (int j = 0; j < self.columns; j++)
            {
                if ([row length])
                {
                    row = accurate ? [row stringByAppendingString:[NSString stringWithFormat:@"\t%.6f", self.m(i, j)]]
                    : [row stringByAppendingString:[NSString stringWithFormat:@"\t%.2f", self.m(i, j)]];
                }
                else
                {
                    row = accurate ? [row stringByAppendingString:[NSString stringWithFormat:@"%.6f", self.m(i, j)]] : [row stringByAppendingString:[NSString stringWithFormat:@"%.2f", self.m(i, j)]];
                }
            }
            
            if (i == 0)
            {
                log = [log stringByAppendingString:[NSString stringWithFormat:@"[%@", row]];
            }
            else
            {
                log = [log stringByAppendingString:[NSString stringWithFormat:@"\n\t%@", row]];
            }
            
            if (i == self.rows - 1)
            {
                log = [log stringByAppendingString:@"]"];
            }
        }
        
        return log;
    };
}


#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    ACMatrix *copy = [[[self class] allocWithZone:zone] initWithRows:_rows columns:_columns];
    memcpy(copy.data, _data, _rows * _columns * sizeof(double));
    return copy;
}

@end
