; ModuleID = '3MM/3mm.cu'
source_filename = "3MM/3mm.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11mm3_kernel1iiiiiPfS_S_(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, ptr noundef %5, ptr noundef %6, ptr noundef %7) #0 {
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca ptr, align 8
  %15 = alloca ptr, align 8
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  store i32 %0, ptr %9, align 4
  store i32 %1, ptr %10, align 4
  store i32 %2, ptr %11, align 4
  store i32 %3, ptr %12, align 4
  store i32 %4, ptr %13, align 4
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
  br i1 %32, label %33, label %80

33:                                               ; preds = %8
  %34 = load i32, ptr %17, align 4
  %35 = load i32, ptr %10, align 4
  %36 = icmp slt i32 %34, %35
  br i1 %36, label %37, label %80

37:                                               ; preds = %33
  %38 = load ptr, ptr %16, align 8
  %39 = load i32, ptr %18, align 4
  %40 = mul nsw i32 %39, 512
  %41 = load i32, ptr %17, align 4
  %42 = add nsw i32 %40, %41
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %38, i64 %43
  store float 0.000000e+00, ptr %44, align 4
  store i32 0, ptr %19, align 4
  br label %45

45:                                               ; preds = %76, %37
  %46 = load i32, ptr %19, align 4
  %47 = load i32, ptr %11, align 4
  %48 = icmp slt i32 %46, %47
  br i1 %48, label %49, label %79

49:                                               ; preds = %45
  %50 = load ptr, ptr %14, align 8
  %51 = load i32, ptr %18, align 4
  %52 = mul nsw i32 %51, 512
  %53 = load i32, ptr %19, align 4
  %54 = add nsw i32 %52, %53
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds float, ptr %50, i64 %55
  %57 = load float, ptr %56, align 4
  %58 = load ptr, ptr %15, align 8
  %59 = load i32, ptr %19, align 4
  %60 = mul nsw i32 %59, 512
  %61 = load i32, ptr %17, align 4
  %62 = add nsw i32 %60, %61
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %58, i64 %63
  %65 = load float, ptr %64, align 4
  %66 = fmul contract float %57, %65
  %67 = load ptr, ptr %16, align 8
  %68 = load i32, ptr %18, align 4
  %69 = mul nsw i32 %68, 512
  %70 = load i32, ptr %17, align 4
  %71 = add nsw i32 %69, %70
  %72 = sext i32 %71 to i64
  %73 = getelementptr inbounds float, ptr %67, i64 %72
  %74 = load float, ptr %73, align 4
  %75 = fadd contract float %74, %66
  store float %75, ptr %73, align 4
  br label %76

76:                                               ; preds = %49
  %77 = load i32, ptr %19, align 4
  %78 = add nsw i32 %77, 1
  store i32 %78, ptr %19, align 4
  br label %45, !llvm.loop !10

79:                                               ; preds = %45
  br label %80

80:                                               ; preds = %79, %33, %8
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11mm3_kernel2iiiiiPfS_S_(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, ptr noundef %5, ptr noundef %6, ptr noundef %7) #0 {
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca ptr, align 8
  %15 = alloca ptr, align 8
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  store i32 %0, ptr %9, align 4
  store i32 %1, ptr %10, align 4
  store i32 %2, ptr %11, align 4
  store i32 %3, ptr %12, align 4
  store i32 %4, ptr %13, align 4
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
  %31 = load i32, ptr %10, align 4
  %32 = icmp slt i32 %30, %31
  br i1 %32, label %33, label %80

33:                                               ; preds = %8
  %34 = load i32, ptr %17, align 4
  %35 = load i32, ptr %12, align 4
  %36 = icmp slt i32 %34, %35
  br i1 %36, label %37, label %80

37:                                               ; preds = %33
  %38 = load ptr, ptr %16, align 8
  %39 = load i32, ptr %18, align 4
  %40 = mul nsw i32 %39, 512
  %41 = load i32, ptr %17, align 4
  %42 = add nsw i32 %40, %41
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %38, i64 %43
  store float 0.000000e+00, ptr %44, align 4
  store i32 0, ptr %19, align 4
  br label %45

45:                                               ; preds = %76, %37
  %46 = load i32, ptr %19, align 4
  %47 = load i32, ptr %13, align 4
  %48 = icmp slt i32 %46, %47
  br i1 %48, label %49, label %79

49:                                               ; preds = %45
  %50 = load ptr, ptr %14, align 8
  %51 = load i32, ptr %18, align 4
  %52 = mul nsw i32 %51, 512
  %53 = load i32, ptr %19, align 4
  %54 = add nsw i32 %52, %53
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds float, ptr %50, i64 %55
  %57 = load float, ptr %56, align 4
  %58 = load ptr, ptr %15, align 8
  %59 = load i32, ptr %19, align 4
  %60 = mul nsw i32 %59, 512
  %61 = load i32, ptr %17, align 4
  %62 = add nsw i32 %60, %61
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %58, i64 %63
  %65 = load float, ptr %64, align 4
  %66 = fmul contract float %57, %65
  %67 = load ptr, ptr %16, align 8
  %68 = load i32, ptr %18, align 4
  %69 = mul nsw i32 %68, 512
  %70 = load i32, ptr %17, align 4
  %71 = add nsw i32 %69, %70
  %72 = sext i32 %71 to i64
  %73 = getelementptr inbounds float, ptr %67, i64 %72
  %74 = load float, ptr %73, align 4
  %75 = fadd contract float %74, %66
  store float %75, ptr %73, align 4
  br label %76

76:                                               ; preds = %49
  %77 = load i32, ptr %19, align 4
  %78 = add nsw i32 %77, 1
  store i32 %78, ptr %19, align 4
  br label %45, !llvm.loop !12

79:                                               ; preds = %45
  br label %80

80:                                               ; preds = %79, %33, %8
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z11mm3_kernel3iiiiiPfS_S_(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, ptr noundef %5, ptr noundef %6, ptr noundef %7) #0 {
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca ptr, align 8
  %15 = alloca ptr, align 8
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  store i32 %0, ptr %9, align 4
  store i32 %1, ptr %10, align 4
  store i32 %2, ptr %11, align 4
  store i32 %3, ptr %12, align 4
  store i32 %4, ptr %13, align 4
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
  br i1 %32, label %33, label %80

33:                                               ; preds = %8
  %34 = load i32, ptr %17, align 4
  %35 = load i32, ptr %12, align 4
  %36 = icmp slt i32 %34, %35
  br i1 %36, label %37, label %80

37:                                               ; preds = %33
  %38 = load ptr, ptr %16, align 8
  %39 = load i32, ptr %18, align 4
  %40 = mul nsw i32 %39, 512
  %41 = load i32, ptr %17, align 4
  %42 = add nsw i32 %40, %41
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds float, ptr %38, i64 %43
  store float 0.000000e+00, ptr %44, align 4
  store i32 0, ptr %19, align 4
  br label %45

45:                                               ; preds = %76, %37
  %46 = load i32, ptr %19, align 4
  %47 = load i32, ptr %10, align 4
  %48 = icmp slt i32 %46, %47
  br i1 %48, label %49, label %79

49:                                               ; preds = %45
  %50 = load ptr, ptr %14, align 8
  %51 = load i32, ptr %18, align 4
  %52 = mul nsw i32 %51, 512
  %53 = load i32, ptr %19, align 4
  %54 = add nsw i32 %52, %53
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds float, ptr %50, i64 %55
  %57 = load float, ptr %56, align 4
  %58 = load ptr, ptr %15, align 8
  %59 = load i32, ptr %19, align 4
  %60 = mul nsw i32 %59, 512
  %61 = load i32, ptr %17, align 4
  %62 = add nsw i32 %60, %61
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, ptr %58, i64 %63
  %65 = load float, ptr %64, align 4
  %66 = fmul contract float %57, %65
  %67 = load ptr, ptr %16, align 8
  %68 = load i32, ptr %18, align 4
  %69 = mul nsw i32 %68, 512
  %70 = load i32, ptr %17, align 4
  %71 = add nsw i32 %69, %70
  %72 = sext i32 %71 to i64
  %73 = getelementptr inbounds float, ptr %67, i64 %72
  %74 = load float, ptr %73, align 4
  %75 = fadd contract float %74, %66
  store float %75, ptr %73, align 4
  br label %76

76:                                               ; preds = %49
  %77 = load i32, ptr %19, align 4
  %78 = add nsw i32 %77, 1
  store i32 %78, ptr %19, align 4
  br label %45, !llvm.loop !13

79:                                               ; preds = %45
  br label %80

80:                                               ; preds = %79, %33, %8
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
!4 = !{ptr @_Z11mm3_kernel1iiiiiPfS_S_}
!5 = !{ptr @_Z11mm3_kernel2iiiiiPfS_S_}
!6 = !{ptr @_Z11mm3_kernel3iiiiiPfS_S_}
!7 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!8 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!9 = !{i32 2, i32 0}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.mustprogress"}
!12 = distinct !{!12, !11}
!13 = distinct !{!13, !11}
