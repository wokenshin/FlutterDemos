#include <stdint.h>

int32_t add_int(int32_t a, int32_t b) {
    return a + b;
}

int32_t subtract_int(int32_t a, int32_t b) {
    return a - b;
}

int32_t multiply_int(int32_t a, int32_t b) {
    return a * b;
}

int32_t divide_int(int32_t a, int32_t b) {
    if (b == 0) {
        return 0;
    }
    return a / b;
}