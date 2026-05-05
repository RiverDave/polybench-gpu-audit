; ModuleID = 'FDTD-2D/fdtd2d.cu'
source_filename = "FDTD-2D/fdtd2d.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z17fdtd_step1_kerneliiPfS_S_S_i(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, i32 noundef %6) #0 {
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  store i32 %0, ptr %8, align 4
  store i32 %1, ptr %9, align 4
  store ptr %2, ptr %10, align 8
  store ptr %3, ptr %11, align 8
  store ptr %4, ptr %12, align 8
  store ptr %5, ptr %13, align 8
  store i32 %6, ptr %14, align 4
  %17 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %18 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %19 = mul i32 %17, %18
  %20 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %21 = add i32 %19, %20
  store i32 %21, ptr %15, align 4
  %22 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %23 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %24 = mul i32 %22, %23
  %25 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %26 = add i32 %24, %25
  store i32 %26, ptr %16, align 4
  %27 = load i32, ptr %16, align 4
  %28 = load i32, ptr %8, align 4
  %29 = icmp slt i32 %27, %28
  br i1 %29, label %30, label %87

30:                                               ; preds = %7
  %31 = load i32, ptr %15, align 4
  %32 = load i32, ptr %9, align 4
  %33 = icmp slt i32 %31, %32
  br i1 %33, label %34, label %87

34:                                               ; preds = %30
  %35 = load i32, ptr %16, align 4
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %37, label %50

37:                                               ; preds = %34
  %38 = load ptr, ptr %10, align 8
  %39 = load i32, ptr %14, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds float, ptr %38, i64 %40
  %42 = load float, ptr %41, align 4
  %43 = load ptr, ptr %12, align 8
  %44 = load i32, ptr %16, align 4
  %45 = mul nsw i32 %44, 2048
  %46 = load i32, ptr %15, align 4
  %47 = add nsw i32 %45, %46
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds float, ptr %43, i64 %48
  store float %42, ptr %49, align 4
  br label %86

50:                                               ; preds = %34
  %51 = load ptr, ptr %12, align 8
  %52 = load i32, ptr %16, align 4
  %53 = mul nsw i32 %52, 2048
  %54 = load i32, ptr %15, align 4
  %55 = add nsw i32 %53, %54
  %56 = sext i32 %55 to i64
  %57 = getelementptr inbounds float, ptr %51, i64 %56
  %58 = load float, ptr %57, align 4
  %59 = load ptr, ptr %13, align 8
  %60 = load i32, ptr %16, align 4
  %61 = mul nsw i32 %60, 2048
  %62 = load i32, ptr %15, align 4
  %63 = add nsw i32 %61, %62
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds float, ptr %59, i64 %64
  %66 = load float, ptr %65, align 4
  %67 = load ptr, ptr %13, align 8
  %68 = load i32, ptr %16, align 4
  %69 = sub nsw i32 %68, 1
  %70 = mul nsw i32 %69, 2048
  %71 = load i32, ptr %15, align 4
  %72 = add nsw i32 %70, %71
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds float, ptr %67, i64 %73
  %75 = load float, ptr %74, align 4
  %76 = fsub contract float %66, %75
  %77 = fmul contract float 5.000000e-01, %76
  %78 = fsub contract float %58, %77
  %79 = load ptr, ptr %12, align 8
  %80 = load i32, ptr %16, align 4
  %81 = mul nsw i32 %80, 2048
  %82 = load i32, ptr %15, align 4
  %83 = add nsw i32 %81, %82
  %84 = sext i32 %83 to i64
  %85 = getelementptr inbounds float, ptr %79, i64 %84
  store float %78, ptr %85, align 4
  br label %86

86:                                               ; preds = %50, %37
  br label %87

87:                                               ; preds = %86, %30, %7
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z17fdtd_step2_kerneliiPfS_S_i(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, i32 noundef %5) #0 {
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
  %20 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %21 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %22 = mul i32 %20, %21
  %23 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %24 = add i32 %22, %23
  store i32 %24, ptr %14, align 4
  %25 = load i32, ptr %14, align 4
  %26 = load i32, ptr %7, align 4
  %27 = icmp slt i32 %25, %26
  br i1 %27, label %28, label %71

28:                                               ; preds = %6
  %29 = load i32, ptr %13, align 4
  %30 = load i32, ptr %8, align 4
  %31 = icmp slt i32 %29, %30
  br i1 %31, label %32, label %71

32:                                               ; preds = %28
  %33 = load i32, ptr %13, align 4
  %34 = icmp sgt i32 %33, 0
  br i1 %34, label %35, label %71

35:                                               ; preds = %32
  %36 = load ptr, ptr %9, align 8
  %37 = load i32, ptr %14, align 4
  %38 = mul nsw i32 %37, 2048
  %39 = load i32, ptr %13, align 4
  %40 = add nsw i32 %38, %39
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds float, ptr %36, i64 %41
  %43 = load float, ptr %42, align 4
  %44 = load ptr, ptr %11, align 8
  %45 = load i32, ptr %14, align 4
  %46 = mul nsw i32 %45, 2048
  %47 = load i32, ptr %13, align 4
  %48 = add nsw i32 %46, %47
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds float, ptr %44, i64 %49
  %51 = load float, ptr %50, align 4
  %52 = load ptr, ptr %11, align 8
  %53 = load i32, ptr %14, align 4
  %54 = mul nsw i32 %53, 2048
  %55 = load i32, ptr %13, align 4
  %56 = sub nsw i32 %55, 1
  %57 = add nsw i32 %54, %56
  %58 = sext i32 %57 to i64
  %59 = getelementptr inbounds float, ptr %52, i64 %58
  %60 = load float, ptr %59, align 4
  %61 = fsub contract float %51, %60
  %62 = fmul contract float 5.000000e-01, %61
  %63 = fsub contract float %43, %62
  %64 = load ptr, ptr %9, align 8
  %65 = load i32, ptr %14, align 4
  %66 = mul nsw i32 %65, 2048
  %67 = load i32, ptr %13, align 4
  %68 = add nsw i32 %66, %67
  %69 = sext i32 %68 to i64
  %70 = getelementptr inbounds float, ptr %64, i64 %69
  store float %63, ptr %70, align 4
  br label %71

71:                                               ; preds = %35, %32, %28, %6
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z17fdtd_step3_kerneliiPfS_S_i(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, i32 noundef %5) #0 {
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
  %20 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %21 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %22 = mul i32 %20, %21
  %23 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %24 = add i32 %22, %23
  store i32 %24, ptr %14, align 4
  %25 = load i32, ptr %14, align 4
  %26 = load i32, ptr %7, align 4
  %27 = sub nsw i32 %26, 1
  %28 = icmp slt i32 %25, %27
  br i1 %28, label %29, label %89

29:                                               ; preds = %6
  %30 = load i32, ptr %13, align 4
  %31 = load i32, ptr %8, align 4
  %32 = sub nsw i32 %31, 1
  %33 = icmp slt i32 %30, %32
  br i1 %33, label %34, label %89

34:                                               ; preds = %29
  %35 = load ptr, ptr %11, align 8
  %36 = load i32, ptr %14, align 4
  %37 = mul nsw i32 %36, 2048
  %38 = load i32, ptr %13, align 4
  %39 = add nsw i32 %37, %38
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds float, ptr %35, i64 %40
  %42 = load float, ptr %41, align 4
  %43 = load ptr, ptr %9, align 8
  %44 = load i32, ptr %14, align 4
  %45 = mul nsw i32 %44, 2048
  %46 = load i32, ptr %13, align 4
  %47 = add nsw i32 %46, 1
  %48 = add nsw i32 %45, %47
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds float, ptr %43, i64 %49
  %51 = load float, ptr %50, align 4
  %52 = load ptr, ptr %9, align 8
  %53 = load i32, ptr %14, align 4
  %54 = mul nsw i32 %53, 2048
  %55 = load i32, ptr %13, align 4
  %56 = add nsw i32 %54, %55
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds float, ptr %52, i64 %57
  %59 = load float, ptr %58, align 4
  %60 = fsub contract float %51, %59
  %61 = load ptr, ptr %10, align 8
  %62 = load i32, ptr %14, align 4
  %63 = add nsw i32 %62, 1
  %64 = mul nsw i32 %63, 2048
  %65 = load i32, ptr %13, align 4
  %66 = add nsw i32 %64, %65
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds float, ptr %61, i64 %67
  %69 = load float, ptr %68, align 4
  %70 = fadd contract float %60, %69
  %71 = load ptr, ptr %10, align 8
  %72 = load i32, ptr %14, align 4
  %73 = mul nsw i32 %72, 2048
  %74 = load i32, ptr %13, align 4
  %75 = add nsw i32 %73, %74
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds float, ptr %71, i64 %76
  %78 = load float, ptr %77, align 4
  %79 = fsub contract float %70, %78
  %80 = fmul contract float 0x3FE6666660000000, %79
  %81 = fsub contract float %42, %80
  %82 = load ptr, ptr %11, align 8
  %83 = load i32, ptr %14, align 4
  %84 = mul nsw i32 %83, 2048
  %85 = load i32, ptr %13, align 4
  %86 = add nsw i32 %84, %85
  %87 = sext i32 %86 to i64
  %88 = getelementptr inbounds float, ptr %82, i64 %87
  store float %81, ptr %88, align 4
  br label %89

89:                                               ; preds = %34, %29, %6
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
!4 = !{ptr @_Z17fdtd_step1_kerneliiPfS_S_S_i}
!5 = !{ptr @_Z17fdtd_step2_kerneliiPfS_S_i}
!6 = !{ptr @_Z17fdtd_step3_kerneliiPfS_S_i}
!7 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!8 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!9 = !{i32 2, i32 0}
