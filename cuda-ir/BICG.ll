; ModuleID = 'BICG/bicg.cu'
source_filename = "BICG/bicg.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z12bicg_kernel1iiPfS_S_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4) #0 {
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  store ptr %2, ptr %8, align 8
  store ptr %3, ptr %9, align 8
  store ptr %4, ptr %10, align 8
  %13 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %14 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %15 = mul i32 %13, %14
  %16 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %17 = add i32 %15, %16
  store i32 %17, ptr %11, align 4
  %18 = load i32, ptr %11, align 4
  %19 = load i32, ptr %7, align 4
  %20 = icmp slt i32 %18, %19
  br i1 %20, label %21, label %55

21:                                               ; preds = %5
  %22 = load ptr, ptr %10, align 8
  %23 = load i32, ptr %11, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds float, ptr %22, i64 %24
  store float 0.000000e+00, ptr %25, align 4
  store i32 0, ptr %12, align 4
  br label %26

26:                                               ; preds = %51, %21
  %27 = load i32, ptr %12, align 4
  %28 = load i32, ptr %6, align 4
  %29 = icmp slt i32 %27, %28
  br i1 %29, label %30, label %54

30:                                               ; preds = %26
  %31 = load ptr, ptr %9, align 8
  %32 = load i32, ptr %12, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds float, ptr %31, i64 %33
  %35 = load float, ptr %34, align 4
  %36 = load ptr, ptr %8, align 8
  %37 = load i32, ptr %12, align 4
  %38 = mul nsw i32 %37, 4096
  %39 = load i32, ptr %11, align 4
  %40 = add nsw i32 %38, %39
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds float, ptr %36, i64 %41
  %43 = load float, ptr %42, align 4
  %44 = fmul contract float %35, %43
  %45 = load ptr, ptr %10, align 8
  %46 = load i32, ptr %11, align 4
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds float, ptr %45, i64 %47
  %49 = load float, ptr %48, align 4
  %50 = fadd contract float %49, %44
  store float %50, ptr %48, align 4
  br label %51

51:                                               ; preds = %30
  %52 = load i32, ptr %12, align 4
  %53 = add nsw i32 %52, 1
  store i32 %53, ptr %12, align 4
  br label %26, !llvm.loop !9

54:                                               ; preds = %26
  br label %55

55:                                               ; preds = %54, %5
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z12bicg_kernel2iiPfS_S_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4) #0 {
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  store ptr %2, ptr %8, align 8
  store ptr %3, ptr %9, align 8
  store ptr %4, ptr %10, align 8
  %13 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %14 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %15 = mul i32 %13, %14
  %16 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %17 = add i32 %15, %16
  store i32 %17, ptr %11, align 4
  %18 = load i32, ptr %11, align 4
  %19 = load i32, ptr %6, align 4
  %20 = icmp slt i32 %18, %19
  br i1 %20, label %21, label %55

21:                                               ; preds = %5
  %22 = load ptr, ptr %10, align 8
  %23 = load i32, ptr %11, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds float, ptr %22, i64 %24
  store float 0.000000e+00, ptr %25, align 4
  store i32 0, ptr %12, align 4
  br label %26

26:                                               ; preds = %51, %21
  %27 = load i32, ptr %12, align 4
  %28 = load i32, ptr %7, align 4
  %29 = icmp slt i32 %27, %28
  br i1 %29, label %30, label %54

30:                                               ; preds = %26
  %31 = load ptr, ptr %8, align 8
  %32 = load i32, ptr %11, align 4
  %33 = mul nsw i32 %32, 4096
  %34 = load i32, ptr %12, align 4
  %35 = add nsw i32 %33, %34
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds float, ptr %31, i64 %36
  %38 = load float, ptr %37, align 4
  %39 = load ptr, ptr %9, align 8
  %40 = load i32, ptr %12, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds float, ptr %39, i64 %41
  %43 = load float, ptr %42, align 4
  %44 = fmul contract float %38, %43
  %45 = load ptr, ptr %10, align 8
  %46 = load i32, ptr %11, align 4
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds float, ptr %45, i64 %47
  %49 = load float, ptr %48, align 4
  %50 = fadd contract float %49, %44
  store float %50, ptr %48, align 4
  br label %51

51:                                               ; preds = %30
  %52 = load i32, ptr %12, align 4
  %53 = add nsw i32 %52, 1
  store i32 %53, ptr %12, align 4
  br label %26, !llvm.loop !11

54:                                               ; preds = %26
  br label %55

55:                                               ; preds = %54, %5
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
!nvvm.annotations = !{!4, !5}
!llvm.ident = !{!6, !7}
!nvvmir.version = !{!8}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z12bicg_kernel1iiPfS_S_}
!5 = !{ptr @_Z12bicg_kernel2iiPfS_S_}
!6 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!7 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!8 = !{i32 2, i32 0}
!9 = distinct !{!9, !10}
!10 = !{!"llvm.loop.mustprogress"}
!11 = distinct !{!11, !10}
