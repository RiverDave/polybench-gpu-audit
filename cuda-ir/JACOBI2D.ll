; ModuleID = 'JACOBI2D/jacobi2D.cu'
source_filename = "JACOBI2D/jacobi2D.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z21runJacobiCUDA_kernel1iPfS_(i32 noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %9 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %10 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %11 = mul i32 %9, %10
  %12 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %13 = add i32 %11, %12
  store i32 %13, ptr %7, align 4
  %14 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %15 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %16 = mul i32 %14, %15
  %17 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %18 = add i32 %16, %17
  store i32 %18, ptr %8, align 4
  %19 = load i32, ptr %7, align 4
  %20 = icmp sge i32 %19, 1
  br i1 %20, label %21, label %91

21:                                               ; preds = %3
  %22 = load i32, ptr %7, align 4
  %23 = load i32, ptr %4, align 4
  %24 = sub nsw i32 %23, 1
  %25 = icmp slt i32 %22, %24
  br i1 %25, label %26, label %91

26:                                               ; preds = %21
  %27 = load i32, ptr %8, align 4
  %28 = icmp sge i32 %27, 1
  br i1 %28, label %29, label %91

29:                                               ; preds = %26
  %30 = load i32, ptr %8, align 4
  %31 = load i32, ptr %4, align 4
  %32 = sub nsw i32 %31, 1
  %33 = icmp slt i32 %30, %32
  br i1 %33, label %34, label %91

34:                                               ; preds = %29
  %35 = load ptr, ptr %5, align 8
  %36 = load i32, ptr %7, align 4
  %37 = mul nsw i32 %36, 1000
  %38 = load i32, ptr %8, align 4
  %39 = add nsw i32 %37, %38
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds float, ptr %35, i64 %40
  %42 = load float, ptr %41, align 4
  %43 = load ptr, ptr %5, align 8
  %44 = load i32, ptr %7, align 4
  %45 = mul nsw i32 %44, 1000
  %46 = load i32, ptr %8, align 4
  %47 = sub nsw i32 %46, 1
  %48 = add nsw i32 %45, %47
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds float, ptr %43, i64 %49
  %51 = load float, ptr %50, align 4
  %52 = fadd contract float %42, %51
  %53 = load ptr, ptr %5, align 8
  %54 = load i32, ptr %7, align 4
  %55 = mul nsw i32 %54, 1000
  %56 = load i32, ptr %8, align 4
  %57 = add nsw i32 1, %56
  %58 = add nsw i32 %55, %57
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds float, ptr %53, i64 %59
  %61 = load float, ptr %60, align 4
  %62 = fadd contract float %52, %61
  %63 = load ptr, ptr %5, align 8
  %64 = load i32, ptr %7, align 4
  %65 = add nsw i32 1, %64
  %66 = mul nsw i32 %65, 1000
  %67 = load i32, ptr %8, align 4
  %68 = add nsw i32 %66, %67
  %69 = sext i32 %68 to i64
  %70 = getelementptr inbounds float, ptr %63, i64 %69
  %71 = load float, ptr %70, align 4
  %72 = fadd contract float %62, %71
  %73 = load ptr, ptr %5, align 8
  %74 = load i32, ptr %7, align 4
  %75 = sub nsw i32 %74, 1
  %76 = mul nsw i32 %75, 1000
  %77 = load i32, ptr %8, align 4
  %78 = add nsw i32 %76, %77
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds float, ptr %73, i64 %79
  %81 = load float, ptr %80, align 4
  %82 = fadd contract float %72, %81
  %83 = fmul contract float 0x3FC99999A0000000, %82
  %84 = load ptr, ptr %6, align 8
  %85 = load i32, ptr %7, align 4
  %86 = mul nsw i32 %85, 1000
  %87 = load i32, ptr %8, align 4
  %88 = add nsw i32 %86, %87
  %89 = sext i32 %88 to i64
  %90 = getelementptr inbounds float, ptr %84, i64 %89
  store float %83, ptr %90, align 4
  br label %91

91:                                               ; preds = %34, %29, %26, %21, %3
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z21runJacobiCUDA_kernel2iPfS_(i32 noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %9 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %10 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %11 = mul i32 %9, %10
  %12 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %13 = add i32 %11, %12
  store i32 %13, ptr %7, align 4
  %14 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %15 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %16 = mul i32 %14, %15
  %17 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %18 = add i32 %16, %17
  store i32 %18, ptr %8, align 4
  %19 = load i32, ptr %7, align 4
  %20 = icmp sge i32 %19, 1
  br i1 %20, label %21, label %50

21:                                               ; preds = %3
  %22 = load i32, ptr %7, align 4
  %23 = load i32, ptr %4, align 4
  %24 = sub nsw i32 %23, 1
  %25 = icmp slt i32 %22, %24
  br i1 %25, label %26, label %50

26:                                               ; preds = %21
  %27 = load i32, ptr %8, align 4
  %28 = icmp sge i32 %27, 1
  br i1 %28, label %29, label %50

29:                                               ; preds = %26
  %30 = load i32, ptr %8, align 4
  %31 = load i32, ptr %4, align 4
  %32 = sub nsw i32 %31, 1
  %33 = icmp slt i32 %30, %32
  br i1 %33, label %34, label %50

34:                                               ; preds = %29
  %35 = load ptr, ptr %6, align 8
  %36 = load i32, ptr %7, align 4
  %37 = mul nsw i32 %36, 1000
  %38 = load i32, ptr %8, align 4
  %39 = add nsw i32 %37, %38
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds float, ptr %35, i64 %40
  %42 = load float, ptr %41, align 4
  %43 = load ptr, ptr %5, align 8
  %44 = load i32, ptr %7, align 4
  %45 = mul nsw i32 %44, 1000
  %46 = load i32, ptr %8, align 4
  %47 = add nsw i32 %45, %46
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds float, ptr %43, i64 %48
  store float %42, ptr %49, align 4
  br label %50

50:                                               ; preds = %34, %29, %26, %21, %3
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.y() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.y() #1

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
!4 = !{ptr @_Z21runJacobiCUDA_kernel1iPfS_}
!5 = !{ptr @_Z21runJacobiCUDA_kernel2iPfS_}
!6 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!7 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!8 = !{i32 2, i32 0}
