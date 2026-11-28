/* Diagnostic for longjmp crashes with MinGW-w64 GCC on x86_64 Windows.
 *
 * victim() calls setjmp() (MinGW's macro passes __builtin_frame_address(0),
 * so longjmp() does an SEH unwind via RtlUnwindEx()), has a FRAME-byte local
 * array, and saves xmm6 in its prologue (unless NO_XMM is defined).
 *
 * probe() asks the system unwinder (RtlVirtualUnwind, as used by RtlUnwindEx)
 * where victim() saved xmm6. It does this on a copy of the context whose frame
 * pointer points into a scratch buffer, so the probe itself never faults.
 * It prints a prediction: whether longjmp's unwind will read past the top of
 * the stack. Then thrower() calls longjmp(); if the prediction is right, the
 * process dies with an access violation exactly when it says "FAULT".
 */
#include <setjmp.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

#ifndef FRAME
#define FRAME 5000
#endif

static jmp_buf buf;
static char *victim_rbp;
static char scratch[1 << 21];

__attribute__((noinline)) static void probe(void) {
    CONTEXT ctx;
    KNONVOLATILE_CONTEXT_POINTERS ptrs;
    DWORD64 base, establisher;
    void *handler_data;
    PRUNTIME_FUNCTION fn;

    RtlCaptureContext(&ctx);
    /* Unwind probe() itself; ctx is now in thrower(). Unwind that too. */
    for (int i = 0; i < 2; i++) {
        fn = RtlLookupFunctionEntry(ctx.Rip, &base, NULL);
        RtlVirtualUnwind(UNW_FLAG_NHANDLER, base, ctx.Rip, fn, &ctx, &handler_data, &establisher, NULL);
    }
    /* ctx is now in victim(). Redirect its frame pointer into scratch. */
    char *fake_rbp = scratch + sizeof(scratch) / 2;
    ctx.Rbp = (DWORD64) fake_rbp;
    ctx.Rsp = (DWORD64) (fake_rbp - FRAME - 4096);
    memset(&ptrs, 0, sizeof ptrs);
    fn = RtlLookupFunctionEntry(ctx.Rip, &base, NULL);
    RtlVirtualUnwind(UNW_FLAG_NHANDLER, base, ctx.Rip, fn, &ctx, &handler_data, &establisher, &ptrs);

    NT_TIB *tib = (NT_TIB *) NtCurrentTeb();
    long long top = (char *) tib->StackBase - victim_rbp;
    if (ptrs.FloatingContext[6] == NULL) {
        printf("FRAME=%d top=rbp%+lld xmm6=not-saved predict=OK\n", FRAME, top);
    } else {
        long long off = (char *) ptrs.FloatingContext[6] - fake_rbp;
        printf("FRAME=%d top=rbp%+lld xmm6=rbp%+lld predict=%s\n", FRAME, top, off,
               off + 16 > top ? "FAULT" : "OK");
    }
    fflush(stdout);
}

__attribute__((noinline)) static void thrower(void) {
    probe();
    longjmp(buf, 1);
}

__attribute__((noinline)) static int victim(volatile char *sink) {
    char big[FRAME];
#ifndef NO_XMM
    __asm__ volatile ("" ::: "xmm6");   /* forces a save of xmm6 */
#endif
    victim_rbp = __builtin_frame_address(0);
    memset(big, 1, sizeof big);
    *sink = big[FRAME / 2];
    if (setjmp(buf)) {
        return 1;
    }
    thrower();
    return 0;
}

int main(void) {
    volatile char c;
    int r = victim(&c);
    printf("survived=%d\n", r);
    return 0;
}
