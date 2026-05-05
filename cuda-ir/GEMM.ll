; ModuleID = 'GEMM/gemm.cu'
source_filename = "GEMM/gemm.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11gemm_kerneliiiffPfS_S_(i32 noundef %0, i32 noundef %1, i32 noundef %2, float noundef %3, float noundef %4, ptr noundef %5, ptr noundef %6, ptr noundef %7) #0 {
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca float, align 4
  %13 = alloca float, align 4
  %14 = alloca ptr, align 8
  %15 = alloca ptr, align 8
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  store i32 %0, ptr %9, align 4
  store i32 %1, ptr %10, align 4
  store i32 %2, ptr %11, align 4
  store float %3, ptr %12, align 4
  store float %4, ptr %13, align 4
  store ptr %5, ptr %14, align 8
  store ptr %6, ptr %15, align 8
  store ptr %7, ptr %16, align 8
  %20 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %21 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %22 = mul i32 %20, %21
  %23 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %24 = add i32 %22, %23
  store i32 %24, ptr %17, align 4
  %25 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %26 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %27 = mul i32 %25, %26
  %28 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %29 = add i32 %27, %28
  store i32 %29, ptr %18, align 4
  %30 = load i32, ptr %18, align 4
  %31 = load i32, ptr %9, align 4
  %32 = icmp slt i32 %30, %31
  br i1 %32, label %33, label %85

33:                                               ; preds = %8
  %34 = load i32, ptr %17, align 4
  %35 = load i32, ptr %10, align 4
  %36 = icmp slt i32 %34, %35
  br i1 %36, label %37, label %85

37:                                               ; preds = %33
  %38 = load float, ptr %13, align 4
  %39 = load ptr, ptr %16, align 8
  %40 = load i32, ptr %18, align 4
  %41 = mul nsw i32 %40, 512
  %42 = load i32, ptr %17, align 4
  %43 = add nsw i32 %41, %42
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds float, ptr %39, i64 %44
  %46 = load float, ptr %45, align 4
  %47 = fmul contract float %46, %38
  store float %47, ptr %45, align 4
  store i32 0, ptr %19, align 4
  br label %48

48:                                               ; preds = %81, %37
  %49 = load i32, ptr %19, align 4
  %50 = load i32, ptr %11, align 4
  %51 = icmp slt i32 %49, %50
  br i1 %51, label %52, label %84

52:                                               ; preds = %48
  %53 = load float, ptr %12, align 4
  %54 = load ptr, ptr %14, align 8
  %55 = load i32, ptr %18, align 4
  %56 = mul nsw i32 %55, 512
  %57 = load i32, ptr %19, align 4
  %58 = add nsw i32 %56, %57
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds float, ptr %54, i64 %59
  %61 = load float, ptr %60, align 4
  %62 = fmul contract float %53, %61
  %63 = load ptr, ptr %15, align 8
  %64 = load i32, ptr %19, align 4
  %65 = mul nsw i32 %64, 512
  %66 = load i32, ptr %17, align 4
  %67 = add nsw i32 %65, %66
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds float, ptr %63, i64 %68
  %70 = load float, ptr %69, align 4
  %71 = fmul contract float %62, %70
  %72 = load ptr, ptr %16, align 8
  %73 = load i32, ptr %18, align 4
  %74 = mul nsw i32 %73, 512
  %75 = load i32, ptr %17, align 4
  %76 = add nsw i32 %74, %75
  %77 = sext i32 %76 to i64
  %78 = getelementptr inbounds float, ptr %72, i64 %77
  %79 = load float, ptr %78, align 4
  %80 = fadd contract float %79, %71
  store float %80, ptr %78, align 4
  br label %81

81:                                               ; preds = %52
  %82 = load i32, ptr %19, align 4
  %83 = add nsw i32 %82, 1
  store i32 %83, ptr %19, align 4
  br label %48, !llvm.loop !8

84:                                               ; preds = %48
  br label %85

85:                                               ; preds = %84, %33, %8
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
!nvvm.annotations = !{!4}
!llvm.ident = !{!5, !6}
!nvvmir.version = !{!7}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z11gemm_kerneliiiffPfS_S_}
!5 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = !{i32 2, i32 0}
!8 = distinct !{!8, !9}
!9 = !{!"llvm.loop.mustprogress"}
