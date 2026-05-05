; ModuleID = 'SYRK/syrk.cu'
source_filename = "SYRK/syrk.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11syrk_kerneliiffPfS_(i32 noundef %0, i32 noundef %1, float noundef %2, float noundef %3, ptr noundef %4, ptr noundef %5) #0 {
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca float, align 4
  %10 = alloca float, align 4
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  store i32 %0, ptr %7, align 4
  store i32 %1, ptr %8, align 4
  store float %2, ptr %9, align 4
  store float %3, ptr %10, align 4
  store ptr %4, ptr %11, align 8
  store ptr %5, ptr %12, align 8
  %16 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %17 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %18 = mul i32 %16, %17
  %19 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %20 = add i32 %18, %19
  store i32 %20, ptr %13, align 4
  %21 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %22 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %23 = mul i32 %21, %22
  %24 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %25 = add i32 %23, %24
  store i32 %25, ptr %14, align 4
  %26 = load i32, ptr %14, align 4
  %27 = load i32, ptr %7, align 4
  %28 = icmp slt i32 %26, %27
  br i1 %28, label %29, label %81

29:                                               ; preds = %6
  %30 = load i32, ptr %13, align 4
  %31 = load i32, ptr %7, align 4
  %32 = icmp slt i32 %30, %31
  br i1 %32, label %33, label %81

33:                                               ; preds = %29
  %34 = load float, ptr %10, align 4
  %35 = load ptr, ptr %12, align 8
  %36 = load i32, ptr %14, align 4
  %37 = mul nsw i32 %36, 1024
  %38 = load i32, ptr %13, align 4
  %39 = add nsw i32 %37, %38
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds float, ptr %35, i64 %40
  %42 = load float, ptr %41, align 4
  %43 = fmul contract float %42, %34
  store float %43, ptr %41, align 4
  store i32 0, ptr %15, align 4
  br label %44

44:                                               ; preds = %77, %33
  %45 = load i32, ptr %15, align 4
  %46 = load i32, ptr %8, align 4
  %47 = icmp slt i32 %45, %46
  br i1 %47, label %48, label %80

48:                                               ; preds = %44
  %49 = load float, ptr %9, align 4
  %50 = load ptr, ptr %11, align 8
  %51 = load i32, ptr %14, align 4
  %52 = mul nsw i32 %51, 1024
  %53 = load i32, ptr %15, align 4
  %54 = add nsw i32 %52, %53
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds float, ptr %50, i64 %55
  %57 = load float, ptr %56, align 4
  %58 = fmul contract float %49, %57
  %59 = load ptr, ptr %11, align 8
  %60 = load i32, ptr %13, align 4
  %61 = mul nsw i32 %60, 1024
  %62 = load i32, ptr %15, align 4
  %63 = add nsw i32 %61, %62
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds float, ptr %59, i64 %64
  %66 = load float, ptr %65, align 4
  %67 = fmul contract float %58, %66
  %68 = load ptr, ptr %12, align 8
  %69 = load i32, ptr %14, align 4
  %70 = mul nsw i32 %69, 1024
  %71 = load i32, ptr %13, align 4
  %72 = add nsw i32 %70, %71
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds float, ptr %68, i64 %73
  %75 = load float, ptr %74, align 4
  %76 = fadd contract float %75, %67
  store float %76, ptr %74, align 4
  br label %77

77:                                               ; preds = %48
  %78 = load i32, ptr %15, align 4
  %79 = add nsw i32 %78, 1
  store i32 %79, ptr %15, align 4
  br label %44, !llvm.loop !8

80:                                               ; preds = %44
  br label %81

81:                                               ; preds = %80, %29, %6
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
!4 = !{ptr @_Z11syrk_kerneliiffPfS_}
!5 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = !{i32 2, i32 0}
!8 = distinct !{!8, !9}
!9 = !{!"llvm.loop.mustprogress"}
