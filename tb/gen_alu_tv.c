#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
void simulate_alu(uint32_t src_a, uint32_t src_b, uint8_t alu_control, uint32_t *alu_result, uint8_t *zero) {
uint32_t bb = (alu_control & 1) ? ~src_b : src_b;
uint32_t cin = alu_control & 1;
// 1. Prefix Adder
uint64_t sum64 = (uint64_t)src_a + (uint64_t)bb + cin;
uint32_t y0 = (uint32_t)sum64;

// 2. Bitwise Logic
uint32_t y1 = (alu_control & 1) ? (src_a | src_b) : (src_a & src_b);

// 3. Mux ALUControl[1]
uint32_t y2 = (alu_control & 2) ? y1 : y0;

// 4. Overflow Detection
uint8_t a31 = (src_a >> 31) & 1;
uint8_t b31 = (src_b >> 31) & 1;
uint8_t y0_31 = (y0 >> 31) & 1;

uint8_t p3 = !a31 && b31;
uint8_t p2 = a31 && !b31;
uint8_t p1 = !a31 && !b31;
uint8_t p0 = a31 && b31;

uint8_t sel = ((alu_control & 1) << 1) | y0_31;
uint8_t overflow = 0;
switch (sel) {
    case 0: overflow = p0; break;
    case 1: overflow = p1; break;
    case 2: overflow = p2; break;
    case 3: overflow = p3; break;
}

// 5. Mux ALUControl[2] (SLT)
uint8_t slt_bit = overflow ^ y0_31;
if (alu_control & 4) {
    *alu_result = (uint32_t)slt_bit;
} else {
    *alu_result = y2;
}

// 6. Cờ Zero
*zero = (*alu_result == 0) ? 1 : 0;
}
void write_vector(FILE *fp, uint32_t a, uint32_t b, uint8_t ctrl) {
uint32_t res;
uint8_t zero;
simulate_alu(a, b, ctrl, &res, &zero);
uint32_t high_4bit = ((ctrl & 0x7) << 1) | ((res >> 31) & 0x1);
uint32_t low_32bit = (res << 1) | (zero & 0x1);

fprintf(fp, "%08X_%08X_%01X%08X\n", a, b, high_4bit, low_32bit);
}
int main() {
FILE *fp = fopen("alu_tv.tv", "w");
if (!fp) {
printf("Loi tao file alu_tv.tv!\n");
return 1;
}
uint32_t test_values[] = {
    0x00000000, 0x00000001, 0x00000002, 0x00000005, 0x0000000A,
    0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 0xFFFFFFFE,
    0x55555555, 0xAAAAAAAA
};
int num_vals = sizeof(test_values) / sizeof(test_values[0]);

for (uint8_t ctrl = 0; ctrl < 8; ctrl++) {
    for (int i = 0; i < num_vals; i++) {
        for (int j = 0; j < num_vals; j++) {
            write_vector(fp, test_values[i], test_values[j], ctrl);
        }
    }
}

srand((unsigned int)time(NULL));
for (int i = 0; i < 1000; i++) {
    uint32_t a = ((uint32_t)rand() << 16) | (rand() & 0xFFFF);
    uint32_t b = ((uint32_t)rand() << 16) | (rand() & 0xFFFF);
    uint8_t ctrl = rand() % 8;
    write_vector(fp, a, b, ctrl);
}

fclose(fp);
printf("Da tao thanh cong file alu_tv.tv!\n");
return 0;
}