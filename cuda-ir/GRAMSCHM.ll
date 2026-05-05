; ModuleID = 'GRAMSCHM/gramschmidt.cu'
source_filename = "GRAMSCHM/gramschmidt.cu"
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

; Function Attrs: convergent noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z19gramschmidt_kernel1iiPfS_S_i(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, i32 noundef %5) #0 {
  %7 = alloca float, align 4
  %8 = alloca float, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca float, align 4
  %17 = alloca i32, align 4
  store i32 %0, ptr %9, align 4
  store i32 %1, ptr %10, align 4
  store ptr %2, ptr %11, align 8
  store ptr %3, ptr %12, align 8
  store ptr %4, ptr %13, align 8
  store i32 %5, ptr %14, align 4
  %18 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %19 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %20 = mul i32 %18, %19
  %21 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %22 = add i32 %20, %21
  store i32 %22, ptr %15, align 4
  %23 = load i32, ptr %15, align 4
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %25, label %65

25:                                               ; preds = %6
  store float 0.000000e+00, ptr %16, align 4
  store i32 0, ptr %17, align 4
  br label %26

26:                                               ; preds = %50, %25
  %27 = load i32, ptr %17, align 4
  %28 = load i32, ptr %9, align 4
  %29 = icmp slt i32 %27, %28
  br i1 %29, label %30, label %53

30:                                               ; preds = %26
  %31 = load ptr, ptr %11, align 8
  %32 = load i32, ptr %17, align 4
  %33 = mul nsw i32 %32, 2048
  %34 = load i32, ptr %14, align 4
  %35 = add nsw i32 %33, %34
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds float, ptr %31, i64 %36
  %38 = load float, ptr %37, align 4
  %39 = load ptr, ptr %11, align 8
  %40 = load i32, ptr %17, align 4
  %41 = mul nsw i32 %40, 2048
  %42 = load i32, ptr %14, align 4
  %43 = add nsw i32 %41, %42
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds float, ptr %39, i64 %44
  %46 = load float, ptr %45, align 4
  %47 = fmul contract float %38, %46
  %48 = load float, ptr %16, align 4
  %49 = fadd contract float %48, %47
  store float %49, ptr %16, align 4
  br label %50

50:                                               ; preds = %30
  %51 = load i32, ptr %17, align 4
  %52 = add nsw i32 %51, 1
  store i32 %52, ptr %17, align 4
  br label %26, !llvm.loop !10

53:                                               ; preds = %26
  %54 = load float, ptr %16, align 4
  store float %54, ptr %8, align 4
  %55 = load float, ptr %8, align 4
  store float %55, ptr %7, align 4
  %56 = load float, ptr %7, align 4
  %57 = call float @llvm.nvvm.sqrt.approx.f(float %56) #5
  %58 = load ptr, ptr %12, align 8
  %59 = load i32, ptr %14, align 4
  %60 = mul nsw i32 %59, 2048
  %61 = load i32, ptr %14, align 4
  %62 = add nsw i32 %60, %61
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %58, i64 %63
  store float %57, ptr %64, align 4
  br label %65

65:                                               ; preds = %53, %6
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z19gramschmidt_kernel2iiPfS_S_i(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, i32 noundef %5) #1 {
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store i32 %0, ptr %7, align 4
  store i32 %1, ptr %8, align 4
  store ptr %2, ptr %9, align 8
  store ptr %3, ptr %10, align 8
  store ptr %4, ptr %11, align 8
  store i32 %5, ptr %12, align 4
  %14 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %15 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %16 = mul i32 %14, %15
  %17 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %18 = add i32 %16, %17
  store i32 %18, ptr %13, align 4
  %19 = load i32, ptr %13, align 4
  %20 = load i32, ptr %7, align 4
  %21 = icmp slt i32 %19, %20
  br i1 %21, label %22, label %47

22:                                               ; preds = %6
  %23 = load ptr, ptr %9, align 8
  %24 = load i32, ptr %13, align 4
  %25 = mul nsw i32 %24, 2048
  %26 = load i32, ptr %12, align 4
  %27 = add nsw i32 %25, %26
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds float, ptr %23, i64 %28
  %30 = load float, ptr %29, align 4
  %31 = load ptr, ptr %10, align 8
  %32 = load i32, ptr %12, align 4
  %33 = mul nsw i32 %32, 2048
  %34 = load i32, ptr %12, align 4
  %35 = add nsw i32 %33, %34
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds float, ptr %31, i64 %36
  %38 = load float, ptr %37, align 4
  %39 = fdiv contract float %30, %38
  %40 = load ptr, ptr %11, align 8
  %41 = load i32, ptr %13, align 4
  %42 = mul nsw i32 %41, 2048
  %43 = load i32, ptr %12, align 4
  %44 = add nsw i32 %42, %43
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds float, ptr %40, i64 %45
  store float %39, ptr %46, align 4
  br label %47

47:                                               ; preds = %22, %6
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z19gramschmidt_kernel3iiPfS_S_i(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, i32 noundef %5) #1 {
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  store i32 %0, ptr %7, align 4
  store i32 %1, ptr %8, align 4
  store ptr %2, ptr %9, align 8
  store ptr %3, ptr %10, align 8
  store ptr %4, ptr %11, align 8
  store i32 %5, ptr %12, align 4
  %15 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %16 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %17 = mul i32 %15, %16
  %18 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %19 = add i32 %17, %18
  store i32 %19, ptr %13, align 4
  %20 = load i32, ptr %13, align 4
  %21 = load i32, ptr %12, align 4
  %22 = icmp sgt i32 %20, %21
  br i1 %22, label %23, label %105

23:                                               ; preds = %6
  %24 = load i32, ptr %13, align 4
  %25 = load i32, ptr %8, align 4
  %26 = icmp slt i32 %24, %25
  br i1 %26, label %27, label %105

27:                                               ; preds = %23
  %28 = load ptr, ptr %10, align 8
  %29 = load i32, ptr %12, align 4
  %30 = mul nsw i32 %29, 2048
  %31 = load i32, ptr %13, align 4
  %32 = add nsw i32 %30, %31
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds float, ptr %28, i64 %33
  store float 0.000000e+00, ptr %34, align 4
  store i32 0, ptr %14, align 4
  br label %35

35:                                               ; preds = %66, %27
  %36 = load i32, ptr %14, align 4
  %37 = load i32, ptr %7, align 4
  %38 = icmp slt i32 %36, %37
  br i1 %38, label %39, label %69

39:                                               ; preds = %35
  %40 = load ptr, ptr %11, align 8
  %41 = load i32, ptr %14, align 4
  %42 = mul nsw i32 %41, 2048
  %43 = load i32, ptr %12, align 4
  %44 = add nsw i32 %42, %43
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds float, ptr %40, i64 %45
  %47 = load float, ptr %46, align 4
  %48 = load ptr, ptr %9, align 8
  %49 = load i32, ptr %14, align 4
  %50 = mul nsw i32 %49, 2048
  %51 = load i32, ptr %13, align 4
  %52 = add nsw i32 %50, %51
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds float, ptr %48, i64 %53
  %55 = load float, ptr %54, align 4
  %56 = fmul contract float %47, %55
  %57 = load ptr, ptr %10, align 8
  %58 = load i32, ptr %12, align 4
  %59 = mul nsw i32 %58, 2048
  %60 = load i32, ptr %13, align 4
  %61 = add nsw i32 %59, %60
  %62 = sext i32 %61 to i64
  %63 = getelementptr inbounds float, ptr %57, i64 %62
  %64 = load float, ptr %63, align 4
  %65 = fadd contract float %64, %56
  store float %65, ptr %63, align 4
  br label %66

66:                                               ; preds = %39
  %67 = load i32, ptr %14, align 4
  %68 = add nsw i32 %67, 1
  store i32 %68, ptr %14, align 4
  br label %35, !llvm.loop !12

69:                                               ; preds = %35
  store i32 0, ptr %14, align 4
  br label %70

70:                                               ; preds = %101, %69
  %71 = load i32, ptr %14, align 4
  %72 = load i32, ptr %7, align 4
  %73 = icmp slt i32 %71, %72
  br i1 %73, label %74, label %104

74:                                               ; preds = %70
  %75 = load ptr, ptr %11, align 8
  %76 = load i32, ptr %14, align 4
  %77 = mul nsw i32 %76, 2048
  %78 = load i32, ptr %12, align 4
  %79 = add nsw i32 %77, %78
  %80 = sext i32 %79 to i64
  %81 = getelementptr inbounds float, ptr %75, i64 %80
  %82 = load float, ptr %81, align 4
  %83 = load ptr, ptr %10, align 8
  %84 = load i32, ptr %12, align 4
  %85 = mul nsw i32 %84, 2048
  %86 = load i32, ptr %13, align 4
  %87 = add nsw i32 %85, %86
  %88 = sext i32 %87 to i64
  %89 = getelementptr inbounds float, ptr %83, i64 %88
  %90 = load float, ptr %89, align 4
  %91 = fmul contract float %82, %90
  %92 = load ptr, ptr %9, align 8
  %93 = load i32, ptr %14, align 4
  %94 = mul nsw i32 %93, 2048
  %95 = load i32, ptr %13, align 4
  %96 = add nsw i32 %94, %95
  %97 = sext i32 %96 to i64
  %98 = getelementptr inbounds float, ptr %92, i64 %97
  %99 = load float, ptr %98, align 4
  %100 = fsub contract float %99, %91
  store float %100, ptr %98, align 4
  br label %101

101:                                              ; preds = %74
  %102 = load i32, ptr %14, align 4
  %103 = add nsw i32 %102, 1
  store i32 %103, ptr %14, align 4
  br label %70, !llvm.loop !13

104:                                              ; preds = %70
  br label %105

105:                                              ; preds = %104, %23, %6
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #2

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

attributes #0 = { convergent noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "uniform-work-group-size"="true" }
attributes #1 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "uniform-work-group-size"="true" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { convergent nounwind "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!nvvm.annotations = !{!4, !5, !6}
!llvm.ident = !{!7, !8}
!nvvmir.version = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z19gramschmidt_kernel1iiPfS_S_i}
!5 = !{ptr @_Z19gramschmidt_kernel2iiPfS_S_i}
!6 = !{ptr @_Z19gramschmidt_kernel3iiPfS_S_i}
!7 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!8 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!9 = !{i32 2, i32 0}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.mustprogress"}
!12 = distinct !{!12, !11}
!13 = distinct !{!13, !11}
