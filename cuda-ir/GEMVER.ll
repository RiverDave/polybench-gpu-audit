; ModuleID = 'GEMVER/gemver.cu'
source_filename = "GEMVER/gemver.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z14gemver_kernel1iffPfS_S_S_S_(i32 noundef %0, float noundef %1, float noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6, ptr noundef %7) #0 {
  %9 = alloca i32, align 4
  %10 = alloca float, align 4
  %11 = alloca float, align 4
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca ptr, align 8
  %15 = alloca ptr, align 8
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  store i32 %0, ptr %9, align 4
  store float %1, ptr %10, align 4
  store float %2, ptr %11, align 4
  store ptr %3, ptr %12, align 8
  store ptr %4, ptr %13, align 8
  store ptr %5, ptr %14, align 8
  store ptr %6, ptr %15, align 8
  store ptr %7, ptr %16, align 8
  %19 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %20 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %21 = mul i32 %19, %20
  %22 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %23 = add i32 %21, %22
  store i32 %23, ptr %17, align 4
  %24 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %25 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %26 = mul i32 %24, %25
  %27 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %28 = add i32 %26, %27
  store i32 %28, ptr %18, align 4
  %29 = load i32, ptr %18, align 4
  %30 = load i32, ptr %9, align 4
  %31 = icmp slt i32 %29, %30
  br i1 %31, label %32, label %69

32:                                               ; preds = %8
  %33 = load i32, ptr %17, align 4
  %34 = load i32, ptr %9, align 4
  %35 = icmp slt i32 %33, %34
  br i1 %35, label %36, label %69

36:                                               ; preds = %32
  %37 = load ptr, ptr %15, align 8
  %38 = load i32, ptr %18, align 4
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds float, ptr %37, i64 %39
  %41 = load float, ptr %40, align 4
  %42 = load ptr, ptr %13, align 8
  %43 = load i32, ptr %17, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds float, ptr %42, i64 %44
  %46 = load float, ptr %45, align 4
  %47 = fmul contract float %41, %46
  %48 = load ptr, ptr %16, align 8
  %49 = load i32, ptr %18, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds float, ptr %48, i64 %50
  %52 = load float, ptr %51, align 4
  %53 = load ptr, ptr %14, align 8
  %54 = load i32, ptr %17, align 4
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds float, ptr %53, i64 %55
  %57 = load float, ptr %56, align 4
  %58 = fmul contract float %52, %57
  %59 = fadd contract float %47, %58
  %60 = load ptr, ptr %12, align 8
  %61 = load i32, ptr %18, align 4
  %62 = mul nsw i32 %61, 4096
  %63 = load i32, ptr %17, align 4
  %64 = add nsw i32 %62, %63
  %65 = sext i32 %64 to i64
  %66 = getelementptr inbounds float, ptr %60, i64 %65
  %67 = load float, ptr %66, align 4
  %68 = fadd contract float %67, %59
  store float %68, ptr %66, align 4
  br label %69

69:                                               ; preds = %36, %32, %8
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z14gemver_kernel2iffPfS_S_S_(i32 noundef %0, float noundef %1, float noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6) #0 {
  %8 = alloca i32, align 4
  %9 = alloca float, align 4
  %10 = alloca float, align 4
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca ptr, align 8
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  store i32 %0, ptr %8, align 4
  store float %1, ptr %9, align 4
  store float %2, ptr %10, align 4
  store ptr %3, ptr %11, align 8
  store ptr %4, ptr %12, align 8
  store ptr %5, ptr %13, align 8
  store ptr %6, ptr %14, align 8
  %17 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %18 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %19 = mul i32 %17, %18
  %20 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %21 = add i32 %19, %20
  store i32 %21, ptr %15, align 4
  %22 = load i32, ptr %15, align 4
  %23 = load i32, ptr %8, align 4
  %24 = icmp slt i32 %22, %23
  br i1 %24, label %25, label %68

25:                                               ; preds = %7
  store i32 0, ptr %16, align 4
  br label %26

26:                                               ; preds = %53, %25
  %27 = load i32, ptr %16, align 4
  %28 = load i32, ptr %8, align 4
  %29 = icmp slt i32 %27, %28
  br i1 %29, label %30, label %56

30:                                               ; preds = %26
  %31 = load float, ptr %10, align 4
  %32 = load ptr, ptr %11, align 8
  %33 = load i32, ptr %16, align 4
  %34 = mul nsw i32 %33, 4096
  %35 = load i32, ptr %15, align 4
  %36 = add nsw i32 %34, %35
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds float, ptr %32, i64 %37
  %39 = load float, ptr %38, align 4
  %40 = fmul contract float %31, %39
  %41 = load ptr, ptr %13, align 8
  %42 = load i32, ptr %16, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %41, i64 %43
  %45 = load float, ptr %44, align 4
  %46 = fmul contract float %40, %45
  %47 = load ptr, ptr %12, align 8
  %48 = load i32, ptr %15, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds float, ptr %47, i64 %49
  %51 = load float, ptr %50, align 4
  %52 = fadd contract float %51, %46
  store float %52, ptr %50, align 4
  br label %53

53:                                               ; preds = %30
  %54 = load i32, ptr %16, align 4
  %55 = add nsw i32 %54, 1
  store i32 %55, ptr %16, align 4
  br label %26, !llvm.loop !10

56:                                               ; preds = %26
  %57 = load ptr, ptr %14, align 8
  %58 = load i32, ptr %15, align 4
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds float, ptr %57, i64 %59
  %61 = load float, ptr %60, align 4
  %62 = load ptr, ptr %12, align 8
  %63 = load i32, ptr %15, align 4
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds float, ptr %62, i64 %64
  %66 = load float, ptr %65, align 4
  %67 = fadd contract float %66, %61
  store float %67, ptr %65, align 4
  br label %68

68:                                               ; preds = %56, %7
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z14gemver_kernel3iffPfS_S_(i32 noundef %0, float noundef %1, float noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5) #0 {
  %7 = alloca i32, align 4
  %8 = alloca float, align 4
  %9 = alloca float, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  store i32 %0, ptr %7, align 4
  store float %1, ptr %8, align 4
  store float %2, ptr %9, align 4
  store ptr %3, ptr %10, align 8
  store ptr %4, ptr %11, align 8
  store ptr %5, ptr %12, align 8
  %15 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %16 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %17 = mul i32 %15, %16
  %18 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %19 = add i32 %17, %18
  store i32 %19, ptr %13, align 4
  %20 = load i32, ptr %13, align 4
  %21 = icmp sge i32 %20, 0
  br i1 %21, label %22, label %58

22:                                               ; preds = %6
  %23 = load i32, ptr %13, align 4
  %24 = load i32, ptr %7, align 4
  %25 = icmp slt i32 %23, %24
  br i1 %25, label %26, label %58

26:                                               ; preds = %22
  store i32 0, ptr %14, align 4
  br label %27

27:                                               ; preds = %54, %26
  %28 = load i32, ptr %14, align 4
  %29 = load i32, ptr %7, align 4
  %30 = icmp slt i32 %28, %29
  br i1 %30, label %31, label %57

31:                                               ; preds = %27
  %32 = load float, ptr %8, align 4
  %33 = load ptr, ptr %10, align 8
  %34 = load i32, ptr %13, align 4
  %35 = mul nsw i32 %34, 4096
  %36 = load i32, ptr %14, align 4
  %37 = add nsw i32 %35, %36
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds float, ptr %33, i64 %38
  %40 = load float, ptr %39, align 4
  %41 = fmul contract float %32, %40
  %42 = load ptr, ptr %11, align 8
  %43 = load i32, ptr %14, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds float, ptr %42, i64 %44
  %46 = load float, ptr %45, align 4
  %47 = fmul contract float %41, %46
  %48 = load ptr, ptr %12, align 8
  %49 = load i32, ptr %13, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds float, ptr %48, i64 %50
  %52 = load float, ptr %51, align 4
  %53 = fadd contract float %52, %47
  store float %53, ptr %51, align 4
  br label %54

54:                                               ; preds = %31
  %55 = load i32, ptr %14, align 4
  %56 = add nsw i32 %55, 1
  store i32 %56, ptr %14, align 4
  br label %27, !llvm.loop !12

57:                                               ; preds = %27
  br label %58

58:                                               ; preds = %57, %22, %6
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.y() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.y() #1

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx87,+sm_80" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3}
!nvvm.annotations = !{!4, !5, !6}
!llvm.ident = !{!7, !8}
!nvvmir.version = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z14gemver_kernel1iffPfS_S_S_S_}
!5 = !{ptr @_Z14gemver_kernel2iffPfS_S_S_}
!6 = !{ptr @_Z14gemver_kernel3iffPfS_S_}
!7 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!8 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!9 = !{i32 2, i32 0}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.mustprogress"}
!12 = distinct !{!12, !11}
