#import "LlamaBridge.h"
#import <Foundation/Foundation.h>

#include <llama/llama.h>
#include <vector>
#include <cmath>
#include <cstring>

static NSError *LLMakeErr(NSString *msg) {
    return [NSError errorWithDomain:@"LlamaBridge"
                               code:1
                           userInfo:@{ NSLocalizedDescriptionKey: msg ?: @"Error" }];
}

@implementation LlamaBridge {
    struct llama_model *_model;
    struct llama_context *_ctx;
    const struct llama_vocab *_vocab;
}

- (instancetype)initWithModelPath:(NSString *)modelPath
                            error:(NSError * _Nullable * _Nullable)error {
    self = [super init];
    if (!self) return nil;

    if (modelPath.length == 0) {
        if (error) *error = LLMakeErr(@"Missing model path");
        return nil;
    }

    llama_backend_init();

    struct llama_model_params mparams = llama_model_default_params();
    _model = llama_model_load_from_file(modelPath.UTF8String, mparams);
    if (!_model) {
        if (error) *error = LLMakeErr([NSString stringWithFormat:@"Failed to load model at: %@", modelPath]);
        return nil;
    }

    _vocab = llama_model_get_vocab(_model);

    struct llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx = 2048;
    cparams.n_threads = 4;

    _ctx = llama_init_from_model(_model, cparams);
    if (!_ctx) {
        llama_model_free(_model);
        _model = NULL;
        if (error) *error = LLMakeErr(@"Failed to create llama context");
        return nil;
    }

    return self;
}

- (void)dealloc {
    if (_ctx) { llama_free(_ctx); _ctx = NULL; }
    if (_model) { llama_model_free(_model); _model = NULL; }
    _vocab = NULL;
    llama_backend_free();
}

- (NSString *)generateWithPrompt:(NSString *)prompt
                       maxTokens:(int)maxTokens
                     temperature:(float)temperature
                           error:(NSError * _Nullable * _Nullable)error {

    if (!_ctx || !_model || !_vocab) {
        if (error) *error = LLMakeErr(@"Model not loaded");
        return @"";
    }
    if (prompt.length == 0) return @"";

    const char *cstr = prompt.UTF8String;
    const int n_prompt = (int)strlen(cstr);

    // rough upper bound: UTF-8 bytes + a bit
    std::vector<llama_token> tokens((size_t)n_prompt + 8);

    const int n_tok = llama_tokenize(
        _vocab,
        cstr,
        (int32_t)n_prompt,
        tokens.data(),
        (int32_t)tokens.size(),
        /* add_bos */ true,
        /* special */ true
    );

    if (n_tok <= 0) {
        if (error) *error = LLMakeErr(@"Tokenisation failed");
        return @"";
    }
    tokens.resize((size_t)n_tok);

    // Evaluate prompt
    llama_batch batch = llama_batch_init((int32_t)tokens.size(), 0, 1);

    for (int i = 0; i < (int)tokens.size(); i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = (int32_t)i;
        batch.n_seq_id[i] = 1;
        if (batch.seq_id && batch.seq_id[i]) {
            batch.seq_id[i][0] = 0;
        }
        batch.logits[i] = (i == (int)tokens.size() - 1) ? 1 : 0;
    }
    batch.n_tokens = (int32_t)tokens.size();

    if (llama_decode(_ctx, batch) != 0) {
        llama_batch_free(batch);
        if (error) *error = LLMakeErr(@"Decode failed on prompt");
        return @"";
    }
    llama_batch_free(batch);

    NSMutableString *out = [NSMutableString string];
    int32_t curPos = (int32_t)tokens.size();

    for (int i = 0; i < maxTokens; i++) {
        const float *logits = llama_get_logits_ith(_ctx, 0);
        if (!logits) {
            if (error) *error = LLMakeErr(@"Failed to read logits");
            break;
        }

        const int32_t vocabSize = llama_vocab_n_tokens(_vocab);
        llama_token next = 0;

        if (temperature <= 0.01f) {
            // argmax
            float best = logits[0];
            for (int32_t t = 1; t < vocabSize; t++) {
                if (logits[t] > best) { best = logits[t]; next = (llama_token)t; }
            }
        } else {
            // simple softmax sampling (MVP)
            std::vector<float> probs((size_t)vocabSize);

            float maxLogit = logits[0];
            for (int32_t t = 1; t < vocabSize; t++) maxLogit = fmaxf(maxLogit, logits[t]);

            float sum = 0.0f;
            for (int32_t t = 0; t < vocabSize; t++) {
                float v = (logits[t] - maxLogit) / temperature;
                float p = expf(v);
                probs[(size_t)t] = p;
                sum += p;
            }

            float r = ((float)arc4random() / (float)UINT32_MAX) * sum;
            float acc = 0.0f;
            for (int32_t t = 0; t < vocabSize; t++) {
                acc += probs[(size_t)t];
                if (acc >= r) { next = (llama_token)t; break; }
            }
        }

        if (next == llama_vocab_eos(_vocab)) break;

        char buf[512];
        const int32_t n = llama_token_to_piece(
            _vocab,
            next,
            buf,
            (int32_t)sizeof(buf),
            0,
            false
        );

        if (n > 0) {
            NSString *piece = [[NSString alloc] initWithBytes:buf length:(NSUInteger)n encoding:NSUTF8StringEncoding];
            if (piece) [out appendString:piece];
        }

        llama_batch b2 = llama_batch_init(1, 0, 1);
        b2.token[0] = next;
        b2.pos[0] = curPos++;
        b2.n_seq_id[0] = 1;
        if (b2.seq_id && b2.seq_id[0]) {
            b2.seq_id[0][0] = 0;
        }
        b2.logits[0] = 1;
        b2.n_tokens = 1;

        if (llama_decode(_ctx, b2) != 0) {
            llama_batch_free(b2);
            if (error) *error = LLMakeErr(@"Decode failed during generation");
            break;
        }
        llama_batch_free(b2);
    }

    return [out stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
