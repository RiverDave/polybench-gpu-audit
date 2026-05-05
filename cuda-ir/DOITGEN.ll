; ModuleID = 'DOITGEN/doitgen.cu'
source_filename = "DOITGEN/doitgen.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z15doitgen_kernel1PfS_S_i(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store i32 %3, ptr %8, align 4
  %12 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %13 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %14 = mul i32 %12, %13
  %15 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %16 = add i32 %14, %15
  store i32 %16, ptr %9, align 4
  %17 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %18 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %19 = mul i32 %17, %18
  %20 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %21 = add i32 %19, %20
  store i32 %21, ptr %10, align 4
  %22 = load i32, ptr %9, align 4
  %23 = icmp slt i32 %22, 128
  br i1 %23, label %24, label %88

24:                                               ; preds = %4
  %25 = load i32, ptr %10, align 4
  %26 = icmp slt i32 %25, 128
  br i1 %26, label %27, label %88

27:                                               ; preds = %24
  %28 = load ptr, ptr %5, align 8
  %29 = load i32, ptr %8, align 4
  %30 = mul nsw i32 %29, 16384
  %31 = load i32, ptr %10, align 4
  %32 = mul nsw i32 %31, 128
  %33 = add nsw i32 %30, %32
  %34 = load i32, ptr %9, align 4
  %35 = add nsw i32 %33, %34
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds float, ptr %28, i64 %36
  store float 0.000000e+00, ptr %37, align 4
  store i32 0, ptr %11, align 4
  br label %38

38:                                               ; preds = %84, %27
  %39 = load i32, ptr %11, align 4
  %40 = icmp slt i32 %39, 128
  br i1 %40, label %41, label %87

41:                                               ; preds = %38
  %42 = load ptr, ptr %5, align 8
  %43 = load i32, ptr %8, align 4
  %44 = mul nsw i32 %43, 16384
  %45 = load i32, ptr %10, align 4
  %46 = mul nsw i32 %45, 128
  %47 = add nsw i32 %44, %46
  %48 = load i32, ptr %9, align 4
  %49 = add nsw i32 %47, %48
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds float, ptr %42, i64 %50
  %52 = load float, ptr %51, align 4
  %53 = load ptr, ptr %6, align 8
  %54 = load i32, ptr %8, align 4
  %55 = mul nsw i32 %54, 16384
  %56 = load i32, ptr %10, align 4
  %57 = mul nsw i32 %56, 128
  %58 = add nsw i32 %55, %57
  %59 = load i32, ptr %11, align 4
  %60 = add nsw i32 %58, %59
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds float, ptr %53, i64 %61
  %63 = load float, ptr %62, align 4
  %64 = load ptr, ptr %7, align 8
  %65 = load i32, ptr %11, align 4
  %66 = mul nsw i32 %65, 128
  %67 = load i32, ptr %9, align 4
  %68 = add nsw i32 %66, %67
  %69 = sext i32 %68 to i64
  %70 = getelementptr inbounds float, ptr %64, i64 %69
  %71 = load float, ptr %70, align 4
  %72 = fmul contract float %63, %71
  %73 = fadd contract float %52, %72
  %74 = load ptr, ptr %5, align 8
  %75 = load i32, ptr %8, align 4
  %76 = mul nsw i32 %75, 16384
  %77 = load i32, ptr %10, align 4
  %78 = mul nsw i32 %77, 128
  %79 = add nsw i32 %76, %78
  %80 = load i32, ptr %9, align 4
  %81 = add nsw i32 %79, %80
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds float, ptr %74, i64 %82
  store float %73, ptr %83, align 4
  br label %84

84:                                               ; preds = %41
  %85 = load i32, ptr %11, align 4
  %86 = add nsw i32 %85, 1
  store i32 %86, ptr %11, align 4
  br label %38, !llvm.loop !9

87:                                               ; preds = %38
  br label %88

88:                                               ; preds = %87, %24, %4
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z15doitgen_kernel2PfS_S_i(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store i32 %3, ptr %8, align 4
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
  %21 = load i32, ptr %9, align 4
  %22 = icmp slt i32 %21, 128
  br i1 %22, label %23, label %48

23:                                               ; preds = %4
  %24 = load i32, ptr %10, align 4
  %25 = icmp slt i32 %24, 128
  br i1 %25, label %26, label %48

26:                                               ; preds = %23
  %27 = load ptr, ptr %5, align 8
  %28 = load i32, ptr %8, align 4
  %29 = mul nsw i32 %28, 16384
  %30 = load i32, ptr %10, align 4
  %31 = mul nsw i32 %30, 128
  %32 = add nsw i32 %29, %31
  %33 = load i32, ptr %9, align 4
  %34 = add nsw i32 %32, %33
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds float, ptr %27, i64 %35
  %37 = load float, ptr %36, align 4
  %38 = load ptr, ptr %6, align 8
  %39 = load i32, ptr %8, align 4
  %40 = mul nsw i32 %39, 16384
  %41 = load i32, ptr %10, align 4
  %42 = mul nsw i32 %41, 128
  %43 = add nsw i32 %40, %42
  %44 = load i32, ptr %9, align 4
  %45 = add nsw i32 %43, %44
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds float, ptr %38, i64 %46
  store float %37, ptr %47, align 4
  br label %48

48:                                               ; preds = %26, %23, %4
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
!4 = !{ptr @_Z15doitgen_kernel1PfS_S_i}
!5 = !{ptr @_Z15doitgen_kernel2PfS_S_i}
!6 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!7 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!8 = !{i32 2, i32 0}
!9 = distinct !{!9, !10}
!10 = !{!"llvm.loop.mustprogress"}
