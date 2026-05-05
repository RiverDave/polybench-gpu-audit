; ModuleID = 'CORR/correlation.cu'
source_filename = "CORR/correlation.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1
@.str = private unnamed_addr constant [11 x i8] c"__CUDA_FTZ\00", align 1
@.str.2 = private unnamed_addr constant [17 x i8] c"__CUDA_PREC_SQRT\00", align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11mean_kerneliiPfS_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 %0, ptr %5, align 4
  store i32 %1, ptr %6, align 4
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
  br i1 %18, label %19, label %53

19:                                               ; preds = %4
  %20 = load ptr, ptr %7, align 8
  %21 = load i32, ptr %9, align 4
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds float, ptr %20, i64 %22
  store float 0.000000e+00, ptr %23, align 4
  store i32 0, ptr %10, align 4
  br label %24

24:                                               ; preds = %43, %19
  %25 = load i32, ptr %10, align 4
  %26 = load i32, ptr %6, align 4
  %27 = icmp slt i32 %25, %26
  br i1 %27, label %28, label %46

28:                                               ; preds = %24
  %29 = load ptr, ptr %8, align 8
  %30 = load i32, ptr %10, align 4
  %31 = mul nsw i32 %30, 2048
  %32 = load i32, ptr %9, align 4
  %33 = add nsw i32 %31, %32
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds float, ptr %29, i64 %34
  %36 = load float, ptr %35, align 4
  %37 = load ptr, ptr %7, align 8
  %38 = load i32, ptr %9, align 4
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds float, ptr %37, i64 %39
  %41 = load float, ptr %40, align 4
  %42 = fadd contract float %41, %36
  store float %42, ptr %40, align 4
  br label %43

43:                                               ; preds = %28
  %44 = load i32, ptr %10, align 4
  %45 = add nsw i32 %44, 1
  store i32 %45, ptr %10, align 4
  br label %24, !llvm.loop !11

46:                                               ; preds = %24
  %47 = load ptr, ptr %7, align 8
  %48 = load i32, ptr %9, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds float, ptr %47, i64 %49
  %51 = load float, ptr %50, align 4
  %52 = fdiv contract float %51, 0x414885C200000000
  store float %52, ptr %50, align 4
  br label %53

53:                                               ; preds = %46, %4
  ret void
}

; Function Attrs: convergent noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z10std_kerneliiPfS_S_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4) #1 {
  %6 = alloca float, align 4
  %7 = alloca float, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  store i32 %0, ptr %8, align 4
  store i32 %1, ptr %9, align 4
  store ptr %2, ptr %10, align 8
  store ptr %3, ptr %11, align 8
  store ptr %4, ptr %12, align 8
  %15 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %16 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %17 = mul i32 %15, %16
  %18 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %19 = add i32 %17, %18
  store i32 %19, ptr %13, align 4
  %20 = load i32, ptr %13, align 4
  %21 = load i32, ptr %8, align 4
  %22 = icmp slt i32 %20, %21
  br i1 %22, label %23, label %102

23:                                               ; preds = %5
  %24 = load ptr, ptr %11, align 8
  %25 = load i32, ptr %13, align 4
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds float, ptr %24, i64 %26
  store float 0.000000e+00, ptr %27, align 4
  store i32 0, ptr %14, align 4
  br label %28

28:                                               ; preds = %68, %23
  %29 = load i32, ptr %14, align 4
  %30 = load i32, ptr %9, align 4
  %31 = icmp slt i32 %29, %30
  br i1 %31, label %32, label %71

32:                                               ; preds = %28
  %33 = load ptr, ptr %12, align 8
  %34 = load i32, ptr %14, align 4
  %35 = mul nsw i32 %34, 2048
  %36 = load i32, ptr %13, align 4
  %37 = add nsw i32 %35, %36
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds float, ptr %33, i64 %38
  %40 = load float, ptr %39, align 4
  %41 = load ptr, ptr %10, align 8
  %42 = load i32, ptr %13, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %41, i64 %43
  %45 = load float, ptr %44, align 4
  %46 = fsub contract float %40, %45
  %47 = load ptr, ptr %12, align 8
  %48 = load i32, ptr %14, align 4
  %49 = mul nsw i32 %48, 2048
  %50 = load i32, ptr %13, align 4
  %51 = add nsw i32 %49, %50
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds float, ptr %47, i64 %52
  %54 = load float, ptr %53, align 4
  %55 = load ptr, ptr %10, align 8
  %56 = load i32, ptr %13, align 4
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds float, ptr %55, i64 %57
  %59 = load float, ptr %58, align 4
  %60 = fsub contract float %54, %59
  %61 = fmul contract float %46, %60
  %62 = load ptr, ptr %11, align 8
  %63 = load i32, ptr %13, align 4
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds float, ptr %62, i64 %64
  %66 = load float, ptr %65, align 4
  %67 = fadd contract float %66, %61
  store float %67, ptr %65, align 4
  br label %68

68:                                               ; preds = %32
  %69 = load i32, ptr %14, align 4
  %70 = add nsw i32 %69, 1
  store i32 %70, ptr %14, align 4
  br label %28, !llvm.loop !13

71:                                               ; preds = %28
  %72 = load ptr, ptr %11, align 8
  %73 = load i32, ptr %13, align 4
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds float, ptr %72, i64 %74
  %76 = load float, ptr %75, align 4
  %77 = fdiv contract float %76, 0x414885C200000000
  store float %77, ptr %75, align 4
  %78 = load ptr, ptr %11, align 8
  %79 = load i32, ptr %13, align 4
  %80 = sext i32 %79 to i64
  %81 = getelementptr inbounds float, ptr %78, i64 %80
  %82 = load float, ptr %81, align 4
  store float %82, ptr %7, align 4
  %83 = load float, ptr %7, align 4
  store float %83, ptr %6, align 4
  %84 = load float, ptr %6, align 4
  %85 = call float @llvm.nvvm.sqrt.approx.f(float %84) #5
  %86 = load ptr, ptr %11, align 8
  %87 = load i32, ptr %13, align 4
  %88 = sext i32 %87 to i64
  %89 = getelementptr inbounds float, ptr %86, i64 %88
  store float %85, ptr %89, align 4
  %90 = load ptr, ptr %11, align 8
  %91 = load i32, ptr %13, align 4
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds float, ptr %90, i64 %92
  %94 = load float, ptr %93, align 4
  %95 = fcmp contract ole float %94, 0x3F747AE140000000
  br i1 %95, label %96, label %101

96:                                               ; preds = %71
  %97 = load ptr, ptr %11, align 8
  %98 = load i32, ptr %13, align 4
  %99 = sext i32 %98 to i64
  %100 = getelementptr inbounds float, ptr %97, i64 %99
  store float 1.000000e+00, ptr %100, align 4
  br label %101

101:                                              ; preds = %96, %71
  br label %102

102:                                              ; preds = %101, %5
  ret void
}

; Function Attrs: convergent noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z13reduce_kerneliiPfS_S_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4) #1 {
  %6 = alloca float, align 4
  %7 = alloca float, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  store i32 %0, ptr %8, align 4
  store i32 %1, ptr %9, align 4
  store ptr %2, ptr %10, align 8
  store ptr %3, ptr %11, align 8
  store ptr %4, ptr %12, align 8
  %15 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %16 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %17 = mul i32 %15, %16
  %18 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %19 = add i32 %17, %18
  store i32 %19, ptr %13, align 4
  %20 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %21 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %22 = mul i32 %20, %21
  %23 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %24 = add i32 %22, %23
  store i32 %24, ptr %14, align 4
  %25 = load i32, ptr %14, align 4
  %26 = load i32, ptr %9, align 4
  %27 = icmp slt i32 %25, %26
  br i1 %27, label %28, label %65

28:                                               ; preds = %5
  %29 = load i32, ptr %13, align 4
  %30 = load i32, ptr %8, align 4
  %31 = icmp slt i32 %29, %30
  br i1 %31, label %32, label %65

32:                                               ; preds = %28
  %33 = load ptr, ptr %10, align 8
  %34 = load i32, ptr %13, align 4
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds float, ptr %33, i64 %35
  %37 = load float, ptr %36, align 4
  %38 = load ptr, ptr %12, align 8
  %39 = load i32, ptr %14, align 4
  %40 = mul nsw i32 %39, 2048
  %41 = load i32, ptr %13, align 4
  %42 = add nsw i32 %40, %41
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %38, i64 %43
  %45 = load float, ptr %44, align 4
  %46 = fsub contract float %45, %37
  store float %46, ptr %44, align 4
  store float 0x414885C200000000, ptr %7, align 4
  %47 = load float, ptr %7, align 4
  store float %47, ptr %6, align 4
  %48 = load float, ptr %6, align 4
  %49 = call float @llvm.nvvm.sqrt.approx.f(float %48) #5
  %50 = load ptr, ptr %11, align 8
  %51 = load i32, ptr %13, align 4
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds float, ptr %50, i64 %52
  %54 = load float, ptr %53, align 4
  %55 = fmul contract float %49, %54
  %56 = load ptr, ptr %12, align 8
  %57 = load i32, ptr %14, align 4
  %58 = mul nsw i32 %57, 2048
  %59 = load i32, ptr %13, align 4
  %60 = add nsw i32 %58, %59
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds float, ptr %56, i64 %61
  %63 = load float, ptr %62, align 4
  %64 = fdiv contract float %63, %55
  store float %64, ptr %62, align 4
  br label %65

65:                                               ; preds = %32, %28, %5
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11corr_kerneliiPfS_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store i32 %0, ptr %5, align 4
  store i32 %1, ptr %6, align 4
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %12 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %13 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %14 = mul i32 %12, %13
  %15 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %16 = add i32 %14, %15
  store i32 %16, ptr %9, align 4
  %17 = load i32, ptr %9, align 4
  %18 = load i32, ptr %5, align 4
  %19 = sub nsw i32 %18, 1
  %20 = icmp slt i32 %17, %19
  br i1 %20, label %21, label %97

21:                                               ; preds = %4
  %22 = load ptr, ptr %7, align 8
  %23 = load i32, ptr %9, align 4
  %24 = mul nsw i32 %23, 2048
  %25 = load i32, ptr %9, align 4
  %26 = add nsw i32 %24, %25
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds float, ptr %22, i64 %27
  store float 1.000000e+00, ptr %28, align 4
  %29 = load i32, ptr %9, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %11, align 4
  br label %31

31:                                               ; preds = %93, %21
  %32 = load i32, ptr %11, align 4
  %33 = load i32, ptr %5, align 4
  %34 = icmp slt i32 %32, %33
  br i1 %34, label %35, label %96

35:                                               ; preds = %31
  %36 = load ptr, ptr %7, align 8
  %37 = load i32, ptr %9, align 4
  %38 = mul nsw i32 %37, 2048
  %39 = load i32, ptr %11, align 4
  %40 = add nsw i32 %38, %39
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds float, ptr %36, i64 %41
  store float 0.000000e+00, ptr %42, align 4
  store i32 0, ptr %10, align 4
  br label %43

43:                                               ; preds = %74, %35
  %44 = load i32, ptr %10, align 4
  %45 = load i32, ptr %6, align 4
  %46 = icmp slt i32 %44, %45
  br i1 %46, label %47, label %77

47:                                               ; preds = %43
  %48 = load ptr, ptr %8, align 8
  %49 = load i32, ptr %10, align 4
  %50 = mul nsw i32 %49, 2048
  %51 = load i32, ptr %9, align 4
  %52 = add nsw i32 %50, %51
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds float, ptr %48, i64 %53
  %55 = load float, ptr %54, align 4
  %56 = load ptr, ptr %8, align 8
  %57 = load i32, ptr %10, align 4
  %58 = mul nsw i32 %57, 2048
  %59 = load i32, ptr %11, align 4
  %60 = add nsw i32 %58, %59
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds float, ptr %56, i64 %61
  %63 = load float, ptr %62, align 4
  %64 = fmul contract float %55, %63
  %65 = load ptr, ptr %7, align 8
  %66 = load i32, ptr %9, align 4
  %67 = mul nsw i32 %66, 2048
  %68 = load i32, ptr %11, align 4
  %69 = add nsw i32 %67, %68
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds float, ptr %65, i64 %70
  %72 = load float, ptr %71, align 4
  %73 = fadd contract float %72, %64
  store float %73, ptr %71, align 4
  br label %74

74:                                               ; preds = %47
  %75 = load i32, ptr %10, align 4
  %76 = add nsw i32 %75, 1
  store i32 %76, ptr %10, align 4
  br label %43, !llvm.loop !14

77:                                               ; preds = %43
  %78 = load ptr, ptr %7, align 8
  %79 = load i32, ptr %9, align 4
  %80 = mul nsw i32 %79, 2048
  %81 = load i32, ptr %11, align 4
  %82 = add nsw i32 %80, %81
  %83 = sext i32 %82 to i64
  %84 = getelementptr inbounds float, ptr %78, i64 %83
  %85 = load float, ptr %84, align 4
  %86 = load ptr, ptr %7, align 8
  %87 = load i32, ptr %11, align 4
  %88 = mul nsw i32 %87, 2048
  %89 = load i32, ptr %9, align 4
  %90 = add nsw i32 %88, %89
  %91 = sext i32 %90 to i64
  %92 = getelementptr inbounds float, ptr %86, i64 %91
  store float %85, ptr %92, align 4
  br label %93

93:                                               ; preds = %77
  %94 = load i32, ptr %11, align 4
  %95 = add nsw i32 %94, 1
  store i32 %95, ptr %11, align 4
  br label %31, !llvm.loop !15

96:                                               ; preds = %31
  br label %97

97:                                               ; preds = %96, %4
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.y() #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.y() #2

; Function Attrs: convergent nounwind
declare i32 @__nvvm_reflect(ptr) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.rn.ftz.f(float) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.approx.ftz.f(float) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.rn.f(float) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.approx.f(float) #4

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "uniform-work-group-size"="true" }
attributes #1 = { convergent noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "uniform-work-group-size"="true" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { convergent nounwind "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!nvvm.annotations = !{!4, !5, !6, !7}
!llvm.ident = !{!8, !9}
!nvvmir.version = !{!10}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z11mean_kerneliiPfS_}
!5 = !{ptr @_Z10std_kerneliiPfS_S_}
!6 = !{ptr @_Z13reduce_kerneliiPfS_S_}
!7 = !{ptr @_Z11corr_kerneliiPfS_}
!8 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!9 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!10 = !{i32 2, i32 0}
!11 = distinct !{!11, !12}
!12 = !{!"llvm.loop.mustprogress"}
!13 = distinct !{!13, !12}
!14 = distinct !{!14, !12}
!15 = distinct !{!15, !12}
