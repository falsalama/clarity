#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LlamaBridge : NSObject

/// Load model once, reuse for generation.
- (instancetype)initWithModelPath:(NSString *)modelPath
                            error:(NSError * _Nullable * _Nullable)error;

/// Non-streaming generation (bounded).
- (NSString *)generateWithPrompt:(NSString *)prompt
                       maxTokens:(int)maxTokens
                     temperature:(float)temperature
                           error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

