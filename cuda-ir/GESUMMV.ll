; ModuleID = 'GESUMMV/gesummv.cu'
source_filename = "GESUMMV/gesummv.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z14gesummv_kerneliffPfS_S_S_S_(i32 noundef %0, float noundef %1, float noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6, ptr noundef %7) #0 {
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
  %24 = load i32, ptr %17, align 4
  %25 = load i32, ptr %9, align 4
  %26 = icmp slt i32 %24, %25
  br i1 %26, label %27, label %96

27:                                               ; preds = %8
  store i32 0, ptr %18, align 4
  br label %28

28:                                               ; preds = %73, %27
  %29 = load i32, ptr %18, align 4
  %30 = load i32, ptr %9, align 4
  %31 = icmp slt i32 %29, %30
  br i1 %31, label %32, label %76

32:                                               ; preds = %28
  %33 = load ptr, ptr %12, align 8
  %34 = load i32, ptr %17, align 4
  %35 = mul nsw i32 %34, 4096
  %36 = load i32, ptr %18, align 4
  %37 = add nsw i32 %35, %36
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds float, ptr %33, i64 %38
  %40 = load float, ptr %39, align 4
  %41 = load ptr, ptr %15, align 8
  %42 = load i32, ptr %18, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %41, i64 %43
  %45 = load float, ptr %44, align 4
  %46 = fmul contract float %40, %45
  %47 = load ptr, ptr %14, align 8
  %48 = load i32, ptr %17, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds float, ptr %47, i64 %49
  %51 = load float, ptr %50, align 4
  %52 = fadd contract float %51, %46
  store float %52, ptr %50, align 4
  %53 = load ptr, ptr %13, align 8
  %54 = load i32, ptr %17, align 4
  %55 = mul nsw i32 %54, 4096
  %56 = load i32, ptr %18, align 4
  %57 = add nsw i32 %55, %56
  %58 = sext i32 %57 to i64
  %59 = getelementptr inbounds float, ptr %53, i64 %58
  %60 = load float, ptr %59, align 4
  %61 = load ptr, ptr %15, align 8
  %62 = load i32, ptr %18, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %61, i64 %63
  %65 = load float, ptr %64, align 4
  %66 = fmul contract float %60, %65
  %67 = load ptr, ptr %16, align 8
  %68 = load i32, ptr %17, align 4
  %69 = sext i32 %68 to i64
  %70 = getelementptr inbounds float, ptr %67, i64 %69
  %71 = load float, ptr %70, align 4
  %72 = fadd contract float %71, %66
  store float %72, ptr %70, align 4
  br label %73

73:                                               ; preds = %32
  %74 = load i32, ptr %18, align 4
  %75 = add nsw i32 %74, 1
  store i32 %75, ptr %18, align 4
  br label %28, !llvm.loop !8

76:                                               ; preds = %28
  %77 = load float, ptr %10, align 4
  %78 = load ptr, ptr %14, align 8
  %79 = load i32, ptr %17, align 4
  %80 = sext i32 %79 to i64
  %81 = getelementptr inbounds float, ptr %78, i64 %80
  %82 = load float, ptr %81, align 4
  %83 = fmul contract float %77, %82
  %84 = load float, ptr %11, align 4
  %85 = load ptr, ptr %16, align 8
  %86 = load i32, ptr %17, align 4
  %87 = sext i32 %86 to i64
  %88 = getelementptr inbounds float, ptr %85, i64 %87
  %89 = load float, ptr %88, align 4
  %90 = fmul contract float %84, %89
  %91 = fadd contract float %83, %90
  %92 = load ptr, ptr %16, align 8
  %93 = load i32, ptr %17, align 4
  %94 = sext i32 %93 to i64
  %95 = getelementptr inbounds float, ptr %92, i64 %94
  store float %91, ptr %95, align 4
  br label %96

96:                                               ; preds = %76, %8
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
!nvvm.annotations = !{!4}
!llvm.ident = !{!5, !6}
!nvvmir.version = !{!7}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z14gesummv_kerneliffPfS_S_S_S_}
!5 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = !{i32 2, i32 0}
!8 = distinct !{!8, !9}
!9 = !{!"llvm.loop.mustprogress"}
