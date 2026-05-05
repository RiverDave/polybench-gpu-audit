; ModuleID = 'SYR2K/syr2k.cu'
source_filename = "SYR2K/syr2k.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z12syr2k_kerneliiffPfS_S_(i32 noundef %0, i32 noundef %1, float noundef %2, float noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6) #0 {
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca float, align 4
  %11 = alloca float, align 4
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca ptr, align 8
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  store i32 %0, ptr %8, align 4
  store i32 %1, ptr %9, align 4
  store float %2, ptr %10, align 4
  store float %3, ptr %11, align 4
  store ptr %4, ptr %12, align 8
  store ptr %5, ptr %13, align 8
  store ptr %6, ptr %14, align 8
  %18 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %19 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %20 = mul i32 %18, %19
  %21 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %22 = add i32 %20, %21
  store i32 %22, ptr %15, align 4
  %23 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %24 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %25 = mul i32 %23, %24
  %26 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %27 = add i32 %25, %26
  store i32 %27, ptr %16, align 4
  %28 = load i32, ptr %16, align 4
  %29 = icmp slt i32 %28, 1024
  br i1 %29, label %30, label %100

30:                                               ; preds = %7
  %31 = load i32, ptr %15, align 4
  %32 = icmp slt i32 %31, 1024
  br i1 %32, label %33, label %100

33:                                               ; preds = %30
  %34 = load float, ptr %11, align 4
  %35 = load ptr, ptr %14, align 8
  %36 = load i32, ptr %16, align 4
  %37 = mul nsw i32 %36, 1024
  %38 = load i32, ptr %15, align 4
  %39 = add nsw i32 %37, %38
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds float, ptr %35, i64 %40
  %42 = load float, ptr %41, align 4
  %43 = fmul contract float %42, %34
  store float %43, ptr %41, align 4
  store i32 0, ptr %17, align 4
  br label %44

44:                                               ; preds = %96, %33
  %45 = load i32, ptr %17, align 4
  %46 = icmp slt i32 %45, 1024
  br i1 %46, label %47, label %99

47:                                               ; preds = %44
  %48 = load float, ptr %10, align 4
  %49 = load ptr, ptr %12, align 8
  %50 = load i32, ptr %16, align 4
  %51 = mul nsw i32 %50, 1024
  %52 = load i32, ptr %17, align 4
  %53 = add nsw i32 %51, %52
  %54 = sext i32 %53 to i64
  %55 = getelementptr inbounds float, ptr %49, i64 %54
  %56 = load float, ptr %55, align 4
  %57 = fmul contract float %48, %56
  %58 = load ptr, ptr %13, align 8
  %59 = load i32, ptr %15, align 4
  %60 = mul nsw i32 %59, 1024
  %61 = load i32, ptr %17, align 4
  %62 = add nsw i32 %60, %61
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %58, i64 %63
  %65 = load float, ptr %64, align 4
  %66 = fmul contract float %57, %65
  %67 = load float, ptr %10, align 4
  %68 = load ptr, ptr %13, align 8
  %69 = load i32, ptr %16, align 4
  %70 = mul nsw i32 %69, 1024
  %71 = load i32, ptr %17, align 4
  %72 = add nsw i32 %70, %71
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds float, ptr %68, i64 %73
  %75 = load float, ptr %74, align 4
  %76 = fmul contract float %67, %75
  %77 = load ptr, ptr %12, align 8
  %78 = load i32, ptr %15, align 4
  %79 = mul nsw i32 %78, 1024
  %80 = load i32, ptr %17, align 4
  %81 = add nsw i32 %79, %80
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds float, ptr %77, i64 %82
  %84 = load float, ptr %83, align 4
  %85 = fmul contract float %76, %84
  %86 = fadd contract float %66, %85
  %87 = load ptr, ptr %14, align 8
  %88 = load i32, ptr %16, align 4
  %89 = mul nsw i32 %88, 1024
  %90 = load i32, ptr %15, align 4
  %91 = add nsw i32 %89, %90
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds float, ptr %87, i64 %92
  %94 = load float, ptr %93, align 4
  %95 = fadd contract float %94, %86
  store float %95, ptr %93, align 4
  br label %96

96:                                               ; preds = %47
  %97 = load i32, ptr %17, align 4
  %98 = add nsw i32 %97, 1
  store i32 %98, ptr %17, align 4
  br label %44, !llvm.loop !8

99:                                               ; preds = %44
  br label %100

100:                                              ; preds = %99, %30, %7
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
!4 = !{ptr @_Z12syr2k_kerneliiffPfS_S_}
!5 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = !{i32 2, i32 0}
!8 = distinct !{!8, !9}
!9 = !{!"llvm.loop.mustprogress"}
