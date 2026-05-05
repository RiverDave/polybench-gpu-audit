; ModuleID = '3DCONV/3DConvolution.cu'
source_filename = "3DCONV/3DConvolution.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local ptx_kernel void @_Z20convolution3D_kerneliiiPfS_i(i32 noundef %0, i32 noundef %1, i32 noundef %2, ptr noundef %3, ptr noundef %4, i32 noundef %5) #0 {
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca float, align 4
  %16 = alloca float, align 4
  %17 = alloca float, align 4
  %18 = alloca float, align 4
  %19 = alloca float, align 4
  %20 = alloca float, align 4
  %21 = alloca float, align 4
  %22 = alloca float, align 4
  %23 = alloca float, align 4
  store i32 %0, ptr %7, align 4
  store i32 %1, ptr %8, align 4
  store i32 %2, ptr %9, align 4
  store ptr %3, ptr %10, align 8
  store ptr %4, ptr %11, align 8
  store i32 %5, ptr %12, align 4
  %24 = call noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %25 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %26 = mul i32 %24, %25
  %27 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %28 = add i32 %26, %27
  store i32 %28, ptr %13, align 4
  %29 = call noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y()
  %30 = call noundef range(i32 1, 1025) i32 @llvm.nvvm.read.ptx.sreg.ntid.y()
  %31 = mul i32 %29, %30
  %32 = call noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.y()
  %33 = add i32 %31, %32
  store i32 %33, ptr %14, align 4
  store float 2.000000e+00, ptr %15, align 4
  store float 5.000000e+00, ptr %18, align 4
  store float -8.000000e+00, ptr %21, align 4
  store float -3.000000e+00, ptr %16, align 4
  store float 6.000000e+00, ptr %19, align 4
  store float -9.000000e+00, ptr %22, align 4
  store float 4.000000e+00, ptr %17, align 4
  store float 7.000000e+00, ptr %20, align 4
  store float 1.000000e+01, ptr %23, align 4
  %34 = load i32, ptr %12, align 4
  %35 = load i32, ptr %7, align 4
  %36 = sub nsw i32 %35, 1
  %37 = icmp slt i32 %34, %36
  br i1 %37, label %38, label %322

38:                                               ; preds = %6
  %39 = load i32, ptr %14, align 4
  %40 = load i32, ptr %8, align 4
  %41 = sub nsw i32 %40, 1
  %42 = icmp slt i32 %39, %41
  br i1 %42, label %43, label %322

43:                                               ; preds = %38
  %44 = load i32, ptr %13, align 4
  %45 = load i32, ptr %9, align 4
  %46 = sub nsw i32 %45, 1
  %47 = icmp slt i32 %44, %46
  br i1 %47, label %48, label %322

48:                                               ; preds = %43
  %49 = load i32, ptr %12, align 4
  %50 = icmp sgt i32 %49, 0
  br i1 %50, label %51, label %322

51:                                               ; preds = %48
  %52 = load i32, ptr %14, align 4
  %53 = icmp sgt i32 %52, 0
  br i1 %53, label %54, label %322

54:                                               ; preds = %51
  %55 = load i32, ptr %13, align 4
  %56 = icmp sgt i32 %55, 0
  br i1 %56, label %57, label %322

57:                                               ; preds = %54
  %58 = load float, ptr %15, align 4
  %59 = load ptr, ptr %10, align 8
  %60 = load i32, ptr %12, align 4
  %61 = sub nsw i32 %60, 1
  %62 = mul nsw i32 %61, 65536
  %63 = load i32, ptr %14, align 4
  %64 = sub nsw i32 %63, 1
  %65 = mul nsw i32 %64, 256
  %66 = add nsw i32 %62, %65
  %67 = load i32, ptr %13, align 4
  %68 = sub nsw i32 %67, 1
  %69 = add nsw i32 %66, %68
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds float, ptr %59, i64 %70
  %72 = load float, ptr %71, align 4
  %73 = fmul contract float %58, %72
  %74 = load float, ptr %17, align 4
  %75 = load ptr, ptr %10, align 8
  %76 = load i32, ptr %12, align 4
  %77 = add nsw i32 %76, 1
  %78 = mul nsw i32 %77, 65536
  %79 = load i32, ptr %14, align 4
  %80 = sub nsw i32 %79, 1
  %81 = mul nsw i32 %80, 256
  %82 = add nsw i32 %78, %81
  %83 = load i32, ptr %13, align 4
  %84 = sub nsw i32 %83, 1
  %85 = add nsw i32 %82, %84
  %86 = sext i32 %85 to i64
  %87 = getelementptr inbounds float, ptr %75, i64 %86
  %88 = load float, ptr %87, align 4
  %89 = fmul contract float %74, %88
  %90 = fadd contract float %73, %89
  %91 = load float, ptr %18, align 4
  %92 = load ptr, ptr %10, align 8
  %93 = load i32, ptr %12, align 4
  %94 = sub nsw i32 %93, 1
  %95 = mul nsw i32 %94, 65536
  %96 = load i32, ptr %14, align 4
  %97 = sub nsw i32 %96, 1
  %98 = mul nsw i32 %97, 256
  %99 = add nsw i32 %95, %98
  %100 = load i32, ptr %13, align 4
  %101 = sub nsw i32 %100, 1
  %102 = add nsw i32 %99, %101
  %103 = sext i32 %102 to i64
  %104 = getelementptr inbounds float, ptr %92, i64 %103
  %105 = load float, ptr %104, align 4
  %106 = fmul contract float %91, %105
  %107 = fadd contract float %90, %106
  %108 = load float, ptr %20, align 4
  %109 = load ptr, ptr %10, align 8
  %110 = load i32, ptr %12, align 4
  %111 = add nsw i32 %110, 1
  %112 = mul nsw i32 %111, 65536
  %113 = load i32, ptr %14, align 4
  %114 = sub nsw i32 %113, 1
  %115 = mul nsw i32 %114, 256
  %116 = add nsw i32 %112, %115
  %117 = load i32, ptr %13, align 4
  %118 = sub nsw i32 %117, 1
  %119 = add nsw i32 %116, %118
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds float, ptr %109, i64 %120
  %122 = load float, ptr %121, align 4
  %123 = fmul contract float %108, %122
  %124 = fadd contract float %107, %123
  %125 = load float, ptr %21, align 4
  %126 = load ptr, ptr %10, align 8
  %127 = load i32, ptr %12, align 4
  %128 = sub nsw i32 %127, 1
  %129 = mul nsw i32 %128, 65536
  %130 = load i32, ptr %14, align 4
  %131 = sub nsw i32 %130, 1
  %132 = mul nsw i32 %131, 256
  %133 = add nsw i32 %129, %132
  %134 = load i32, ptr %13, align 4
  %135 = sub nsw i32 %134, 1
  %136 = add nsw i32 %133, %135
  %137 = sext i32 %136 to i64
  %138 = getelementptr inbounds float, ptr %126, i64 %137
  %139 = load float, ptr %138, align 4
  %140 = fmul contract float %125, %139
  %141 = fadd contract float %124, %140
  %142 = load float, ptr %23, align 4
  %143 = load ptr, ptr %10, align 8
  %144 = load i32, ptr %12, align 4
  %145 = add nsw i32 %144, 1
  %146 = mul nsw i32 %145, 65536
  %147 = load i32, ptr %14, align 4
  %148 = sub nsw i32 %147, 1
  %149 = mul nsw i32 %148, 256
  %150 = add nsw i32 %146, %149
  %151 = load i32, ptr %13, align 4
  %152 = sub nsw i32 %151, 1
  %153 = add nsw i32 %150, %152
  %154 = sext i32 %153 to i64
  %155 = getelementptr inbounds float, ptr %143, i64 %154
  %156 = load float, ptr %155, align 4
  %157 = fmul contract float %142, %156
  %158 = fadd contract float %141, %157
  %159 = load float, ptr %16, align 4
  %160 = load ptr, ptr %10, align 8
  %161 = load i32, ptr %12, align 4
  %162 = add nsw i32 %161, 0
  %163 = mul nsw i32 %162, 65536
  %164 = load i32, ptr %14, align 4
  %165 = sub nsw i32 %164, 1
  %166 = mul nsw i32 %165, 256
  %167 = add nsw i32 %163, %166
  %168 = load i32, ptr %13, align 4
  %169 = add nsw i32 %168, 0
  %170 = add nsw i32 %167, %169
  %171 = sext i32 %170 to i64
  %172 = getelementptr inbounds float, ptr %160, i64 %171
  %173 = load float, ptr %172, align 4
  %174 = fmul contract float %159, %173
  %175 = fadd contract float %158, %174
  %176 = load float, ptr %19, align 4
  %177 = load ptr, ptr %10, align 8
  %178 = load i32, ptr %12, align 4
  %179 = add nsw i32 %178, 0
  %180 = mul nsw i32 %179, 65536
  %181 = load i32, ptr %14, align 4
  %182 = add nsw i32 %181, 0
  %183 = mul nsw i32 %182, 256
  %184 = add nsw i32 %180, %183
  %185 = load i32, ptr %13, align 4
  %186 = add nsw i32 %185, 0
  %187 = add nsw i32 %184, %186
  %188 = sext i32 %187 to i64
  %189 = getelementptr inbounds float, ptr %177, i64 %188
  %190 = load float, ptr %189, align 4
  %191 = fmul contract float %176, %190
  %192 = fadd contract float %175, %191
  %193 = load float, ptr %22, align 4
  %194 = load ptr, ptr %10, align 8
  %195 = load i32, ptr %12, align 4
  %196 = add nsw i32 %195, 0
  %197 = mul nsw i32 %196, 65536
  %198 = load i32, ptr %14, align 4
  %199 = add nsw i32 %198, 1
  %200 = mul nsw i32 %199, 256
  %201 = add nsw i32 %197, %200
  %202 = load i32, ptr %13, align 4
  %203 = add nsw i32 %202, 0
  %204 = add nsw i32 %201, %203
  %205 = sext i32 %204 to i64
  %206 = getelementptr inbounds float, ptr %194, i64 %205
  %207 = load float, ptr %206, align 4
  %208 = fmul contract float %193, %207
  %209 = fadd contract float %192, %208
  %210 = load float, ptr %15, align 4
  %211 = load ptr, ptr %10, align 8
  %212 = load i32, ptr %12, align 4
  %213 = sub nsw i32 %212, 1
  %214 = mul nsw i32 %213, 65536
  %215 = load i32, ptr %14, align 4
  %216 = sub nsw i32 %215, 1
  %217 = mul nsw i32 %216, 256
  %218 = add nsw i32 %214, %217
  %219 = load i32, ptr %13, align 4
  %220 = add nsw i32 %219, 1
  %221 = add nsw i32 %218, %220
  %222 = sext i32 %221 to i64
  %223 = getelementptr inbounds float, ptr %211, i64 %222
  %224 = load float, ptr %223, align 4
  %225 = fmul contract float %210, %224
  %226 = fadd contract float %209, %225
  %227 = load float, ptr %17, align 4
  %228 = load ptr, ptr %10, align 8
  %229 = load i32, ptr %12, align 4
  %230 = add nsw i32 %229, 1
  %231 = mul nsw i32 %230, 65536
  %232 = load i32, ptr %14, align 4
  %233 = sub nsw i32 %232, 1
  %234 = mul nsw i32 %233, 256
  %235 = add nsw i32 %231, %234
  %236 = load i32, ptr %13, align 4
  %237 = add nsw i32 %236, 1
  %238 = add nsw i32 %235, %237
  %239 = sext i32 %238 to i64
  %240 = getelementptr inbounds float, ptr %228, i64 %239
  %241 = load float, ptr %240, align 4
  %242 = fmul contract float %227, %241
  %243 = fadd contract float %226, %242
  %244 = load float, ptr %18, align 4
  %245 = load ptr, ptr %10, align 8
  %246 = load i32, ptr %12, align 4
  %247 = sub nsw i32 %246, 1
  %248 = mul nsw i32 %247, 65536
  %249 = load i32, ptr %14, align 4
  %250 = add nsw i32 %249, 0
  %251 = mul nsw i32 %250, 256
  %252 = add nsw i32 %248, %251
  %253 = load i32, ptr %13, align 4
  %254 = add nsw i32 %253, 1
  %255 = add nsw i32 %252, %254
  %256 = sext i32 %255 to i64
  %257 = getelementptr inbounds float, ptr %245, i64 %256
  %258 = load float, ptr %257, align 4
  %259 = fmul contract float %244, %258
  %260 = fadd contract float %243, %259
  %261 = load float, ptr %20, align 4
  %262 = load ptr, ptr %10, align 8
  %263 = load i32, ptr %12, align 4
  %264 = add nsw i32 %263, 1
  %265 = mul nsw i32 %264, 65536
  %266 = load i32, ptr %14, align 4
  %267 = add nsw i32 %266, 0
  %268 = mul nsw i32 %267, 256
  %269 = add nsw i32 %265, %268
  %270 = load i32, ptr %13, align 4
  %271 = add nsw i32 %270, 1
  %272 = add nsw i32 %269, %271
  %273 = sext i32 %272 to i64
  %274 = getelementptr inbounds float, ptr %262, i64 %273
  %275 = load float, ptr %274, align 4
  %276 = fmul contract float %261, %275
  %277 = fadd contract float %260, %276
  %278 = load float, ptr %21, align 4
  %279 = load ptr, ptr %10, align 8
  %280 = load i32, ptr %12, align 4
  %281 = sub nsw i32 %280, 1
  %282 = mul nsw i32 %281, 65536
  %283 = load i32, ptr %14, align 4
  %284 = add nsw i32 %283, 1
  %285 = mul nsw i32 %284, 256
  %286 = add nsw i32 %282, %285
  %287 = load i32, ptr %13, align 4
  %288 = add nsw i32 %287, 1
  %289 = add nsw i32 %286, %288
  %290 = sext i32 %289 to i64
  %291 = getelementptr inbounds float, ptr %279, i64 %290
  %292 = load float, ptr %291, align 4
  %293 = fmul contract float %278, %292
  %294 = fadd contract float %277, %293
  %295 = load float, ptr %23, align 4
  %296 = load ptr, ptr %10, align 8
  %297 = load i32, ptr %12, align 4
  %298 = add nsw i32 %297, 1
  %299 = mul nsw i32 %298, 65536
  %300 = load i32, ptr %14, align 4
  %301 = add nsw i32 %300, 1
  %302 = mul nsw i32 %301, 256
  %303 = add nsw i32 %299, %302
  %304 = load i32, ptr %13, align 4
  %305 = add nsw i32 %304, 1
  %306 = add nsw i32 %303, %305
  %307 = sext i32 %306 to i64
  %308 = getelementptr inbounds float, ptr %296, i64 %307
  %309 = load float, ptr %308, align 4
  %310 = fmul contract float %295, %309
  %311 = fadd contract float %294, %310
  %312 = load ptr, ptr %11, align 8
  %313 = load i32, ptr %12, align 4
  %314 = mul nsw i32 %313, 65536
  %315 = load i32, ptr %14, align 4
  %316 = mul nsw i32 %315, 256
  %317 = add nsw i32 %314, %316
  %318 = load i32, ptr %13, align 4
  %319 = add nsw i32 %317, %318
  %320 = sext i32 %319 to i64
  %321 = getelementptr inbounds float, ptr %312, i64 %320
  store float %311, ptr %321, align 4
  br label %322

322:                                              ; preds = %57, %54, %51, %48, %43, %38, %6
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
!4 = !{ptr @_Z20convolution3D_kerneliiiPfS_i}
!5 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = !{i32 2, i32 0}
