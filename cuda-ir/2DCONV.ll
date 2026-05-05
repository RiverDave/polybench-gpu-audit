; ModuleID = '2DCONV/2DConvolution.cu'
source_filename = "2DCONV/2DConvolution.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z20convolution2D_kerneliiPfS_(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca float, align 4
  %12 = alloca float, align 4
  %13 = alloca float, align 4
  %14 = alloca float, align 4
  %15 = alloca float, align 4
  %16 = alloca float, align 4
  %17 = alloca float, align 4
  %18 = alloca float, align 4
  %19 = alloca float, align 4
  store i32 %0, ptr %5, align 4
  store i32 %1, ptr %6, align 4
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %20 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %21 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %22 = mul i32 %20, %21
  %23 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %24 = add i32 %22, %23
  store i32 %24, ptr %9, align 4
  %25 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %26 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %27 = mul i32 %25, %26
  %28 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %29 = add i32 %27, %28
  store i32 %29, ptr %10, align 4
  store float 0x3FC99999A0000000, ptr %11, align 4
  store float 5.000000e-01, ptr %14, align 4
  store float 0xBFE99999A0000000, ptr %17, align 4
  store float 0xBFD3333340000000, ptr %12, align 4
  store float 0x3FE3333340000000, ptr %15, align 4
  store float 0xBFECCCCCC0000000, ptr %18, align 4
  store float 0x3FD99999A0000000, ptr %13, align 4
  store float 0x3FE6666660000000, ptr %16, align 4
  store float 0x3FB99999A0000000, ptr %19, align 4
  %30 = load i32, ptr %10, align 4
  %31 = load i32, ptr %5, align 4
  %32 = sub nsw i32 %31, 1
  %33 = icmp slt i32 %30, %32
  br i1 %33, label %34, label %169

34:                                               ; preds = %4
  %35 = load i32, ptr %9, align 4
  %36 = load i32, ptr %6, align 4
  %37 = sub nsw i32 %36, 1
  %38 = icmp slt i32 %35, %37
  br i1 %38, label %39, label %169

39:                                               ; preds = %34
  %40 = load i32, ptr %10, align 4
  %41 = icmp sgt i32 %40, 0
  br i1 %41, label %42, label %169

42:                                               ; preds = %39
  %43 = load i32, ptr %9, align 4
  %44 = icmp sgt i32 %43, 0
  br i1 %44, label %45, label %169

45:                                               ; preds = %42
  %46 = load float, ptr %11, align 4
  %47 = load ptr, ptr %7, align 8
  %48 = load i32, ptr %10, align 4
  %49 = sub nsw i32 %48, 1
  %50 = mul nsw i32 %49, 4096
  %51 = load i32, ptr %9, align 4
  %52 = sub nsw i32 %51, 1
  %53 = add nsw i32 %50, %52
  %54 = sext i32 %53 to i64
  %55 = getelementptr inbounds float, ptr %47, i64 %54
  %56 = load float, ptr %55, align 4
  %57 = fmul contract float %46, %56
  %58 = load float, ptr %14, align 4
  %59 = load ptr, ptr %7, align 8
  %60 = load i32, ptr %10, align 4
  %61 = sub nsw i32 %60, 1
  %62 = mul nsw i32 %61, 4096
  %63 = load i32, ptr %9, align 4
  %64 = add nsw i32 %63, 0
  %65 = add nsw i32 %62, %64
  %66 = sext i32 %65 to i64
  %67 = getelementptr inbounds float, ptr %59, i64 %66
  %68 = load float, ptr %67, align 4
  %69 = fmul contract float %58, %68
  %70 = fadd contract float %57, %69
  %71 = load float, ptr %17, align 4
  %72 = load ptr, ptr %7, align 8
  %73 = load i32, ptr %10, align 4
  %74 = sub nsw i32 %73, 1
  %75 = mul nsw i32 %74, 4096
  %76 = load i32, ptr %9, align 4
  %77 = add nsw i32 %76, 1
  %78 = add nsw i32 %75, %77
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds float, ptr %72, i64 %79
  %81 = load float, ptr %80, align 4
  %82 = fmul contract float %71, %81
  %83 = fadd contract float %70, %82
  %84 = load float, ptr %12, align 4
  %85 = load ptr, ptr %7, align 8
  %86 = load i32, ptr %10, align 4
  %87 = add nsw i32 %86, 0
  %88 = mul nsw i32 %87, 4096
  %89 = load i32, ptr %9, align 4
  %90 = sub nsw i32 %89, 1
  %91 = add nsw i32 %88, %90
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds float, ptr %85, i64 %92
  %94 = load float, ptr %93, align 4
  %95 = fmul contract float %84, %94
  %96 = fadd contract float %83, %95
  %97 = load float, ptr %15, align 4
  %98 = load ptr, ptr %7, align 8
  %99 = load i32, ptr %10, align 4
  %100 = add nsw i32 %99, 0
  %101 = mul nsw i32 %100, 4096
  %102 = load i32, ptr %9, align 4
  %103 = add nsw i32 %102, 0
  %104 = add nsw i32 %101, %103
  %105 = sext i32 %104 to i64
  %106 = getelementptr inbounds float, ptr %98, i64 %105
  %107 = load float, ptr %106, align 4
  %108 = fmul contract float %97, %107
  %109 = fadd contract float %96, %108
  %110 = load float, ptr %18, align 4
  %111 = load ptr, ptr %7, align 8
  %112 = load i32, ptr %10, align 4
  %113 = add nsw i32 %112, 0
  %114 = mul nsw i32 %113, 4096
  %115 = load i32, ptr %9, align 4
  %116 = add nsw i32 %115, 1
  %117 = add nsw i32 %114, %116
  %118 = sext i32 %117 to i64
  %119 = getelementptr inbounds float, ptr %111, i64 %118
  %120 = load float, ptr %119, align 4
  %121 = fmul contract float %110, %120
  %122 = fadd contract float %109, %121
  %123 = load float, ptr %13, align 4
  %124 = load ptr, ptr %7, align 8
  %125 = load i32, ptr %10, align 4
  %126 = add nsw i32 %125, 1
  %127 = mul nsw i32 %126, 4096
  %128 = load i32, ptr %9, align 4
  %129 = sub nsw i32 %128, 1
  %130 = add nsw i32 %127, %129
  %131 = sext i32 %130 to i64
  %132 = getelementptr inbounds float, ptr %124, i64 %131
  %133 = load float, ptr %132, align 4
  %134 = fmul contract float %123, %133
  %135 = fadd contract float %122, %134
  %136 = load float, ptr %16, align 4
  %137 = load ptr, ptr %7, align 8
  %138 = load i32, ptr %10, align 4
  %139 = add nsw i32 %138, 1
  %140 = mul nsw i32 %139, 4096
  %141 = load i32, ptr %9, align 4
  %142 = add nsw i32 %141, 0
  %143 = add nsw i32 %140, %142
  %144 = sext i32 %143 to i64
  %145 = getelementptr inbounds float, ptr %137, i64 %144
  %146 = load float, ptr %145, align 4
  %147 = fmul contract float %136, %146
  %148 = fadd contract float %135, %147
  %149 = load float, ptr %19, align 4
  %150 = load ptr, ptr %7, align 8
  %151 = load i32, ptr %10, align 4
  %152 = add nsw i32 %151, 1
  %153 = mul nsw i32 %152, 4096
  %154 = load i32, ptr %9, align 4
  %155 = add nsw i32 %154, 1
  %156 = add nsw i32 %153, %155
  %157 = sext i32 %156 to i64
  %158 = getelementptr inbounds float, ptr %150, i64 %157
  %159 = load float, ptr %158, align 4
  %160 = fmul contract float %149, %159
  %161 = fadd contract float %148, %160
  %162 = load ptr, ptr %8, align 8
  %163 = load i32, ptr %10, align 4
  %164 = mul nsw i32 %163, 4096
  %165 = load i32, ptr %9, align 4
  %166 = add nsw i32 %164, %165
  %167 = sext i32 %166 to i64
  %168 = getelementptr inbounds float, ptr %162, i64 %167
  store float %161, ptr %168, align 4
  br label %169

169:                                              ; preds = %45, %42, %39, %34, %4
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
!4 = !{ptr @_Z20convolution2D_kerneliiPfS_}
!5 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = !{i32 2, i32 0}
