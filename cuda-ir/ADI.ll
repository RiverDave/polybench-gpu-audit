; ModuleID = 'ADI/adi.cu'
source_filename = "ADI/adi.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11adi_kernel1iPfS_S_(i32 noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 %0, ptr %5, align 4
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %11 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %12 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %13 = mul i32 %11, %12
  %14 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %15 = add i32 %13, %14
  store i32 %15, ptr %9, align 4
  %16 = load i32, ptr %9, align 4
  %17 = load i32, ptr %5, align 4
  %18 = icmp slt i32 %16, %17
  br i1 %18, label %19, label %116

19:                                               ; preds = %4
  store i32 1, ptr %10, align 4
  br label %20

20:                                               ; preds = %112, %19
  %21 = load i32, ptr %10, align 4
  %22 = load i32, ptr %5, align 4
  %23 = icmp slt i32 %21, %22
  br i1 %23, label %24, label %115

24:                                               ; preds = %20
  %25 = load ptr, ptr %8, align 8
  %26 = load i32, ptr %9, align 4
  %27 = mul nsw i32 %26, 1024
  %28 = load i32, ptr %10, align 4
  %29 = add nsw i32 %27, %28
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds float, ptr %25, i64 %30
  %32 = load float, ptr %31, align 4
  %33 = load ptr, ptr %8, align 8
  %34 = load i32, ptr %9, align 4
  %35 = mul nsw i32 %34, 1024
  %36 = load i32, ptr %10, align 4
  %37 = sub nsw i32 %36, 1
  %38 = add nsw i32 %35, %37
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds float, ptr %33, i64 %39
  %41 = load float, ptr %40, align 4
  %42 = load ptr, ptr %6, align 8
  %43 = load i32, ptr %9, align 4
  %44 = mul nsw i32 %43, 1024
  %45 = load i32, ptr %10, align 4
  %46 = add nsw i32 %44, %45
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds float, ptr %42, i64 %47
  %49 = load float, ptr %48, align 4
  %50 = fmul contract float %41, %49
  %51 = load ptr, ptr %7, align 8
  %52 = load i32, ptr %9, align 4
  %53 = mul nsw i32 %52, 1024
  %54 = load i32, ptr %10, align 4
  %55 = sub nsw i32 %54, 1
  %56 = add nsw i32 %53, %55
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds float, ptr %51, i64 %57
  %59 = load float, ptr %58, align 4
  %60 = fdiv contract float %50, %59
  %61 = fsub contract float %32, %60
  %62 = load ptr, ptr %8, align 8
  %63 = load i32, ptr %9, align 4
  %64 = mul nsw i32 %63, 1024
  %65 = load i32, ptr %10, align 4
  %66 = add nsw i32 %64, %65
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds float, ptr %62, i64 %67
  store float %61, ptr %68, align 4
  %69 = load ptr, ptr %7, align 8
  %70 = load i32, ptr %9, align 4
  %71 = mul nsw i32 %70, 1024
  %72 = load i32, ptr %10, align 4
  %73 = add nsw i32 %71, %72
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds float, ptr %69, i64 %74
  %76 = load float, ptr %75, align 4
  %77 = load ptr, ptr %6, align 8
  %78 = load i32, ptr %9, align 4
  %79 = mul nsw i32 %78, 1024
  %80 = load i32, ptr %10, align 4
  %81 = add nsw i32 %79, %80
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds float, ptr %77, i64 %82
  %84 = load float, ptr %83, align 4
  %85 = load ptr, ptr %6, align 8
  %86 = load i32, ptr %9, align 4
  %87 = mul nsw i32 %86, 1024
  %88 = load i32, ptr %10, align 4
  %89 = add nsw i32 %87, %88
  %90 = sext i32 %89 to i64
  %91 = getelementptr inbounds float, ptr %85, i64 %90
  %92 = load float, ptr %91, align 4
  %93 = fmul contract float %84, %92
  %94 = load ptr, ptr %7, align 8
  %95 = load i32, ptr %9, align 4
  %96 = mul nsw i32 %95, 1024
  %97 = load i32, ptr %10, align 4
  %98 = sub nsw i32 %97, 1
  %99 = add nsw i32 %96, %98
  %100 = sext i32 %99 to i64
  %101 = getelementptr inbounds float, ptr %94, i64 %100
  %102 = load float, ptr %101, align 4
  %103 = fdiv contract float %93, %102
  %104 = fsub contract float %76, %103
  %105 = load ptr, ptr %7, align 8
  %106 = load i32, ptr %9, align 4
  %107 = mul nsw i32 %106, 1024
  %108 = load i32, ptr %10, align 4
  %109 = add nsw i32 %107, %108
  %110 = sext i32 %109 to i64
  %111 = getelementptr inbounds float, ptr %105, i64 %110
  store float %104, ptr %111, align 4
  br label %112

112:                                              ; preds = %24
  %113 = load i32, ptr %10, align 4
  %114 = add nsw i32 %113, 1
  store i32 %114, ptr %10, align 4
  br label %20, !llvm.loop !13

115:                                              ; preds = %20
  br label %116

116:                                              ; preds = %115, %4
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11adi_kernel2iPfS_S_(i32 noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  store i32 %0, ptr %5, align 4
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %10 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %11 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %12 = mul i32 %10, %11
  %13 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %14 = add i32 %12, %13
  store i32 %14, ptr %9, align 4
  %15 = load i32, ptr %9, align 4
  %16 = load i32, ptr %5, align 4
  %17 = icmp slt i32 %15, %16
  br i1 %17, label %18, label %40

18:                                               ; preds = %4
  %19 = load ptr, ptr %8, align 8
  %20 = load i32, ptr %9, align 4
  %21 = mul nsw i32 %20, 1024
  %22 = add nsw i32 %21, 1023
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds float, ptr %19, i64 %23
  %25 = load float, ptr %24, align 4
  %26 = load ptr, ptr %7, align 8
  %27 = load i32, ptr %9, align 4
  %28 = mul nsw i32 %27, 1024
  %29 = add nsw i32 %28, 1023
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds float, ptr %26, i64 %30
  %32 = load float, ptr %31, align 4
  %33 = fdiv contract float %25, %32
  %34 = load ptr, ptr %8, align 8
  %35 = load i32, ptr %9, align 4
  %36 = mul nsw i32 %35, 1024
  %37 = add nsw i32 %36, 1023
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds float, ptr %34, i64 %38
  store float %33, ptr %39, align 4
  br label %40

40:                                               ; preds = %18, %4
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11adi_kernel3iPfS_S_(i32 noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 %0, ptr %5, align 4
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %11 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %12 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %13 = mul i32 %11, %12
  %14 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %15 = add i32 %13, %14
  store i32 %15, ptr %9, align 4
  %16 = load i32, ptr %9, align 4
  %17 = load i32, ptr %5, align 4
  %18 = icmp slt i32 %16, %17
  br i1 %18, label %19, label %80

19:                                               ; preds = %4
  store i32 0, ptr %10, align 4
  br label %20

20:                                               ; preds = %76, %19
  %21 = load i32, ptr %10, align 4
  %22 = load i32, ptr %5, align 4
  %23 = sub nsw i32 %22, 2
  %24 = icmp slt i32 %21, %23
  br i1 %24, label %25, label %79

25:                                               ; preds = %20
  %26 = load ptr, ptr %8, align 8
  %27 = load i32, ptr %9, align 4
  %28 = mul nsw i32 %27, 1024
  %29 = load i32, ptr %10, align 4
  %30 = sub nsw i32 1022, %29
  %31 = add nsw i32 %28, %30
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds float, ptr %26, i64 %32
  %34 = load float, ptr %33, align 4
  %35 = load ptr, ptr %8, align 8
  %36 = load i32, ptr %9, align 4
  %37 = mul nsw i32 %36, 1024
  %38 = load i32, ptr %10, align 4
  %39 = sub nsw i32 1022, %38
  %40 = sub nsw i32 %39, 1
  %41 = add nsw i32 %37, %40
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds float, ptr %35, i64 %42
  %44 = load float, ptr %43, align 4
  %45 = load ptr, ptr %6, align 8
  %46 = load i32, ptr %9, align 4
  %47 = mul nsw i32 %46, 1024
  %48 = load i32, ptr %10, align 4
  %49 = sub nsw i32 1024, %48
  %50 = sub nsw i32 %49, 3
  %51 = add nsw i32 %47, %50
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds float, ptr %45, i64 %52
  %54 = load float, ptr %53, align 4
  %55 = fmul contract float %44, %54
  %56 = fsub contract float %34, %55
  %57 = load ptr, ptr %7, align 8
  %58 = load i32, ptr %9, align 4
  %59 = mul nsw i32 %58, 1024
  %60 = load i32, ptr %10, align 4
  %61 = sub nsw i32 1021, %60
  %62 = add nsw i32 %59, %61
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %57, i64 %63
  %65 = load float, ptr %64, align 4
  %66 = fdiv contract float %56, %65
  %67 = load ptr, ptr %8, align 8
  %68 = load i32, ptr %9, align 4
  %69 = mul nsw i32 %68, 1024
  %70 = load i32, ptr %10, align 4
  %71 = sub nsw i32 1024, %70
  %72 = sub nsw i32 %71, 2
  %73 = add nsw i32 %69, %72
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds float, ptr %67, i64 %74
  store float %66, ptr %75, align 4
  br label %76

76:                                               ; preds = %25
  %77 = load i32, ptr %10, align 4
  %78 = add nsw i32 %77, 1
  store i32 %78, ptr %10, align 4
  br label %20, !llvm.loop !15

79:                                               ; preds = %20
  br label %80

80:                                               ; preds = %79, %4
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11adi_kernel4iPfS_S_i(i32 noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef %4) #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store i32 %0, ptr %6, align 4
  store ptr %1, ptr %7, align 8
  store ptr %2, ptr %8, align 8
  store ptr %3, ptr %9, align 8
  store i32 %4, ptr %10, align 4
  %12 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %13 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %14 = mul i32 %12, %13
  %15 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %16 = add i32 %14, %15
  store i32 %16, ptr %11, align 4
  %17 = load i32, ptr %11, align 4
  %18 = load i32, ptr %6, align 4
  %19 = icmp slt i32 %17, %18
  br i1 %19, label %20, label %108

20:                                               ; preds = %5
  %21 = load ptr, ptr %9, align 8
  %22 = load i32, ptr %10, align 4
  %23 = mul nsw i32 %22, 1024
  %24 = load i32, ptr %11, align 4
  %25 = add nsw i32 %23, %24
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds float, ptr %21, i64 %26
  %28 = load float, ptr %27, align 4
  %29 = load ptr, ptr %9, align 8
  %30 = load i32, ptr %10, align 4
  %31 = sub nsw i32 %30, 1
  %32 = mul nsw i32 %31, 1024
  %33 = load i32, ptr %11, align 4
  %34 = add nsw i32 %32, %33
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds float, ptr %29, i64 %35
  %37 = load float, ptr %36, align 4
  %38 = load ptr, ptr %7, align 8
  %39 = load i32, ptr %10, align 4
  %40 = mul nsw i32 %39, 1024
  %41 = load i32, ptr %11, align 4
  %42 = add nsw i32 %40, %41
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %38, i64 %43
  %45 = load float, ptr %44, align 4
  %46 = fmul contract float %37, %45
  %47 = load ptr, ptr %8, align 8
  %48 = load i32, ptr %10, align 4
  %49 = sub nsw i32 %48, 1
  %50 = mul nsw i32 %49, 1024
  %51 = load i32, ptr %11, align 4
  %52 = add nsw i32 %50, %51
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds float, ptr %47, i64 %53
  %55 = load float, ptr %54, align 4
  %56 = fdiv contract float %46, %55
  %57 = fsub contract float %28, %56
  %58 = load ptr, ptr %9, align 8
  %59 = load i32, ptr %10, align 4
  %60 = mul nsw i32 %59, 1024
  %61 = load i32, ptr %11, align 4
  %62 = add nsw i32 %60, %61
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %58, i64 %63
  store float %57, ptr %64, align 4
  %65 = load ptr, ptr %8, align 8
  %66 = load i32, ptr %10, align 4
  %67 = mul nsw i32 %66, 1024
  %68 = load i32, ptr %11, align 4
  %69 = add nsw i32 %67, %68
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds float, ptr %65, i64 %70
  %72 = load float, ptr %71, align 4
  %73 = load ptr, ptr %7, align 8
  %74 = load i32, ptr %10, align 4
  %75 = mul nsw i32 %74, 1024
  %76 = load i32, ptr %11, align 4
  %77 = add nsw i32 %75, %76
  %78 = sext i32 %77 to i64
  %79 = getelementptr inbounds float, ptr %73, i64 %78
  %80 = load float, ptr %79, align 4
  %81 = load ptr, ptr %7, align 8
  %82 = load i32, ptr %10, align 4
  %83 = mul nsw i32 %82, 1024
  %84 = load i32, ptr %11, align 4
  %85 = add nsw i32 %83, %84
  %86 = sext i32 %85 to i64
  %87 = getelementptr inbounds float, ptr %81, i64 %86
  %88 = load float, ptr %87, align 4
  %89 = fmul contract float %80, %88
  %90 = load ptr, ptr %8, align 8
  %91 = load i32, ptr %10, align 4
  %92 = sub nsw i32 %91, 1
  %93 = mul nsw i32 %92, 1024
  %94 = load i32, ptr %11, align 4
  %95 = add nsw i32 %93, %94
  %96 = sext i32 %95 to i64
  %97 = getelementptr inbounds float, ptr %90, i64 %96
  %98 = load float, ptr %97, align 4
  %99 = fdiv contract float %89, %98
  %100 = fsub contract float %72, %99
  %101 = load ptr, ptr %8, align 8
  %102 = load i32, ptr %10, align 4
  %103 = mul nsw i32 %102, 1024
  %104 = load i32, ptr %11, align 4
  %105 = add nsw i32 %103, %104
  %106 = sext i32 %105 to i64
  %107 = getelementptr inbounds float, ptr %101, i64 %106
  store float %100, ptr %107, align 4
  br label %108

108:                                              ; preds = %20, %5
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11adi_kernel5iPfS_S_(i32 noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  store i32 %0, ptr %5, align 4
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %10 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %11 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %12 = mul i32 %10, %11
  %13 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %14 = add i32 %12, %13
  store i32 %14, ptr %9, align 4
  %15 = load i32, ptr %9, align 4
  %16 = load i32, ptr %5, align 4
  %17 = icmp slt i32 %15, %16
  br i1 %17, label %18, label %37

18:                                               ; preds = %4
  %19 = load ptr, ptr %8, align 8
  %20 = load i32, ptr %9, align 4
  %21 = add nsw i32 1047552, %20
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds float, ptr %19, i64 %22
  %24 = load float, ptr %23, align 4
  %25 = load ptr, ptr %7, align 8
  %26 = load i32, ptr %9, align 4
  %27 = add nsw i32 1047552, %26
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds float, ptr %25, i64 %28
  %30 = load float, ptr %29, align 4
  %31 = fdiv contract float %24, %30
  %32 = load ptr, ptr %8, align 8
  %33 = load i32, ptr %9, align 4
  %34 = add nsw i32 1047552, %33
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds float, ptr %32, i64 %35
  store float %31, ptr %36, align 4
  br label %37

37:                                               ; preds = %18, %4
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11adi_kernel6iPfS_S_i(i32 noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef %4) #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store i32 %0, ptr %6, align 4
  store ptr %1, ptr %7, align 8
  store ptr %2, ptr %8, align 8
  store ptr %3, ptr %9, align 8
  store i32 %4, ptr %10, align 4
  %12 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %13 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %14 = mul i32 %12, %13
  %15 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %16 = add i32 %14, %15
  store i32 %16, ptr %11, align 4
  %17 = load i32, ptr %11, align 4
  %18 = load i32, ptr %6, align 4
  %19 = icmp slt i32 %17, %18
  br i1 %19, label %20, label %69

20:                                               ; preds = %5
  %21 = load ptr, ptr %9, align 8
  %22 = load i32, ptr %10, align 4
  %23 = sub nsw i32 1022, %22
  %24 = mul nsw i32 %23, 1024
  %25 = load i32, ptr %11, align 4
  %26 = add nsw i32 %24, %25
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds float, ptr %21, i64 %27
  %29 = load float, ptr %28, align 4
  %30 = load ptr, ptr %9, align 8
  %31 = load i32, ptr %10, align 4
  %32 = sub nsw i32 1024, %31
  %33 = sub nsw i32 %32, 3
  %34 = mul nsw i32 %33, 1024
  %35 = load i32, ptr %11, align 4
  %36 = add nsw i32 %34, %35
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds float, ptr %30, i64 %37
  %39 = load float, ptr %38, align 4
  %40 = load ptr, ptr %7, align 8
  %41 = load i32, ptr %10, align 4
  %42 = sub nsw i32 1021, %41
  %43 = mul nsw i32 %42, 1024
  %44 = load i32, ptr %11, align 4
  %45 = add nsw i32 %43, %44
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds float, ptr %40, i64 %46
  %48 = load float, ptr %47, align 4
  %49 = fmul contract float %39, %48
  %50 = fsub contract float %29, %49
  %51 = load ptr, ptr %8, align 8
  %52 = load i32, ptr %10, align 4
  %53 = sub nsw i32 1022, %52
  %54 = mul nsw i32 %53, 1024
  %55 = load i32, ptr %11, align 4
  %56 = add nsw i32 %54, %55
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds float, ptr %51, i64 %57
  %59 = load float, ptr %58, align 4
  %60 = fdiv contract float %50, %59
  %61 = load ptr, ptr %9, align 8
  %62 = load i32, ptr %10, align 4
  %63 = sub nsw i32 1022, %62
  %64 = mul nsw i32 %63, 1024
  %65 = load i32, ptr %11, align 4
  %66 = add nsw i32 %64, %65
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds float, ptr %61, i64 %67
  store float %60, ptr %68, align 4
  br label %69

69:                                               ; preds = %20, %5
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3}
!nvvm.annotations = !{!4, !5, !6, !7, !8, !9}
!llvm.ident = !{!10, !11}
!nvvmir.version = !{!12}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z11adi_kernel1iPfS_S_}
!5 = !{ptr @_Z11adi_kernel2iPfS_S_}
!6 = !{ptr @_Z11adi_kernel3iPfS_S_}
!7 = !{ptr @_Z11adi_kernel4iPfS_S_i}
!8 = !{ptr @_Z11adi_kernel5iPfS_S_}
!9 = !{ptr @_Z11adi_kernel6iPfS_S_i}
!10 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!11 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!12 = !{i32 2, i32 0}
!13 = distinct !{!13, !14}
!14 = !{!"llvm.loop.mustprogress"}
!15 = distinct !{!15, !14}
