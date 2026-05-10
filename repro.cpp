// Reproducer for CIR bug: array-to-pointer decay on AMDGPU loses the implicit
// addrspace(5) → generic addrspacecast, causing a CIR verifier failure.
//
// Compile command:
//   clang -cc1 -triple amdgcn-amd-amdhsa -target-cpu gfx942 \
//         -fclangir -std=c++17 -O0 -emit-obj -x c++ repro.cpp -o /dev/null
//
// Expected: compiles cleanly
// Actual:   error: 'cir.cast' op result type address space does not match the
//           address space of the operand
//
// Root cause:
//   Local arrays on AMDGPU live in private addrspace(5). When the array decays
//   to a pointer (CK_ArrayToPointerDecay), CIR preserves addrspace(5) in the
//   result type. Storing that addrspace(5) pointer into a generic (addrspace 0)
//   variable then causes createStore to emit a bitcast (kind=1) that changes
//   the outer pointer's address space, which the CIR verifier correctly rejects.
//
//   OG LLVM codegen inserts an `addrspacecast addrspace(5) → flat` immediately
//   after the alloca, so all downstream pointer arithmetic stays in flat/generic.
//   CIR does not insert this cast, leaving the addrspace(5) type to propagate.
//
// Fix: In CIRGenExprScalar.cpp, case CK_ArrayToPointerDecay, emit a
//      cir.cast(kind=address_space) after the decay when the CIR result type
//      does not match the Clang expression's expected pointer type.

void foo() {
    const char fmt[] = "hello";   // stack array → AMDGPU private addrspace(5)
    const char *tmp = fmt;        // decay must implicitly cast addrspace(5) → generic
    while (*tmp++);
}
