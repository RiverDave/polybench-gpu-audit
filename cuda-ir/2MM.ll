; ModuleID = '2MM/2mm.cu'
source_filename = "2MM/2mm.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11mm2_kernel1iiiiffPfS_S_(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, float noundef %4, float noundef %5, ptr noundef %6, ptr noundef %7, ptr noundef %8) #0 {
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca float, align 4
  %15 = alloca float, align 4
  %16 = alloca ptr, align 8
  %17 = alloca ptr, align 8
  %18 = alloca ptr, align 8
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  %21 = alloca i32, align 4
  store i32 %0, ptr %10, align 4
  store i32 %1, ptr %11, align 4
  store i32 %2, ptr %12, align 4
  store i32 %3, ptr %13, align 4
  store float %4, ptr %14, align 4
  store float %5, ptr %15, align 4
  store ptr %6, ptr %16, align 8
  store ptr %7, ptr %17, align 8
  store ptr %8, ptr %18, align 8
  %22 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %23 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %24 = mul i32 %22, %23
  %25 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %26 = add i32 %24, %25
  store i32 %26, ptr %19, align 4
  %27 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %28 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %29 = mul i32 %27, %28
  %30 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %31 = add i32 %29, %30
  store i32 %31, ptr %20, align 4
  %32 = load i32, ptr %20, align 4
  %33 = load i32, ptr %10, align 4
  %34 = icmp slt i32 %32, %33
  br i1 %34, label %35, label %84

35:                                               ; preds = %9
  %36 = load i32, ptr %19, align 4
  %37 = load i32, ptr %11, align 4
  %38 = icmp slt i32 %36, %37
  br i1 %38, label %39, label %84

39:                                               ; preds = %35
  %40 = load ptr, ptr %16, align 8
  %41 = load i32, ptr %20, align 4
  %42 = mul nsw i32 %41, 1024
  %43 = load i32, ptr %19, align 4
  %44 = add nsw i32 %42, %43
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds float, ptr %40, i64 %45
  store float 0.000000e+00, ptr %46, align 4
  store i32 0, ptr %21, align 4
  br label %47

47:                                               ; preds = %80, %39
  %48 = load i32, ptr %21, align 4
  %49 = load i32, ptr %12, align 4
  %50 = icmp slt i32 %48, %49
  br i1 %50, label %51, label %83

51:                                               ; preds = %47
  %52 = load float, ptr %14, align 4
  %53 = load ptr, ptr %17, align 8
  %54 = load i32, ptr %20, align 4
  %55 = mul nsw i32 %54, 1024
  %56 = load i32, ptr %21, align 4
  %57 = add nsw i32 %55, %56
  %58 = sext i32 %57 to i64
  %59 = getelementptr inbounds float, ptr %53, i64 %58
  %60 = load float, ptr %59, align 4
  %61 = fmul contract float %52, %60
  %62 = load ptr, ptr %18, align 8
  %63 = load i32, ptr %21, align 4
  %64 = mul nsw i32 %63, 1024
  %65 = load i32, ptr %19, align 4
  %66 = add nsw i32 %64, %65
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds float, ptr %62, i64 %67
  %69 = load float, ptr %68, align 4
  %70 = fmul contract float %61, %69
  %71 = load ptr, ptr %16, align 8
  %72 = load i32, ptr %20, align 4
  %73 = mul nsw i32 %72, 1024
  %74 = load i32, ptr %19, align 4
  %75 = add nsw i32 %73, %74
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds float, ptr %71, i64 %76
  %78 = load float, ptr %77, align 4
  %79 = fadd contract float %78, %70
  store float %79, ptr %77, align 4
  br label %80

80:                                               ; preds = %51
  %81 = load i32, ptr %21, align 4
  %82 = add nsw i32 %81, 1
  store i32 %82, ptr %21, align 4
  br label %47, !llvm.loop !9

83:                                               ; preds = %47
  br label %84

84:                                               ; preds = %83, %35, %9
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11mm2_kernel2iiiiffPfS_S_(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, float noundef %4, float noundef %5, ptr noundef %6, ptr noundef %7, ptr noundef %8) #0 {
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca float, align 4
  %15 = alloca float, align 4
  %16 = alloca ptr, align 8
  %17 = alloca ptr, align 8
  %18 = alloca ptr, align 8
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  %21 = alloca i32, align 4
  store i32 %0, ptr %10, align 4
  store i32 %1, ptr %11, align 4
  store i32 %2, ptr %12, align 4
  store i32 %3, ptr %13, align 4
  store float %4, ptr %14, align 4
  store float %5, ptr %15, align 4
  store ptr %6, ptr %16, align 8
  store ptr %7, ptr %17, align 8
  store ptr %8, ptr %18, align 8
  %22 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %23 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %24 = mul i32 %22, %23
  %25 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %26 = add i32 %24, %25
  store i32 %26, ptr %19, align 4
  %27 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %28 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %29 = mul i32 %27, %28
  %30 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %31 = add i32 %29, %30
  store i32 %31, ptr %20, align 4
  %32 = load i32, ptr %20, align 4
  %33 = load i32, ptr %10, align 4
  %34 = icmp slt i32 %32, %33
  br i1 %34, label %35, label %85

35:                                               ; preds = %9
  %36 = load i32, ptr %19, align 4
  %37 = load i32, ptr %13, align 4
  %38 = icmp slt i32 %36, %37
  br i1 %38, label %39, label %85

39:                                               ; preds = %35
  %40 = load float, ptr %15, align 4
  %41 = load ptr, ptr %18, align 8
  %42 = load i32, ptr %20, align 4
  %43 = mul nsw i32 %42, 1024
  %44 = load i32, ptr %19, align 4
  %45 = add nsw i32 %43, %44
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds float, ptr %41, i64 %46
  %48 = load float, ptr %47, align 4
  %49 = fmul contract float %48, %40
  store float %49, ptr %47, align 4
  store i32 0, ptr %21, align 4
  br label %50

50:                                               ; preds = %81, %39
  %51 = load i32, ptr %21, align 4
  %52 = load i32, ptr %11, align 4
  %53 = icmp slt i32 %51, %52
  br i1 %53, label %54, label %84

54:                                               ; preds = %50
  %55 = load ptr, ptr %16, align 8
  %56 = load i32, ptr %20, align 4
  %57 = mul nsw i32 %56, 1024
  %58 = load i32, ptr %21, align 4
  %59 = add nsw i32 %57, %58
  %60 = sext i32 %59 to i64
  %61 = getelementptr inbounds float, ptr %55, i64 %60
  %62 = load float, ptr %61, align 4
  %63 = load ptr, ptr %17, align 8
  %64 = load i32, ptr %21, align 4
  %65 = mul nsw i32 %64, 1024
  %66 = load i32, ptr %19, align 4
  %67 = add nsw i32 %65, %66
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds float, ptr %63, i64 %68
  %70 = load float, ptr %69, align 4
  %71 = fmul contract float %62, %70
  %72 = load ptr, ptr %18, align 8
  %73 = load i32, ptr %20, align 4
  %74 = mul nsw i32 %73, 1024
  %75 = load i32, ptr %19, align 4
  %76 = add nsw i32 %74, %75
  %77 = sext i32 %76 to i64
  %78 = getelementptr inbounds float, ptr %72, i64 %77
  %79 = load float, ptr %78, align 4
  %80 = fadd contract float %79, %71
  store float %80, ptr %78, align 4
  br label %81

81:                                               ; preds = %54
  %82 = load i32, ptr %21, align 4
  %83 = add nsw i32 %82, 1
  store i32 %83, ptr %21, align 4
  br label %50, !llvm.loop !11

84:                                               ; preds = %50
  br label %85

85:                                               ; preds = %84, %35, %9
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
!nvvm.annotations = !{!4, !5}
!llvm.ident = !{!6, !7}
!nvvmir.version = !{!8}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 8]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{ptr @_Z11mm2_kernel1iiiiffPfS_S_}
!5 = !{ptr @_Z11mm2_kernel2iiiiffPfS_S_}
!6 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!7 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!8 = !{i32 2, i32 0}
!9 = distinct !{!9, !10}
!10 = !{!"llvm.loop.mustprogress"}
!11 = distinct !{!11, !10}
