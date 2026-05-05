; ModuleID = 'COVAR/covariance.cu'
source_filename = "COVAR/covariance.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

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
  br label %24, !llvm.loop !10

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

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z13reduce_kerneliiPfS_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
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
  %16 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %17 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %18 = mul i32 %16, %17
  %19 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %20 = add i32 %18, %19
  store i32 %20, ptr %10, align 4
  %21 = load i32, ptr %10, align 4
  %22 = load i32, ptr %6, align 4
  %23 = icmp slt i32 %21, %22
  br i1 %23, label %24, label %43

24:                                               ; preds = %4
  %25 = load i32, ptr %9, align 4
  %26 = load i32, ptr %5, align 4
  %27 = icmp slt i32 %25, %26
  br i1 %27, label %28, label %43

28:                                               ; preds = %24
  %29 = load ptr, ptr %7, align 8
  %30 = load i32, ptr %9, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds float, ptr %29, i64 %31
  %33 = load float, ptr %32, align 4
  %34 = load ptr, ptr %8, align 8
  %35 = load i32, ptr %10, align 4
  %36 = mul nsw i32 %35, 2048
  %37 = load i32, ptr %9, align 4
  %38 = add nsw i32 %36, %37
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds float, ptr %34, i64 %39
  %41 = load float, ptr %40, align 4
  %42 = fsub contract float %41, %33
  store float %42, ptr %40, align 4
  br label %43

43:                                               ; preds = %28, %24, %4
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z12covar_kerneliiPfS_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
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
  %19 = icmp slt i32 %17, %18
  br i1 %19, label %20, label %88

20:                                               ; preds = %4
  %21 = load i32, ptr %9, align 4
  store i32 %21, ptr %11, align 4
  br label %22

22:                                               ; preds = %84, %20
  %23 = load i32, ptr %11, align 4
  %24 = load i32, ptr %5, align 4
  %25 = icmp slt i32 %23, %24
  br i1 %25, label %26, label %87

26:                                               ; preds = %22
  %27 = load ptr, ptr %7, align 8
  %28 = load i32, ptr %9, align 4
  %29 = mul nsw i32 %28, 2048
  %30 = load i32, ptr %11, align 4
  %31 = add nsw i32 %29, %30
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds float, ptr %27, i64 %32
  store float 0.000000e+00, ptr %33, align 4
  store i32 0, ptr %10, align 4
  br label %34

34:                                               ; preds = %65, %26
  %35 = load i32, ptr %10, align 4
  %36 = load i32, ptr %6, align 4
  %37 = icmp slt i32 %35, %36
  br i1 %37, label %38, label %68

38:                                               ; preds = %34
  %39 = load ptr, ptr %8, align 8
  %40 = load i32, ptr %10, align 4
  %41 = mul nsw i32 %40, 2048
  %42 = load i32, ptr %9, align 4
  %43 = add nsw i32 %41, %42
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds float, ptr %39, i64 %44
  %46 = load float, ptr %45, align 4
  %47 = load ptr, ptr %8, align 8
  %48 = load i32, ptr %10, align 4
  %49 = mul nsw i32 %48, 2048
  %50 = load i32, ptr %11, align 4
  %51 = add nsw i32 %49, %50
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds float, ptr %47, i64 %52
  %54 = load float, ptr %53, align 4
  %55 = fmul contract float %46, %54
  %56 = load ptr, ptr %7, align 8
  %57 = load i32, ptr %9, align 4
  %58 = mul nsw i32 %57, 2048
  %59 = load i32, ptr %11, align 4
  %60 = add nsw i32 %58, %59
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds float, ptr %56, i64 %61
  %63 = load float, ptr %62, align 4
  %64 = fadd contract float %63, %55
  store float %64, ptr %62, align 4
  br label %65

65:                                               ; preds = %38
  %66 = load i32, ptr %10, align 4
  %67 = add nsw i32 %66, 1
  store i32 %67, ptr %10, align 4
  br label %34, !llvm.loop !12

68:                                               ; preds = %34
  %69 = load ptr, ptr %7, align 8
  %70 = load i32, ptr %9, align 4
  %71 = mul nsw i32 %70, 2048
  %72 = load i32, ptr %11, align 4
  %73 = add nsw i32 %71, %72
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds float, ptr %69, i64 %74
  %76 = load float, ptr %75, align 4
  %77 = load ptr, ptr %7, align 8
  %78 = load i32, ptr %11, align 4
  %79 = mul nsw i32 %78, 2048
  %80 = load i32, ptr %9, align 4
  %81 = add nsw i32 %79, %80
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds float, ptr %77, i64 %82
  store float %76, ptr %83, align 4
  br label %84

84:                                               ; preds = %68
  %85 = load i32, ptr %11, align 4
  %86 = add nsw i32 %85, 1
  store i32 %86, ptr %11, align 4
  br label %22, !llvm.loop !13

87:                                               ; preds = %22
  br label %88

88:                                               ; preds = %87, %4
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
!4 = !{ptr @_Z11mean_kerneliiPfS_}
!5 = !{ptr @_Z13reduce_kerneliiPfS_}
!6 = !{ptr @_Z12covar_kerneliiPfS_}
!7 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!8 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!9 = !{i32 2, i32 0}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.mustprogress"}
!12 = distinct !{!12, !11}
!13 = distinct !{!13, !11}
