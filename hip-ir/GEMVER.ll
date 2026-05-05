; ModuleID = '/home/ubuntu/audit/hip-src/GEMVER.hip.cpp'
source_filename = "/home/ubuntu/audit/hip-src/GEMVER.hip.cpp"
target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "amdgcn-amd-amdhsa"

%0 = type { ptr addrspace(1), ptr addrspace(1), %1, i64, i64, i64 }
%1 = type { i64 }
%2 = type { i64, i64, i32, i32 }
%3 = type { [64 x [8 x i64]] }
%4 = type { i64, %1, i64, i32, i32, i64, i64, %5, [2 x i32] }
%5 = type { ptr addrspace(1) }
%6 = type { i16, i16, i16, i16, i16, i16, i32, i32, i32, i32, i32, %5, ptr addrspace(1), i64, %1 }
%struct.__hip_builtin_blockIdx_t = type { i8 }
%struct.__hip_builtin_blockDim_t = type { i8 }
%struct.__hip_builtin_threadIdx_t = type { i8 }

@__const.__assert_fail.fmt = private unnamed_addr addrspace(4) constant [47 x i8] c"%s:%u: %s: Device-side assertion `%s' failed.\0A\00", align 16
@blockIdx = extern_weak dso_local protected addrspace(1) global %struct.__hip_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local protected addrspace(1) global %struct.__hip_builtin_blockDim_t, align 1
@threadIdx = extern_weak dso_local protected addrspace(1) global %struct.__hip_builtin_threadIdx_t, align 1
@__hip_cuid_6dd7cc6069d37f4a = addrspace(1) global i8 0
@llvm.compiler.used = appending addrspace(1) global [1 x ptr] [ptr addrspacecast (ptr addrspace(1) @__hip_cuid_6dd7cc6069d37f4a to ptr)], section "llvm.metadata"
@__oclc_ABI_version = weak_odr hidden local_unnamed_addr addrspace(4) constant i32 500

; Function Attrs: convergent mustprogress noinline noreturn nounwind optnone
define weak void @__cxa_pure_virtual() #0 {
  call void @llvm.trap()
  unreachable
}

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap() #1

; Function Attrs: convergent mustprogress noinline noreturn nounwind optnone
define weak void @__cxa_deleted_virtual() #0 {
  call void @llvm.trap()
  unreachable
}

; Function Attrs: convergent mustprogress noinline nounwind optnone
define weak hidden void @__assert_fail(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3) #2 {
  %5 = alloca ptr, align 8, addrspace(5)
  %6 = alloca ptr, align 8, addrspace(5)
  %7 = alloca i32, align 4, addrspace(5)
  %8 = alloca ptr, align 8, addrspace(5)
  %9 = alloca [47 x i8], align 16, addrspace(5)
  %10 = alloca i64, align 8, addrspace(5)
  %11 = alloca i32, align 4, addrspace(5)
  %12 = alloca ptr, align 8, addrspace(5)
  %13 = alloca ptr, align 8, addrspace(5)
  %14 = alloca ptr, align 8, addrspace(5)
  %15 = alloca ptr, align 8, addrspace(5)
  %16 = addrspacecast ptr addrspace(5) %5 to ptr
  %17 = addrspacecast ptr addrspace(5) %6 to ptr
  %18 = addrspacecast ptr addrspace(5) %7 to ptr
  %19 = addrspacecast ptr addrspace(5) %8 to ptr
  %20 = addrspacecast ptr addrspace(5) %9 to ptr
  %21 = addrspacecast ptr addrspace(5) %10 to ptr
  %22 = addrspacecast ptr addrspace(5) %11 to ptr
  %23 = addrspacecast ptr addrspace(5) %12 to ptr
  %24 = addrspacecast ptr addrspace(5) %13 to ptr
  %25 = addrspacecast ptr addrspace(5) %14 to ptr
  %26 = addrspacecast ptr addrspace(5) %15 to ptr
  store ptr %0, ptr %16, align 8
  store ptr %1, ptr %17, align 8
  store i32 %2, ptr %18, align 4
  store ptr %3, ptr %19, align 8
  call void @llvm.memcpy.p0.p4.i64(ptr align 16 %20, ptr addrspace(4) align 16 @__const.__assert_fail.fmt, i64 47, i1 false)
  %27 = call i64 @__ockl_fprintf_stderr_begin() #12
  store i64 %27, ptr %21, align 8
  store i32 0, ptr %22, align 4
  br label %28

28:                                               ; preds = %4
  %29 = getelementptr inbounds [47 x i8], ptr %20, i64 0, i64 0
  store ptr %29, ptr %23, align 8
  br label %30

30:                                               ; preds = %35, %28
  %31 = load ptr, ptr %23, align 8
  %32 = getelementptr inbounds nuw i8, ptr %31, i32 1
  store ptr %32, ptr %23, align 8
  %33 = load i8, ptr %31, align 1
  %34 = icmp ne i8 %33, 0
  br i1 %34, label %35, label %36

35:                                               ; preds = %30
  br label %30, !llvm.loop !8

36:                                               ; preds = %30
  %37 = load ptr, ptr %23, align 8
  %38 = getelementptr inbounds [47 x i8], ptr %20, i64 0, i64 0
  %39 = ptrtoint ptr %37 to i64
  %40 = ptrtoint ptr %38 to i64
  %41 = sub i64 %39, %40
  %42 = trunc i64 %41 to i32
  store i32 %42, ptr %22, align 4
  br label %43

43:                                               ; preds = %36
  %44 = load i64, ptr %21, align 8
  %45 = getelementptr inbounds [47 x i8], ptr %20, i64 0, i64 0
  %46 = load i32, ptr %22, align 4
  %47 = sext i32 %46 to i64
  %48 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %44, ptr noundef %45, i64 noundef %47, i32 noundef 0) #12
  store i64 %48, ptr %21, align 8
  br label %49

49:                                               ; preds = %43
  %50 = load ptr, ptr %17, align 8
  store ptr %50, ptr %24, align 8
  br label %51

51:                                               ; preds = %56, %49
  %52 = load ptr, ptr %24, align 8
  %53 = getelementptr inbounds nuw i8, ptr %52, i32 1
  store ptr %53, ptr %24, align 8
  %54 = load i8, ptr %52, align 1
  %55 = icmp ne i8 %54, 0
  br i1 %55, label %56, label %57

56:                                               ; preds = %51
  br label %51, !llvm.loop !10

57:                                               ; preds = %51
  %58 = load ptr, ptr %24, align 8
  %59 = load ptr, ptr %17, align 8
  %60 = ptrtoint ptr %58 to i64
  %61 = ptrtoint ptr %59 to i64
  %62 = sub i64 %60, %61
  %63 = trunc i64 %62 to i32
  store i32 %63, ptr %22, align 4
  br label %64

64:                                               ; preds = %57
  %65 = load i64, ptr %21, align 8
  %66 = load ptr, ptr %17, align 8
  %67 = load i32, ptr %22, align 4
  %68 = sext i32 %67 to i64
  %69 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %65, ptr noundef %66, i64 noundef %68, i32 noundef 0) #12
  store i64 %69, ptr %21, align 8
  %70 = load i64, ptr %21, align 8
  %71 = load i32, ptr %18, align 4
  %72 = zext i32 %71 to i64
  %73 = call i64 @__ockl_fprintf_append_args(i64 noundef %70, i32 noundef 1, i64 noundef %72, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i32 noundef 0) #12
  store i64 %73, ptr %21, align 8
  br label %74

74:                                               ; preds = %64
  %75 = load ptr, ptr %19, align 8
  store ptr %75, ptr %25, align 8
  br label %76

76:                                               ; preds = %81, %74
  %77 = load ptr, ptr %25, align 8
  %78 = getelementptr inbounds nuw i8, ptr %77, i32 1
  store ptr %78, ptr %25, align 8
  %79 = load i8, ptr %77, align 1
  %80 = icmp ne i8 %79, 0
  br i1 %80, label %81, label %82

81:                                               ; preds = %76
  br label %76, !llvm.loop !11

82:                                               ; preds = %76
  %83 = load ptr, ptr %25, align 8
  %84 = load ptr, ptr %19, align 8
  %85 = ptrtoint ptr %83 to i64
  %86 = ptrtoint ptr %84 to i64
  %87 = sub i64 %85, %86
  %88 = trunc i64 %87 to i32
  store i32 %88, ptr %22, align 4
  br label %89

89:                                               ; preds = %82
  %90 = load i64, ptr %21, align 8
  %91 = load ptr, ptr %19, align 8
  %92 = load i32, ptr %22, align 4
  %93 = sext i32 %92 to i64
  %94 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %90, ptr noundef %91, i64 noundef %93, i32 noundef 0) #12
  store i64 %94, ptr %21, align 8
  br label %95

95:                                               ; preds = %89
  %96 = load ptr, ptr %16, align 8
  store ptr %96, ptr %26, align 8
  br label %97

97:                                               ; preds = %102, %95
  %98 = load ptr, ptr %26, align 8
  %99 = getelementptr inbounds nuw i8, ptr %98, i32 1
  store ptr %99, ptr %26, align 8
  %100 = load i8, ptr %98, align 1
  %101 = icmp ne i8 %100, 0
  br i1 %101, label %102, label %103

102:                                              ; preds = %97
  br label %97, !llvm.loop !12

103:                                              ; preds = %97
  %104 = load ptr, ptr %26, align 8
  %105 = load ptr, ptr %16, align 8
  %106 = ptrtoint ptr %104 to i64
  %107 = ptrtoint ptr %105 to i64
  %108 = sub i64 %106, %107
  %109 = trunc i64 %108 to i32
  store i32 %109, ptr %22, align 4
  br label %110

110:                                              ; preds = %103
  %111 = load i64, ptr %21, align 8
  %112 = load ptr, ptr %16, align 8
  %113 = load i32, ptr %22, align 4
  %114 = sext i32 %113 to i64
  %115 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %111, ptr noundef %112, i64 noundef %114, i32 noundef 1) #12
  call void @llvm.trap()
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p4.i64(ptr noalias nocapture writeonly, ptr addrspace(4) noalias nocapture readonly, i64, i1 immarg) #3

; Function Attrs: convergent mustprogress noinline nounwind optnone
define weak hidden void @__assertfail() #2 {
  call void @llvm.trap()
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define protected amdgpu_kernel void @_Z14gemver_kernel1iffPfS_S_S_S_(i32 noundef %0, float noundef %1, float noundef %2, ptr addrspace(1) noundef %3, ptr addrspace(1) noundef %4, ptr addrspace(1) noundef %5, ptr addrspace(1) noundef %6, ptr addrspace(1) noundef %7) #4 {
  %9 = alloca i32, align 4, addrspace(5)
  %10 = alloca i32, align 4, addrspace(5)
  %11 = alloca i32, align 4, addrspace(5)
  %12 = alloca i32, align 4, addrspace(5)
  %13 = alloca i32, align 4, addrspace(5)
  %14 = alloca i32, align 4, addrspace(5)
  %15 = alloca i32, align 4, addrspace(5)
  %16 = alloca i32, align 4, addrspace(5)
  %17 = alloca i32, align 4, addrspace(5)
  %18 = alloca i32, align 4, addrspace(5)
  %19 = alloca i32, align 4, addrspace(5)
  %20 = alloca i32, align 4, addrspace(5)
  %21 = alloca ptr, align 8, addrspace(5)
  %22 = alloca ptr, align 8, addrspace(5)
  %23 = alloca ptr, align 8, addrspace(5)
  %24 = alloca ptr, align 8, addrspace(5)
  %25 = alloca ptr, align 8, addrspace(5)
  %26 = alloca i32, align 4, addrspace(5)
  %27 = alloca float, align 4, addrspace(5)
  %28 = alloca float, align 4, addrspace(5)
  %29 = alloca ptr, align 8, addrspace(5)
  %30 = alloca ptr, align 8, addrspace(5)
  %31 = alloca ptr, align 8, addrspace(5)
  %32 = alloca ptr, align 8, addrspace(5)
  %33 = alloca ptr, align 8, addrspace(5)
  %34 = alloca i32, align 4, addrspace(5)
  %35 = alloca i32, align 4, addrspace(5)
  %36 = addrspacecast ptr addrspace(5) %21 to ptr
  %37 = addrspacecast ptr addrspace(5) %22 to ptr
  %38 = addrspacecast ptr addrspace(5) %23 to ptr
  %39 = addrspacecast ptr addrspace(5) %24 to ptr
  %40 = addrspacecast ptr addrspace(5) %25 to ptr
  %41 = addrspacecast ptr addrspace(5) %26 to ptr
  %42 = addrspacecast ptr addrspace(5) %27 to ptr
  %43 = addrspacecast ptr addrspace(5) %28 to ptr
  %44 = addrspacecast ptr addrspace(5) %29 to ptr
  %45 = addrspacecast ptr addrspace(5) %30 to ptr
  %46 = addrspacecast ptr addrspace(5) %31 to ptr
  %47 = addrspacecast ptr addrspace(5) %32 to ptr
  %48 = addrspacecast ptr addrspace(5) %33 to ptr
  %49 = addrspacecast ptr addrspace(5) %34 to ptr
  %50 = addrspacecast ptr addrspace(5) %35 to ptr
  store ptr addrspace(1) %3, ptr %36, align 8
  %51 = load ptr, ptr %36, align 8
  store ptr addrspace(1) %4, ptr %37, align 8
  %52 = load ptr, ptr %37, align 8
  store ptr addrspace(1) %5, ptr %38, align 8
  %53 = load ptr, ptr %38, align 8
  store ptr addrspace(1) %6, ptr %39, align 8
  %54 = load ptr, ptr %39, align 8
  store ptr addrspace(1) %7, ptr %40, align 8
  %55 = load ptr, ptr %40, align 8
  store i32 %0, ptr %41, align 4
  store float %1, ptr %42, align 4
  store float %2, ptr %43, align 4
  store ptr %51, ptr %44, align 8
  store ptr %52, ptr %45, align 8
  store ptr %53, ptr %46, align 8
  store ptr %54, ptr %47, align 8
  store ptr %55, ptr %48, align 8
  %56 = addrspacecast ptr addrspace(5) %20 to ptr
  %57 = addrspacecast ptr addrspace(5) %14 to ptr
  %58 = call i64 @__ockl_get_group_id(i32 noundef 0) #13
  %59 = trunc i64 %58 to i32
  %60 = addrspacecast ptr addrspace(5) %19 to ptr
  %61 = addrspacecast ptr addrspace(5) %13 to ptr
  %62 = call i64 @__ockl_get_local_size(i32 noundef 0) #13
  %63 = trunc i64 %62 to i32
  %64 = mul i32 %59, %63
  %65 = addrspacecast ptr addrspace(5) %18 to ptr
  %66 = addrspacecast ptr addrspace(5) %12 to ptr
  %67 = call i64 @__ockl_get_local_id(i32 noundef 0) #13
  %68 = trunc i64 %67 to i32
  %69 = add i32 %64, %68
  store i32 %69, ptr %49, align 4
  %70 = addrspacecast ptr addrspace(5) %17 to ptr
  %71 = addrspacecast ptr addrspace(5) %11 to ptr
  %72 = call i64 @__ockl_get_group_id(i32 noundef 1) #13
  %73 = trunc i64 %72 to i32
  %74 = addrspacecast ptr addrspace(5) %16 to ptr
  %75 = addrspacecast ptr addrspace(5) %10 to ptr
  %76 = call i64 @__ockl_get_local_size(i32 noundef 1) #13
  %77 = trunc i64 %76 to i32
  %78 = mul i32 %73, %77
  %79 = addrspacecast ptr addrspace(5) %15 to ptr
  %80 = addrspacecast ptr addrspace(5) %9 to ptr
  %81 = call i64 @__ockl_get_local_id(i32 noundef 1) #13
  %82 = trunc i64 %81 to i32
  %83 = add i32 %78, %82
  store i32 %83, ptr %50, align 4
  %84 = load i32, ptr %50, align 4
  %85 = load i32, ptr %41, align 4
  %86 = icmp slt i32 %84, %85
  br i1 %86, label %87, label %124

87:                                               ; preds = %8
  %88 = load i32, ptr %49, align 4
  %89 = load i32, ptr %41, align 4
  %90 = icmp slt i32 %88, %89
  br i1 %90, label %91, label %124

91:                                               ; preds = %87
  %92 = load ptr, ptr %47, align 8
  %93 = load i32, ptr %50, align 4
  %94 = sext i32 %93 to i64
  %95 = getelementptr inbounds float, ptr %92, i64 %94
  %96 = load float, ptr %95, align 4
  %97 = load ptr, ptr %45, align 8
  %98 = load i32, ptr %49, align 4
  %99 = sext i32 %98 to i64
  %100 = getelementptr inbounds float, ptr %97, i64 %99
  %101 = load float, ptr %100, align 4
  %102 = fmul contract float %96, %101
  %103 = load ptr, ptr %48, align 8
  %104 = load i32, ptr %50, align 4
  %105 = sext i32 %104 to i64
  %106 = getelementptr inbounds float, ptr %103, i64 %105
  %107 = load float, ptr %106, align 4
  %108 = load ptr, ptr %46, align 8
  %109 = load i32, ptr %49, align 4
  %110 = sext i32 %109 to i64
  %111 = getelementptr inbounds float, ptr %108, i64 %110
  %112 = load float, ptr %111, align 4
  %113 = fmul contract float %107, %112
  %114 = fadd contract float %102, %113
  %115 = load ptr, ptr %44, align 8
  %116 = load i32, ptr %50, align 4
  %117 = mul nsw i32 %116, 4096
  %118 = load i32, ptr %49, align 4
  %119 = add nsw i32 %117, %118
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds float, ptr %115, i64 %120
  %122 = load float, ptr %121, align 4
  %123 = fadd contract float %122, %114
  store float %123, ptr %121, align 4
  br label %124

124:                                              ; preds = %91, %87, %8
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define protected amdgpu_kernel void @_Z14gemver_kernel2iffPfS_S_S_(i32 noundef %0, float noundef %1, float noundef %2, ptr addrspace(1) noundef %3, ptr addrspace(1) noundef %4, ptr addrspace(1) noundef %5, ptr addrspace(1) noundef %6) #4 {
  %8 = alloca i32, align 4, addrspace(5)
  %9 = alloca i32, align 4, addrspace(5)
  %10 = alloca i32, align 4, addrspace(5)
  %11 = alloca i32, align 4, addrspace(5)
  %12 = alloca i32, align 4, addrspace(5)
  %13 = alloca i32, align 4, addrspace(5)
  %14 = alloca ptr, align 8, addrspace(5)
  %15 = alloca ptr, align 8, addrspace(5)
  %16 = alloca ptr, align 8, addrspace(5)
  %17 = alloca ptr, align 8, addrspace(5)
  %18 = alloca i32, align 4, addrspace(5)
  %19 = alloca float, align 4, addrspace(5)
  %20 = alloca float, align 4, addrspace(5)
  %21 = alloca ptr, align 8, addrspace(5)
  %22 = alloca ptr, align 8, addrspace(5)
  %23 = alloca ptr, align 8, addrspace(5)
  %24 = alloca ptr, align 8, addrspace(5)
  %25 = alloca i32, align 4, addrspace(5)
  %26 = alloca i32, align 4, addrspace(5)
  %27 = addrspacecast ptr addrspace(5) %14 to ptr
  %28 = addrspacecast ptr addrspace(5) %15 to ptr
  %29 = addrspacecast ptr addrspace(5) %16 to ptr
  %30 = addrspacecast ptr addrspace(5) %17 to ptr
  %31 = addrspacecast ptr addrspace(5) %18 to ptr
  %32 = addrspacecast ptr addrspace(5) %19 to ptr
  %33 = addrspacecast ptr addrspace(5) %20 to ptr
  %34 = addrspacecast ptr addrspace(5) %21 to ptr
  %35 = addrspacecast ptr addrspace(5) %22 to ptr
  %36 = addrspacecast ptr addrspace(5) %23 to ptr
  %37 = addrspacecast ptr addrspace(5) %24 to ptr
  %38 = addrspacecast ptr addrspace(5) %25 to ptr
  %39 = addrspacecast ptr addrspace(5) %26 to ptr
  store ptr addrspace(1) %3, ptr %27, align 8
  %40 = load ptr, ptr %27, align 8
  store ptr addrspace(1) %4, ptr %28, align 8
  %41 = load ptr, ptr %28, align 8
  store ptr addrspace(1) %5, ptr %29, align 8
  %42 = load ptr, ptr %29, align 8
  store ptr addrspace(1) %6, ptr %30, align 8
  %43 = load ptr, ptr %30, align 8
  store i32 %0, ptr %31, align 4
  store float %1, ptr %32, align 4
  store float %2, ptr %33, align 4
  store ptr %40, ptr %34, align 8
  store ptr %41, ptr %35, align 8
  store ptr %42, ptr %36, align 8
  store ptr %43, ptr %37, align 8
  %44 = addrspacecast ptr addrspace(5) %13 to ptr
  %45 = addrspacecast ptr addrspace(5) %10 to ptr
  %46 = call i64 @__ockl_get_group_id(i32 noundef 0) #13
  %47 = trunc i64 %46 to i32
  %48 = addrspacecast ptr addrspace(5) %12 to ptr
  %49 = addrspacecast ptr addrspace(5) %9 to ptr
  %50 = call i64 @__ockl_get_local_size(i32 noundef 0) #13
  %51 = trunc i64 %50 to i32
  %52 = mul i32 %47, %51
  %53 = addrspacecast ptr addrspace(5) %11 to ptr
  %54 = addrspacecast ptr addrspace(5) %8 to ptr
  %55 = call i64 @__ockl_get_local_id(i32 noundef 0) #13
  %56 = trunc i64 %55 to i32
  %57 = add i32 %52, %56
  store i32 %57, ptr %38, align 4
  %58 = load i32, ptr %38, align 4
  %59 = load i32, ptr %31, align 4
  %60 = icmp slt i32 %58, %59
  br i1 %60, label %61, label %104

61:                                               ; preds = %7
  store i32 0, ptr %39, align 4
  br label %62

62:                                               ; preds = %89, %61
  %63 = load i32, ptr %39, align 4
  %64 = load i32, ptr %31, align 4
  %65 = icmp slt i32 %63, %64
  br i1 %65, label %66, label %92

66:                                               ; preds = %62
  %67 = load float, ptr %33, align 4
  %68 = load ptr, ptr %34, align 8
  %69 = load i32, ptr %39, align 4
  %70 = mul nsw i32 %69, 4096
  %71 = load i32, ptr %38, align 4
  %72 = add nsw i32 %70, %71
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds float, ptr %68, i64 %73
  %75 = load float, ptr %74, align 4
  %76 = fmul contract float %67, %75
  %77 = load ptr, ptr %36, align 8
  %78 = load i32, ptr %39, align 4
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds float, ptr %77, i64 %79
  %81 = load float, ptr %80, align 4
  %82 = fmul contract float %76, %81
  %83 = load ptr, ptr %35, align 8
  %84 = load i32, ptr %38, align 4
  %85 = sext i32 %84 to i64
  %86 = getelementptr inbounds float, ptr %83, i64 %85
  %87 = load float, ptr %86, align 4
  %88 = fadd contract float %87, %82
  store float %88, ptr %86, align 4
  br label %89

89:                                               ; preds = %66
  %90 = load i32, ptr %39, align 4
  %91 = add nsw i32 %90, 1
  store i32 %91, ptr %39, align 4
  br label %62, !llvm.loop !13

92:                                               ; preds = %62
  %93 = load ptr, ptr %37, align 8
  %94 = load i32, ptr %38, align 4
  %95 = sext i32 %94 to i64
  %96 = getelementptr inbounds float, ptr %93, i64 %95
  %97 = load float, ptr %96, align 4
  %98 = load ptr, ptr %35, align 8
  %99 = load i32, ptr %38, align 4
  %100 = sext i32 %99 to i64
  %101 = getelementptr inbounds float, ptr %98, i64 %100
  %102 = load float, ptr %101, align 4
  %103 = fadd contract float %102, %97
  store float %103, ptr %101, align 4
  br label %104

104:                                              ; preds = %92, %7
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define protected amdgpu_kernel void @_Z14gemver_kernel3iffPfS_S_(i32 noundef %0, float noundef %1, float noundef %2, ptr addrspace(1) noundef %3, ptr addrspace(1) noundef %4, ptr addrspace(1) noundef %5) #4 {
  %7 = alloca i32, align 4, addrspace(5)
  %8 = alloca i32, align 4, addrspace(5)
  %9 = alloca i32, align 4, addrspace(5)
  %10 = alloca i32, align 4, addrspace(5)
  %11 = alloca i32, align 4, addrspace(5)
  %12 = alloca i32, align 4, addrspace(5)
  %13 = alloca ptr, align 8, addrspace(5)
  %14 = alloca ptr, align 8, addrspace(5)
  %15 = alloca ptr, align 8, addrspace(5)
  %16 = alloca i32, align 4, addrspace(5)
  %17 = alloca float, align 4, addrspace(5)
  %18 = alloca float, align 4, addrspace(5)
  %19 = alloca ptr, align 8, addrspace(5)
  %20 = alloca ptr, align 8, addrspace(5)
  %21 = alloca ptr, align 8, addrspace(5)
  %22 = alloca i32, align 4, addrspace(5)
  %23 = alloca i32, align 4, addrspace(5)
  %24 = addrspacecast ptr addrspace(5) %13 to ptr
  %25 = addrspacecast ptr addrspace(5) %14 to ptr
  %26 = addrspacecast ptr addrspace(5) %15 to ptr
  %27 = addrspacecast ptr addrspace(5) %16 to ptr
  %28 = addrspacecast ptr addrspace(5) %17 to ptr
  %29 = addrspacecast ptr addrspace(5) %18 to ptr
  %30 = addrspacecast ptr addrspace(5) %19 to ptr
  %31 = addrspacecast ptr addrspace(5) %20 to ptr
  %32 = addrspacecast ptr addrspace(5) %21 to ptr
  %33 = addrspacecast ptr addrspace(5) %22 to ptr
  %34 = addrspacecast ptr addrspace(5) %23 to ptr
  store ptr addrspace(1) %3, ptr %24, align 8
  %35 = load ptr, ptr %24, align 8
  store ptr addrspace(1) %4, ptr %25, align 8
  %36 = load ptr, ptr %25, align 8
  store ptr addrspace(1) %5, ptr %26, align 8
  %37 = load ptr, ptr %26, align 8
  store i32 %0, ptr %27, align 4
  store float %1, ptr %28, align 4
  store float %2, ptr %29, align 4
  store ptr %35, ptr %30, align 8
  store ptr %36, ptr %31, align 8
  store ptr %37, ptr %32, align 8
  %38 = addrspacecast ptr addrspace(5) %12 to ptr
  %39 = addrspacecast ptr addrspace(5) %9 to ptr
  %40 = call i64 @__ockl_get_group_id(i32 noundef 0) #13
  %41 = trunc i64 %40 to i32
  %42 = addrspacecast ptr addrspace(5) %11 to ptr
  %43 = addrspacecast ptr addrspace(5) %8 to ptr
  %44 = call i64 @__ockl_get_local_size(i32 noundef 0) #13
  %45 = trunc i64 %44 to i32
  %46 = mul i32 %41, %45
  %47 = addrspacecast ptr addrspace(5) %10 to ptr
  %48 = addrspacecast ptr addrspace(5) %7 to ptr
  %49 = call i64 @__ockl_get_local_id(i32 noundef 0) #13
  %50 = trunc i64 %49 to i32
  %51 = add i32 %46, %50
  store i32 %51, ptr %33, align 4
  %52 = load i32, ptr %33, align 4
  %53 = icmp sge i32 %52, 0
  br i1 %53, label %54, label %90

54:                                               ; preds = %6
  %55 = load i32, ptr %33, align 4
  %56 = load i32, ptr %27, align 4
  %57 = icmp slt i32 %55, %56
  br i1 %57, label %58, label %90

58:                                               ; preds = %54
  store i32 0, ptr %34, align 4
  br label %59

59:                                               ; preds = %86, %58
  %60 = load i32, ptr %34, align 4
  %61 = load i32, ptr %27, align 4
  %62 = icmp slt i32 %60, %61
  br i1 %62, label %63, label %89

63:                                               ; preds = %59
  %64 = load float, ptr %28, align 4
  %65 = load ptr, ptr %30, align 8
  %66 = load i32, ptr %33, align 4
  %67 = mul nsw i32 %66, 4096
  %68 = load i32, ptr %34, align 4
  %69 = add nsw i32 %67, %68
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds float, ptr %65, i64 %70
  %72 = load float, ptr %71, align 4
  %73 = fmul contract float %64, %72
  %74 = load ptr, ptr %31, align 8
  %75 = load i32, ptr %34, align 4
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds float, ptr %74, i64 %76
  %78 = load float, ptr %77, align 4
  %79 = fmul contract float %73, %78
  %80 = load ptr, ptr %32, align 8
  %81 = load i32, ptr %33, align 4
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds float, ptr %80, i64 %82
  %84 = load float, ptr %83, align 4
  %85 = fadd contract float %84, %79
  store float %85, ptr %83, align 4
  br label %86

86:                                               ; preds = %63
  %87 = load i32, ptr %34, align 4
  %88 = add nsw i32 %87, 1
  store i32 %88, ptr %34, align 4
  br label %59, !llvm.loop !14

89:                                               ; preds = %59
  br label %90

90:                                               ; preds = %89, %54, %6
  ret void
}

; Function Attrs: convergent mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define internal i64 @__ockl_get_local_id(i32 noundef %0) #5 {
  switch i32 %0, label %8 [
    i32 0, label %2
    i32 1, label %4
    i32 2, label %6
  ]

2:                                                ; preds = %1
  %3 = tail call i32 @llvm.amdgcn.workitem.id.x(), !range !15, !noundef !16
  br label %8

4:                                                ; preds = %1
  %5 = tail call i32 @llvm.amdgcn.workitem.id.y(), !range !15, !noundef !16
  br label %8

6:                                                ; preds = %1
  %7 = tail call i32 @llvm.amdgcn.workitem.id.z(), !range !15, !noundef !16
  br label %8

8:                                                ; preds = %6, %4, %2, %1
  %9 = phi i32 [ %7, %6 ], [ %5, %4 ], [ %3, %2 ], [ 0, %1 ]
  %10 = zext nneg i32 %9 to i64
  ret i64 %10
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workitem.id.x() #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workitem.id.y() #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workitem.id.z() #6

; Function Attrs: convergent norecurse nounwind
define internal i64 @__ockl_fprintf_stderr_begin() #7 {
  %1 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef 33, i64 noundef 1, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0) #12
  %2 = extractelement <2 x i64> %1, i64 0
  ret i64 %2
}

; Function Attrs: convergent norecurse nounwind
define internal <2 x i64> @__ockl_hostcall_preview(i32 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) local_unnamed_addr #7 {
  %10 = load i32, ptr addrspace(4) @__oclc_ABI_version, align 4, !tbaa !17
  %11 = icmp slt i32 %10, 500
  %12 = tail call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %13 = select i1 %11, i64 3, i64 10
  %14 = getelementptr inbounds i64, ptr addrspace(4) %12, i64 %13
  %15 = load i64, ptr addrspace(4) %14, align 8, !tbaa !21
  %16 = inttoptr i64 %15 to ptr addrspace(1)
  %17 = addrspacecast ptr addrspace(1) %16 to ptr
  %18 = tail call <2 x i64> @__ockl_hostcall_internal(ptr noundef %17, i32 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) #14
  ret <2 x i64> %18
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef align 4 ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr() #6

; Function Attrs: convergent norecurse nounwind
define internal <2 x i64> @__ockl_hostcall_internal(ptr nocapture noundef %0, i32 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i64 noundef %9) local_unnamed_addr #7 {
  %11 = tail call i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0)
  %12 = tail call i32 @llvm.amdgcn.mbcnt.hi(i32 -1, i32 %11)
  %13 = tail call i32 asm sideeffect "", "=v,0"(i32 %12) #12, !srcloc !23
  %14 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %13)
  %15 = addrspacecast ptr %0 to ptr addrspace(1)
  %16 = icmp eq i32 %13, %14
  br i1 %16, label %17, label %39

17:                                               ; preds = %10
  %18 = getelementptr inbounds %0, ptr addrspace(1) %15, i64 0, i32 3
  %19 = load atomic i64, ptr addrspace(1) %18 syncscope("one-as") acquire, align 8
  %20 = getelementptr i8, ptr addrspace(1) %15, i64 40
  %21 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !24
  %22 = load i64, ptr addrspace(1) %20, align 8, !tbaa !28
  %23 = and i64 %22, %19
  %24 = getelementptr inbounds %2, ptr addrspace(1) %21, i64 %23
  %25 = load atomic i64, ptr addrspace(1) %24 syncscope("one-as") monotonic, align 8
  %26 = cmpxchg ptr addrspace(1) %18, i64 %19, i64 %25 syncscope("one-as") acquire monotonic, align 8
  %27 = extractvalue { i64, i1 } %26, 1
  %28 = extractvalue { i64, i1 } %26, 0
  br i1 %27, label %39, label %29

29:                                               ; preds = %29, %17
  %30 = phi i64 [ %38, %29 ], [ %28, %17 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %31 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !24
  %32 = load i64, ptr addrspace(1) %20, align 8, !tbaa !28
  %33 = and i64 %32, %30
  %34 = getelementptr inbounds %2, ptr addrspace(1) %31, i64 %33
  %35 = load atomic i64, ptr addrspace(1) %34 syncscope("one-as") monotonic, align 8
  %36 = cmpxchg ptr addrspace(1) %18, i64 %30, i64 %35 syncscope("one-as") acquire monotonic, align 8
  %37 = extractvalue { i64, i1 } %36, 1
  %38 = extractvalue { i64, i1 } %36, 0
  br i1 %37, label %39, label %29

39:                                               ; preds = %29, %17, %10
  %40 = phi i64 [ 0, %10 ], [ %28, %17 ], [ %38, %29 ]
  %41 = trunc i64 %40 to i32
  %42 = lshr i64 %40, 32
  %43 = trunc i64 %42 to i32
  %44 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %41)
  %45 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %43)
  %46 = zext i32 %45 to i64
  %47 = shl nuw i64 %46, 32
  %48 = zext i32 %44 to i64
  %49 = or disjoint i64 %47, %48
  %50 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !24
  %51 = getelementptr i8, ptr addrspace(1) %15, i64 40
  %52 = load i64, ptr addrspace(1) %51, align 8, !tbaa !28
  %53 = and i64 %49, %52
  %54 = getelementptr i8, ptr addrspace(1) %15, i64 8
  %55 = load ptr addrspace(1), ptr addrspace(1) %54, align 8, !tbaa !29
  %56 = getelementptr inbounds %3, ptr addrspace(1) %55, i64 %53
  %57 = tail call i64 @llvm.amdgcn.ballot.i64(i1 true)
  br i1 %16, label %58, label %62

58:                                               ; preds = %39
  %59 = getelementptr inbounds %2, ptr addrspace(1) %50, i64 %53, i32 2
  %60 = getelementptr inbounds %2, ptr addrspace(1) %50, i64 %53, i32 1
  %61 = getelementptr inbounds %2, ptr addrspace(1) %50, i64 %53, i32 3
  store i32 %1, ptr addrspace(1) %59, align 8, !tbaa !30
  store i64 %57, ptr addrspace(1) %60, align 8, !tbaa !32
  store i32 1, ptr addrspace(1) %61, align 4, !tbaa !33
  br label %62

62:                                               ; preds = %58, %39
  %63 = zext i32 %13 to i64
  %64 = getelementptr inbounds [64 x [8 x i64]], ptr addrspace(1) %56, i64 0, i64 %63
  store i64 %2, ptr addrspace(1) %64, align 8, !tbaa !21
  %65 = getelementptr inbounds i64, ptr addrspace(1) %64, i64 1
  store i64 %3, ptr addrspace(1) %65, align 8, !tbaa !21
  %66 = getelementptr inbounds i64, ptr addrspace(1) %64, i64 2
  store i64 %4, ptr addrspace(1) %66, align 8, !tbaa !21
  %67 = getelementptr inbounds i64, ptr addrspace(1) %64, i64 3
  store i64 %5, ptr addrspace(1) %67, align 8, !tbaa !21
  %68 = getelementptr inbounds i64, ptr addrspace(1) %64, i64 4
  store i64 %6, ptr addrspace(1) %68, align 8, !tbaa !21
  %69 = getelementptr inbounds i64, ptr addrspace(1) %64, i64 5
  store i64 %7, ptr addrspace(1) %69, align 8, !tbaa !21
  %70 = getelementptr inbounds i64, ptr addrspace(1) %64, i64 6
  store i64 %8, ptr addrspace(1) %70, align 8, !tbaa !21
  %71 = getelementptr inbounds i64, ptr addrspace(1) %64, i64 7
  store i64 %9, ptr addrspace(1) %71, align 8, !tbaa !21
  br i1 %16, label %72, label %88

72:                                               ; preds = %62
  %73 = getelementptr inbounds %0, ptr addrspace(1) %15, i64 0, i32 4
  %74 = load atomic i64, ptr addrspace(1) %73 syncscope("one-as") monotonic, align 8
  %75 = load i64, ptr addrspace(1) %51, align 8, !tbaa !28
  %76 = and i64 %75, %49
  %77 = getelementptr inbounds %2, ptr addrspace(1) %50, i64 %76
  store i64 %74, ptr addrspace(1) %77, align 8, !tbaa !34
  %78 = cmpxchg ptr addrspace(1) %73, i64 %74, i64 %49 syncscope("one-as") release monotonic, align 8
  %79 = extractvalue { i64, i1 } %78, 1
  br i1 %79, label %85, label %80

80:                                               ; preds = %80, %72
  %81 = phi { i64, i1 } [ %83, %80 ], [ %78, %72 ]
  %82 = extractvalue { i64, i1 } %81, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %82, ptr addrspace(1) %77, align 8, !tbaa !34
  %83 = cmpxchg ptr addrspace(1) %73, i64 %82, i64 %49 syncscope("one-as") release monotonic, align 8
  %84 = extractvalue { i64, i1 } %83, 1
  br i1 %84, label %85, label %80

85:                                               ; preds = %80, %72
  %86 = getelementptr inbounds %0, ptr addrspace(1) %15, i64 0, i32 2
  %87 = load i64, ptr addrspace(1) %86, align 8
  tail call void @__ockl_hsa_signal_add(i64 %87, i64 noundef 1, i32 noundef 3) #12
  br label %88

88:                                               ; preds = %85, %62
  %89 = getelementptr inbounds %2, ptr addrspace(1) %50, i64 %53, i32 3
  br label %90

90:                                               ; preds = %98, %88
  br i1 %16, label %91, label %94

91:                                               ; preds = %90
  %92 = load atomic i32, ptr addrspace(1) %89 syncscope("one-as") acquire, align 4
  %93 = and i32 %92, 1
  br label %94

94:                                               ; preds = %91, %90
  %95 = phi i32 [ %93, %91 ], [ 1, %90 ]
  %96 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %95)
  %97 = icmp eq i32 %96, 0
  br i1 %97, label %99, label %98

98:                                               ; preds = %94
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %90

99:                                               ; preds = %94
  %100 = load i64, ptr addrspace(1) %64, align 8, !tbaa !21
  %101 = load i64, ptr addrspace(1) %65, align 8, !tbaa !21
  br i1 %16, label %102, label %120

102:                                              ; preds = %99
  %103 = load i64, ptr addrspace(1) %51, align 8, !tbaa !28
  %104 = add i64 %103, 1
  %105 = add i64 %104, %49
  %106 = icmp eq i64 %105, 0
  %107 = select i1 %106, i64 %104, i64 %105
  %108 = getelementptr inbounds %0, ptr addrspace(1) %15, i64 0, i32 3
  %109 = load atomic i64, ptr addrspace(1) %108 syncscope("one-as") monotonic, align 8
  %110 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !24
  %111 = and i64 %107, %103
  %112 = getelementptr inbounds %2, ptr addrspace(1) %110, i64 %111
  store i64 %109, ptr addrspace(1) %112, align 8, !tbaa !34
  %113 = cmpxchg ptr addrspace(1) %108, i64 %109, i64 %107 syncscope("one-as") release monotonic, align 8
  %114 = extractvalue { i64, i1 } %113, 1
  br i1 %114, label %120, label %115

115:                                              ; preds = %115, %102
  %116 = phi { i64, i1 } [ %118, %115 ], [ %113, %102 ]
  %117 = extractvalue { i64, i1 } %116, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %117, ptr addrspace(1) %112, align 8, !tbaa !34
  %118 = cmpxchg ptr addrspace(1) %108, i64 %117, i64 %107 syncscope("one-as") release monotonic, align 8
  %119 = extractvalue { i64, i1 } %118, 1
  br i1 %119, label %120, label %115

120:                                              ; preds = %115, %102, %99
  %121 = insertelement <2 x i64> poison, i64 %100, i64 0
  %122 = insertelement <2 x i64> %121, i64 %101, i64 1
  ret <2 x i64> %122
}

; Function Attrs: convergent nocallback nofree nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.readfirstlane.i32(i32) #8

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.amdgcn.s.sleep(i32 immarg) #9

; Function Attrs: convergent nocallback nofree nounwind willreturn memory(none)
declare i64 @llvm.amdgcn.ballot.i64(i1) #8

; Function Attrs: convergent norecurse nounwind
define internal void @__ockl_hsa_signal_add(i64 %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #7 {
  %4 = inttoptr i64 %0 to ptr addrspace(1)
  %5 = getelementptr inbounds %4, ptr addrspace(1) %4, i64 0, i32 1
  switch i32 %2, label %6 [
    i32 1, label %8
    i32 2, label %8
    i32 3, label %10
    i32 4, label %12
    i32 5, label %14
  ]

6:                                                ; preds = %3
  %7 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") monotonic, align 8
  br label %16

8:                                                ; preds = %3, %3
  %9 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") acquire, align 8
  br label %16

10:                                               ; preds = %3
  %11 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") release, align 8
  br label %16

12:                                               ; preds = %3
  %13 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") acq_rel, align 8
  br label %16

14:                                               ; preds = %3
  %15 = atomicrmw add ptr addrspace(1) %5, i64 %1 seq_cst, align 8
  br label %16

16:                                               ; preds = %14, %12, %10, %8, %6
  %17 = getelementptr inbounds %4, ptr addrspace(1) %4, i64 0, i32 2
  %18 = load i64, ptr addrspace(1) %17, align 16, !tbaa !35
  %19 = icmp eq i64 %18, 0
  br i1 %19, label %27, label %20

20:                                               ; preds = %16
  %21 = inttoptr i64 %18 to ptr addrspace(1)
  %22 = getelementptr inbounds %4, ptr addrspace(1) %4, i64 0, i32 3
  %23 = load i32, ptr addrspace(1) %22, align 8, !tbaa !37
  %24 = zext i32 %23 to i64
  store atomic i64 %24, ptr addrspace(1) %21 syncscope("one-as") release, align 8
  %25 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %23)
  %26 = and i32 %25, 255
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %26)
  br label %27

27:                                               ; preds = %20, %16
  ret void
}

; Function Attrs: nounwind
declare void @llvm.amdgcn.s.sendmsg(i32 immarg, i32) #10

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.mbcnt.lo(i32, i32) #11

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.mbcnt.hi(i32, i32) #11

; Function Attrs: convergent norecurse nounwind
define internal i64 @__ockl_fprintf_append_args(i64 noundef %0, i32 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i32 noundef %9) #7 {
  %11 = icmp eq i32 %9, 0
  %12 = or i64 %0, 2
  %13 = select i1 %11, i64 %0, i64 %12
  %14 = and i64 %13, -225
  %15 = zext i32 %1 to i64
  %16 = shl nuw nsw i64 %15, 5
  %17 = or i64 %14, %16
  %18 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %17, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) #12
  %19 = extractelement <2 x i64> %18, i64 0
  ret i64 %19
}

; Function Attrs: convergent norecurse nounwind
define internal i64 @__ockl_fprintf_append_string_n(i64 noundef %0, ptr noundef readonly %1, i64 noundef %2, i32 noundef %3) #7 {
  %5 = icmp eq i32 %3, 0
  %6 = or i64 %0, 2
  %7 = select i1 %5, i64 %0, i64 %6
  %8 = icmp eq ptr %1, null
  br i1 %8, label %9, label %13

9:                                                ; preds = %4
  %10 = and i64 %7, -225
  %11 = or disjoint i64 %10, 32
  %12 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %11, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0) #12
  br label %454

13:                                               ; preds = %4
  %14 = and i64 %7, 2
  %15 = and i64 %7, -3
  %16 = insertelement <2 x i64> <i64 poison, i64 0>, i64 %15, i64 0
  br label %17

17:                                               ; preds = %443, %13
  %18 = phi i64 [ %2, %13 ], [ %451, %443 ]
  %19 = phi ptr [ %1, %13 ], [ %452, %443 ]
  %20 = phi <2 x i64> [ %16, %13 ], [ %450, %443 ]
  %21 = icmp ugt i64 %18, 56
  %22 = extractelement <2 x i64> %20, i64 0
  %23 = or i64 %22, %14
  %24 = insertelement <2 x i64> poison, i64 %23, i64 0
  %25 = select i1 %21, <2 x i64> %20, <2 x i64> %24
  %26 = tail call i64 @llvm.umin.i64(i64 %18, i64 56)
  %27 = trunc i64 %26 to i32
  %28 = extractelement <2 x i64> %25, i64 0
  %29 = icmp ugt i32 %27, 7
  br i1 %29, label %32, label %30

30:                                               ; preds = %17
  %31 = icmp eq i32 %27, 0
  br i1 %31, label %85, label %72

32:                                               ; preds = %17
  %33 = load i8, ptr %19, align 1, !tbaa !38
  %34 = zext i8 %33 to i64
  %35 = getelementptr inbounds i8, ptr %19, i64 1
  %36 = load i8, ptr %35, align 1, !tbaa !38
  %37 = zext i8 %36 to i64
  %38 = shl nuw nsw i64 %37, 8
  %39 = or disjoint i64 %38, %34
  %40 = getelementptr inbounds i8, ptr %19, i64 2
  %41 = load i8, ptr %40, align 1, !tbaa !38
  %42 = zext i8 %41 to i64
  %43 = shl nuw nsw i64 %42, 16
  %44 = or disjoint i64 %39, %43
  %45 = getelementptr inbounds i8, ptr %19, i64 3
  %46 = load i8, ptr %45, align 1, !tbaa !38
  %47 = zext i8 %46 to i64
  %48 = shl nuw nsw i64 %47, 24
  %49 = or disjoint i64 %44, %48
  %50 = getelementptr inbounds i8, ptr %19, i64 4
  %51 = load i8, ptr %50, align 1, !tbaa !38
  %52 = zext i8 %51 to i64
  %53 = shl nuw nsw i64 %52, 32
  %54 = or disjoint i64 %49, %53
  %55 = getelementptr inbounds i8, ptr %19, i64 5
  %56 = load i8, ptr %55, align 1, !tbaa !38
  %57 = zext i8 %56 to i64
  %58 = shl nuw nsw i64 %57, 40
  %59 = or i64 %54, %58
  %60 = getelementptr inbounds i8, ptr %19, i64 6
  %61 = load i8, ptr %60, align 1, !tbaa !38
  %62 = zext i8 %61 to i64
  %63 = shl nuw nsw i64 %62, 48
  %64 = or i64 %59, %63
  %65 = getelementptr inbounds i8, ptr %19, i64 7
  %66 = load i8, ptr %65, align 1, !tbaa !38
  %67 = zext i8 %66 to i64
  %68 = shl nuw i64 %67, 56
  %69 = or i64 %64, %68
  %70 = add nsw i32 %27, -8
  %71 = getelementptr inbounds i8, ptr %19, i64 8
  br label %85

72:                                               ; preds = %72, %30
  %73 = phi i32 [ %83, %72 ], [ 0, %30 ]
  %74 = phi i64 [ %82, %72 ], [ 0, %30 ]
  %75 = zext nneg i32 %73 to i64
  %76 = getelementptr inbounds i8, ptr %19, i64 %75
  %77 = load i8, ptr %76, align 1, !tbaa !38
  %78 = zext i8 %77 to i64
  %79 = shl i32 %73, 3
  %80 = zext nneg i32 %79 to i64
  %81 = shl nuw i64 %78, %80
  %82 = or i64 %81, %74
  %83 = add nuw nsw i32 %73, 1
  %84 = icmp eq i32 %83, %27
  br i1 %84, label %85, label %72

85:                                               ; preds = %72, %32, %30
  %86 = phi ptr [ %71, %32 ], [ %19, %30 ], [ %19, %72 ]
  %87 = phi i32 [ %70, %32 ], [ 0, %30 ], [ 0, %72 ]
  %88 = phi i64 [ %69, %32 ], [ 0, %30 ], [ %82, %72 ]
  %89 = icmp ugt i32 %87, 7
  br i1 %89, label %92, label %90

90:                                               ; preds = %85
  %91 = icmp eq i32 %87, 0
  br i1 %91, label %145, label %132

92:                                               ; preds = %85
  %93 = load i8, ptr %86, align 1, !tbaa !38
  %94 = zext i8 %93 to i64
  %95 = getelementptr inbounds i8, ptr %86, i64 1
  %96 = load i8, ptr %95, align 1, !tbaa !38
  %97 = zext i8 %96 to i64
  %98 = shl nuw nsw i64 %97, 8
  %99 = or disjoint i64 %98, %94
  %100 = getelementptr inbounds i8, ptr %86, i64 2
  %101 = load i8, ptr %100, align 1, !tbaa !38
  %102 = zext i8 %101 to i64
  %103 = shl nuw nsw i64 %102, 16
  %104 = or disjoint i64 %99, %103
  %105 = getelementptr inbounds i8, ptr %86, i64 3
  %106 = load i8, ptr %105, align 1, !tbaa !38
  %107 = zext i8 %106 to i64
  %108 = shl nuw nsw i64 %107, 24
  %109 = or disjoint i64 %104, %108
  %110 = getelementptr inbounds i8, ptr %86, i64 4
  %111 = load i8, ptr %110, align 1, !tbaa !38
  %112 = zext i8 %111 to i64
  %113 = shl nuw nsw i64 %112, 32
  %114 = or disjoint i64 %109, %113
  %115 = getelementptr inbounds i8, ptr %86, i64 5
  %116 = load i8, ptr %115, align 1, !tbaa !38
  %117 = zext i8 %116 to i64
  %118 = shl nuw nsw i64 %117, 40
  %119 = or i64 %114, %118
  %120 = getelementptr inbounds i8, ptr %86, i64 6
  %121 = load i8, ptr %120, align 1, !tbaa !38
  %122 = zext i8 %121 to i64
  %123 = shl nuw nsw i64 %122, 48
  %124 = or i64 %119, %123
  %125 = getelementptr inbounds i8, ptr %86, i64 7
  %126 = load i8, ptr %125, align 1, !tbaa !38
  %127 = zext i8 %126 to i64
  %128 = shl nuw i64 %127, 56
  %129 = or i64 %124, %128
  %130 = add nsw i32 %87, -8
  %131 = getelementptr inbounds i8, ptr %86, i64 8
  br label %145

132:                                              ; preds = %132, %90
  %133 = phi i32 [ %143, %132 ], [ 0, %90 ]
  %134 = phi i64 [ %142, %132 ], [ 0, %90 ]
  %135 = zext nneg i32 %133 to i64
  %136 = getelementptr inbounds i8, ptr %86, i64 %135
  %137 = load i8, ptr %136, align 1, !tbaa !38
  %138 = zext i8 %137 to i64
  %139 = shl i32 %133, 3
  %140 = zext nneg i32 %139 to i64
  %141 = shl nuw i64 %138, %140
  %142 = or i64 %141, %134
  %143 = add nuw nsw i32 %133, 1
  %144 = icmp eq i32 %143, %87
  br i1 %144, label %145, label %132

145:                                              ; preds = %132, %92, %90
  %146 = phi ptr [ %131, %92 ], [ %86, %90 ], [ %86, %132 ]
  %147 = phi i32 [ %130, %92 ], [ 0, %90 ], [ 0, %132 ]
  %148 = phi i64 [ %129, %92 ], [ 0, %90 ], [ %142, %132 ]
  %149 = icmp ugt i32 %147, 7
  br i1 %149, label %152, label %150

150:                                              ; preds = %145
  %151 = icmp eq i32 %147, 0
  br i1 %151, label %205, label %192

152:                                              ; preds = %145
  %153 = load i8, ptr %146, align 1, !tbaa !38
  %154 = zext i8 %153 to i64
  %155 = getelementptr inbounds i8, ptr %146, i64 1
  %156 = load i8, ptr %155, align 1, !tbaa !38
  %157 = zext i8 %156 to i64
  %158 = shl nuw nsw i64 %157, 8
  %159 = or disjoint i64 %158, %154
  %160 = getelementptr inbounds i8, ptr %146, i64 2
  %161 = load i8, ptr %160, align 1, !tbaa !38
  %162 = zext i8 %161 to i64
  %163 = shl nuw nsw i64 %162, 16
  %164 = or disjoint i64 %159, %163
  %165 = getelementptr inbounds i8, ptr %146, i64 3
  %166 = load i8, ptr %165, align 1, !tbaa !38
  %167 = zext i8 %166 to i64
  %168 = shl nuw nsw i64 %167, 24
  %169 = or disjoint i64 %164, %168
  %170 = getelementptr inbounds i8, ptr %146, i64 4
  %171 = load i8, ptr %170, align 1, !tbaa !38
  %172 = zext i8 %171 to i64
  %173 = shl nuw nsw i64 %172, 32
  %174 = or disjoint i64 %169, %173
  %175 = getelementptr inbounds i8, ptr %146, i64 5
  %176 = load i8, ptr %175, align 1, !tbaa !38
  %177 = zext i8 %176 to i64
  %178 = shl nuw nsw i64 %177, 40
  %179 = or i64 %174, %178
  %180 = getelementptr inbounds i8, ptr %146, i64 6
  %181 = load i8, ptr %180, align 1, !tbaa !38
  %182 = zext i8 %181 to i64
  %183 = shl nuw nsw i64 %182, 48
  %184 = or i64 %179, %183
  %185 = getelementptr inbounds i8, ptr %146, i64 7
  %186 = load i8, ptr %185, align 1, !tbaa !38
  %187 = zext i8 %186 to i64
  %188 = shl nuw i64 %187, 56
  %189 = or i64 %184, %188
  %190 = add nsw i32 %147, -8
  %191 = getelementptr inbounds i8, ptr %146, i64 8
  br label %205

192:                                              ; preds = %192, %150
  %193 = phi i32 [ %203, %192 ], [ 0, %150 ]
  %194 = phi i64 [ %202, %192 ], [ 0, %150 ]
  %195 = zext nneg i32 %193 to i64
  %196 = getelementptr inbounds i8, ptr %146, i64 %195
  %197 = load i8, ptr %196, align 1, !tbaa !38
  %198 = zext i8 %197 to i64
  %199 = shl i32 %193, 3
  %200 = zext nneg i32 %199 to i64
  %201 = shl nuw i64 %198, %200
  %202 = or i64 %201, %194
  %203 = add nuw nsw i32 %193, 1
  %204 = icmp eq i32 %203, %147
  br i1 %204, label %205, label %192

205:                                              ; preds = %192, %152, %150
  %206 = phi ptr [ %191, %152 ], [ %146, %150 ], [ %146, %192 ]
  %207 = phi i32 [ %190, %152 ], [ 0, %150 ], [ 0, %192 ]
  %208 = phi i64 [ %189, %152 ], [ 0, %150 ], [ %202, %192 ]
  %209 = icmp ugt i32 %207, 7
  br i1 %209, label %212, label %210

210:                                              ; preds = %205
  %211 = icmp eq i32 %207, 0
  br i1 %211, label %265, label %252

212:                                              ; preds = %205
  %213 = load i8, ptr %206, align 1, !tbaa !38
  %214 = zext i8 %213 to i64
  %215 = getelementptr inbounds i8, ptr %206, i64 1
  %216 = load i8, ptr %215, align 1, !tbaa !38
  %217 = zext i8 %216 to i64
  %218 = shl nuw nsw i64 %217, 8
  %219 = or disjoint i64 %218, %214
  %220 = getelementptr inbounds i8, ptr %206, i64 2
  %221 = load i8, ptr %220, align 1, !tbaa !38
  %222 = zext i8 %221 to i64
  %223 = shl nuw nsw i64 %222, 16
  %224 = or disjoint i64 %219, %223
  %225 = getelementptr inbounds i8, ptr %206, i64 3
  %226 = load i8, ptr %225, align 1, !tbaa !38
  %227 = zext i8 %226 to i64
  %228 = shl nuw nsw i64 %227, 24
  %229 = or disjoint i64 %224, %228
  %230 = getelementptr inbounds i8, ptr %206, i64 4
  %231 = load i8, ptr %230, align 1, !tbaa !38
  %232 = zext i8 %231 to i64
  %233 = shl nuw nsw i64 %232, 32
  %234 = or disjoint i64 %229, %233
  %235 = getelementptr inbounds i8, ptr %206, i64 5
  %236 = load i8, ptr %235, align 1, !tbaa !38
  %237 = zext i8 %236 to i64
  %238 = shl nuw nsw i64 %237, 40
  %239 = or i64 %234, %238
  %240 = getelementptr inbounds i8, ptr %206, i64 6
  %241 = load i8, ptr %240, align 1, !tbaa !38
  %242 = zext i8 %241 to i64
  %243 = shl nuw nsw i64 %242, 48
  %244 = or i64 %239, %243
  %245 = getelementptr inbounds i8, ptr %206, i64 7
  %246 = load i8, ptr %245, align 1, !tbaa !38
  %247 = zext i8 %246 to i64
  %248 = shl nuw i64 %247, 56
  %249 = or i64 %244, %248
  %250 = add nsw i32 %207, -8
  %251 = getelementptr inbounds i8, ptr %206, i64 8
  br label %265

252:                                              ; preds = %252, %210
  %253 = phi i32 [ %263, %252 ], [ 0, %210 ]
  %254 = phi i64 [ %262, %252 ], [ 0, %210 ]
  %255 = zext nneg i32 %253 to i64
  %256 = getelementptr inbounds i8, ptr %206, i64 %255
  %257 = load i8, ptr %256, align 1, !tbaa !38
  %258 = zext i8 %257 to i64
  %259 = shl i32 %253, 3
  %260 = zext nneg i32 %259 to i64
  %261 = shl nuw i64 %258, %260
  %262 = or i64 %261, %254
  %263 = add nuw nsw i32 %253, 1
  %264 = icmp eq i32 %263, %207
  br i1 %264, label %265, label %252

265:                                              ; preds = %252, %212, %210
  %266 = phi ptr [ %251, %212 ], [ %206, %210 ], [ %206, %252 ]
  %267 = phi i32 [ %250, %212 ], [ 0, %210 ], [ 0, %252 ]
  %268 = phi i64 [ %249, %212 ], [ 0, %210 ], [ %262, %252 ]
  %269 = icmp ugt i32 %267, 7
  br i1 %269, label %272, label %270

270:                                              ; preds = %265
  %271 = icmp eq i32 %267, 0
  br i1 %271, label %325, label %312

272:                                              ; preds = %265
  %273 = load i8, ptr %266, align 1, !tbaa !38
  %274 = zext i8 %273 to i64
  %275 = getelementptr inbounds i8, ptr %266, i64 1
  %276 = load i8, ptr %275, align 1, !tbaa !38
  %277 = zext i8 %276 to i64
  %278 = shl nuw nsw i64 %277, 8
  %279 = or disjoint i64 %278, %274
  %280 = getelementptr inbounds i8, ptr %266, i64 2
  %281 = load i8, ptr %280, align 1, !tbaa !38
  %282 = zext i8 %281 to i64
  %283 = shl nuw nsw i64 %282, 16
  %284 = or disjoint i64 %279, %283
  %285 = getelementptr inbounds i8, ptr %266, i64 3
  %286 = load i8, ptr %285, align 1, !tbaa !38
  %287 = zext i8 %286 to i64
  %288 = shl nuw nsw i64 %287, 24
  %289 = or disjoint i64 %284, %288
  %290 = getelementptr inbounds i8, ptr %266, i64 4
  %291 = load i8, ptr %290, align 1, !tbaa !38
  %292 = zext i8 %291 to i64
  %293 = shl nuw nsw i64 %292, 32
  %294 = or disjoint i64 %289, %293
  %295 = getelementptr inbounds i8, ptr %266, i64 5
  %296 = load i8, ptr %295, align 1, !tbaa !38
  %297 = zext i8 %296 to i64
  %298 = shl nuw nsw i64 %297, 40
  %299 = or i64 %294, %298
  %300 = getelementptr inbounds i8, ptr %266, i64 6
  %301 = load i8, ptr %300, align 1, !tbaa !38
  %302 = zext i8 %301 to i64
  %303 = shl nuw nsw i64 %302, 48
  %304 = or i64 %299, %303
  %305 = getelementptr inbounds i8, ptr %266, i64 7
  %306 = load i8, ptr %305, align 1, !tbaa !38
  %307 = zext i8 %306 to i64
  %308 = shl nuw i64 %307, 56
  %309 = or i64 %304, %308
  %310 = add nsw i32 %267, -8
  %311 = getelementptr inbounds i8, ptr %266, i64 8
  br label %325

312:                                              ; preds = %312, %270
  %313 = phi i32 [ %323, %312 ], [ 0, %270 ]
  %314 = phi i64 [ %322, %312 ], [ 0, %270 ]
  %315 = zext nneg i32 %313 to i64
  %316 = getelementptr inbounds i8, ptr %266, i64 %315
  %317 = load i8, ptr %316, align 1, !tbaa !38
  %318 = zext i8 %317 to i64
  %319 = shl i32 %313, 3
  %320 = zext nneg i32 %319 to i64
  %321 = shl nuw i64 %318, %320
  %322 = or i64 %321, %314
  %323 = add nuw nsw i32 %313, 1
  %324 = icmp eq i32 %323, %267
  br i1 %324, label %325, label %312

325:                                              ; preds = %312, %272, %270
  %326 = phi ptr [ %311, %272 ], [ %266, %270 ], [ %266, %312 ]
  %327 = phi i32 [ %310, %272 ], [ 0, %270 ], [ 0, %312 ]
  %328 = phi i64 [ %309, %272 ], [ 0, %270 ], [ %322, %312 ]
  %329 = icmp ugt i32 %327, 7
  br i1 %329, label %332, label %330

330:                                              ; preds = %325
  %331 = icmp eq i32 %327, 0
  br i1 %331, label %385, label %372

332:                                              ; preds = %325
  %333 = load i8, ptr %326, align 1, !tbaa !38
  %334 = zext i8 %333 to i64
  %335 = getelementptr inbounds i8, ptr %326, i64 1
  %336 = load i8, ptr %335, align 1, !tbaa !38
  %337 = zext i8 %336 to i64
  %338 = shl nuw nsw i64 %337, 8
  %339 = or disjoint i64 %338, %334
  %340 = getelementptr inbounds i8, ptr %326, i64 2
  %341 = load i8, ptr %340, align 1, !tbaa !38
  %342 = zext i8 %341 to i64
  %343 = shl nuw nsw i64 %342, 16
  %344 = or disjoint i64 %339, %343
  %345 = getelementptr inbounds i8, ptr %326, i64 3
  %346 = load i8, ptr %345, align 1, !tbaa !38
  %347 = zext i8 %346 to i64
  %348 = shl nuw nsw i64 %347, 24
  %349 = or disjoint i64 %344, %348
  %350 = getelementptr inbounds i8, ptr %326, i64 4
  %351 = load i8, ptr %350, align 1, !tbaa !38
  %352 = zext i8 %351 to i64
  %353 = shl nuw nsw i64 %352, 32
  %354 = or disjoint i64 %349, %353
  %355 = getelementptr inbounds i8, ptr %326, i64 5
  %356 = load i8, ptr %355, align 1, !tbaa !38
  %357 = zext i8 %356 to i64
  %358 = shl nuw nsw i64 %357, 40
  %359 = or i64 %354, %358
  %360 = getelementptr inbounds i8, ptr %326, i64 6
  %361 = load i8, ptr %360, align 1, !tbaa !38
  %362 = zext i8 %361 to i64
  %363 = shl nuw nsw i64 %362, 48
  %364 = or i64 %359, %363
  %365 = getelementptr inbounds i8, ptr %326, i64 7
  %366 = load i8, ptr %365, align 1, !tbaa !38
  %367 = zext i8 %366 to i64
  %368 = shl nuw i64 %367, 56
  %369 = or i64 %364, %368
  %370 = add nsw i32 %327, -8
  %371 = getelementptr inbounds i8, ptr %326, i64 8
  br label %385

372:                                              ; preds = %372, %330
  %373 = phi i32 [ %383, %372 ], [ 0, %330 ]
  %374 = phi i64 [ %382, %372 ], [ 0, %330 ]
  %375 = zext nneg i32 %373 to i64
  %376 = getelementptr inbounds i8, ptr %326, i64 %375
  %377 = load i8, ptr %376, align 1, !tbaa !38
  %378 = zext i8 %377 to i64
  %379 = shl i32 %373, 3
  %380 = zext nneg i32 %379 to i64
  %381 = shl nuw i64 %378, %380
  %382 = or i64 %381, %374
  %383 = add nuw nsw i32 %373, 1
  %384 = icmp eq i32 %383, %327
  br i1 %384, label %385, label %372

385:                                              ; preds = %372, %332, %330
  %386 = phi ptr [ %371, %332 ], [ %326, %330 ], [ %326, %372 ]
  %387 = phi i32 [ %370, %332 ], [ 0, %330 ], [ 0, %372 ]
  %388 = phi i64 [ %369, %332 ], [ 0, %330 ], [ %382, %372 ]
  %389 = icmp ugt i32 %387, 7
  br i1 %389, label %392, label %390

390:                                              ; preds = %385
  %391 = icmp eq i32 %387, 0
  br i1 %391, label %443, label %430

392:                                              ; preds = %385
  %393 = load i8, ptr %386, align 1, !tbaa !38
  %394 = zext i8 %393 to i64
  %395 = getelementptr inbounds i8, ptr %386, i64 1
  %396 = load i8, ptr %395, align 1, !tbaa !38
  %397 = zext i8 %396 to i64
  %398 = shl nuw nsw i64 %397, 8
  %399 = or disjoint i64 %398, %394
  %400 = getelementptr inbounds i8, ptr %386, i64 2
  %401 = load i8, ptr %400, align 1, !tbaa !38
  %402 = zext i8 %401 to i64
  %403 = shl nuw nsw i64 %402, 16
  %404 = or disjoint i64 %399, %403
  %405 = getelementptr inbounds i8, ptr %386, i64 3
  %406 = load i8, ptr %405, align 1, !tbaa !38
  %407 = zext i8 %406 to i64
  %408 = shl nuw nsw i64 %407, 24
  %409 = or disjoint i64 %404, %408
  %410 = getelementptr inbounds i8, ptr %386, i64 4
  %411 = load i8, ptr %410, align 1, !tbaa !38
  %412 = zext i8 %411 to i64
  %413 = shl nuw nsw i64 %412, 32
  %414 = or disjoint i64 %409, %413
  %415 = getelementptr inbounds i8, ptr %386, i64 5
  %416 = load i8, ptr %415, align 1, !tbaa !38
  %417 = zext i8 %416 to i64
  %418 = shl nuw nsw i64 %417, 40
  %419 = or i64 %414, %418
  %420 = getelementptr inbounds i8, ptr %386, i64 6
  %421 = load i8, ptr %420, align 1, !tbaa !38
  %422 = zext i8 %421 to i64
  %423 = shl nuw nsw i64 %422, 48
  %424 = or i64 %419, %423
  %425 = getelementptr inbounds i8, ptr %386, i64 7
  %426 = load i8, ptr %425, align 1, !tbaa !38
  %427 = zext i8 %426 to i64
  %428 = shl nuw i64 %427, 56
  %429 = or i64 %424, %428
  br label %443

430:                                              ; preds = %430, %390
  %431 = phi i32 [ %441, %430 ], [ 0, %390 ]
  %432 = phi i64 [ %440, %430 ], [ 0, %390 ]
  %433 = zext nneg i32 %431 to i64
  %434 = getelementptr inbounds i8, ptr %386, i64 %433
  %435 = load i8, ptr %434, align 1, !tbaa !38
  %436 = zext i8 %435 to i64
  %437 = shl i32 %431, 3
  %438 = zext nneg i32 %437 to i64
  %439 = shl nuw i64 %436, %438
  %440 = or i64 %439, %432
  %441 = add nuw nsw i32 %431, 1
  %442 = icmp eq i32 %441, %387
  br i1 %442, label %443, label %430

443:                                              ; preds = %430, %392, %390
  %444 = phi i64 [ %429, %392 ], [ 0, %390 ], [ %440, %430 ]
  %445 = shl nuw nsw i64 %26, 2
  %446 = add nuw nsw i64 %445, 28
  %447 = and i64 %446, 480
  %448 = and i64 %28, -225
  %449 = or i64 %448, %447
  %450 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %449, i64 noundef %88, i64 noundef %148, i64 noundef %208, i64 noundef %268, i64 noundef %328, i64 noundef %388, i64 noundef %444) #12
  %451 = sub i64 %18, %26
  %452 = getelementptr inbounds i8, ptr %19, i64 %26
  %453 = icmp eq i64 %451, 0
  br i1 %453, label %454, label %17

454:                                              ; preds = %443, %9
  %455 = phi <2 x i64> [ %12, %9 ], [ %450, %443 ]
  %456 = extractelement <2 x i64> %455, i64 0
  ret i64 %456
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #6

; Function Attrs: convergent mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define internal i64 @__ockl_get_local_size(i32 noundef %0) #5 {
  switch i32 %0, label %76 [
    i32 0, label %2
    i32 1, label %26
    i32 2, label %51
  ]

2:                                                ; preds = %1
  %3 = load i32, ptr addrspace(4) @__oclc_ABI_version, align 4
  %4 = icmp slt i32 %3, 500
  br i1 %4, label %5, label %17

5:                                                ; preds = %2
  %6 = tail call align 4 dereferenceable(64) ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
  %7 = tail call i32 @llvm.amdgcn.workgroup.id.x()
  %8 = getelementptr inbounds i8, ptr addrspace(4) %6, i64 4
  %9 = load i16, ptr addrspace(4) %8, align 4, !range !39, !invariant.load !16, !noundef !16
  %10 = zext nneg i16 %9 to i32
  %11 = getelementptr inbounds %6, ptr addrspace(4) %6, i64 0, i32 6
  %12 = load i32, ptr addrspace(4) %11, align 4, !tbaa !40
  %13 = mul i32 %7, %10
  %14 = sub i32 %12, %13
  %15 = tail call i32 @llvm.umin.i32(i32 %14, i32 %10)
  %16 = zext nneg i32 %15 to i64
  br label %76

17:                                               ; preds = %2
  %18 = tail call i32 @llvm.amdgcn.workgroup.id.x()
  %19 = tail call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %20 = load i32, ptr addrspace(4) %19, align 4, !tbaa !17
  %21 = icmp ult i32 %18, %20
  %22 = select i1 %21, i64 6, i64 9
  %23 = getelementptr inbounds i16, ptr addrspace(4) %19, i64 %22
  %24 = load i16, ptr addrspace(4) %23, align 2, !tbaa !43
  %25 = zext i16 %24 to i64
  br label %76

26:                                               ; preds = %1
  %27 = load i32, ptr addrspace(4) @__oclc_ABI_version, align 4
  %28 = icmp slt i32 %27, 500
  br i1 %28, label %29, label %41

29:                                               ; preds = %26
  %30 = tail call align 4 dereferenceable(64) ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
  %31 = tail call i32 @llvm.amdgcn.workgroup.id.y()
  %32 = getelementptr inbounds i8, ptr addrspace(4) %30, i64 6
  %33 = load i16, ptr addrspace(4) %32, align 2, !range !39, !invariant.load !16, !noundef !16
  %34 = zext nneg i16 %33 to i32
  %35 = getelementptr inbounds %6, ptr addrspace(4) %30, i64 0, i32 7
  %36 = load i32, ptr addrspace(4) %35, align 8, !tbaa !44
  %37 = mul i32 %31, %34
  %38 = sub i32 %36, %37
  %39 = tail call i32 @llvm.umin.i32(i32 %38, i32 %34)
  %40 = zext nneg i32 %39 to i64
  br label %76

41:                                               ; preds = %26
  %42 = tail call i32 @llvm.amdgcn.workgroup.id.y()
  %43 = tail call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %44 = getelementptr inbounds i32, ptr addrspace(4) %43, i64 1
  %45 = load i32, ptr addrspace(4) %44, align 4, !tbaa !17
  %46 = icmp ult i32 %42, %45
  %47 = select i1 %46, i64 7, i64 10
  %48 = getelementptr inbounds i16, ptr addrspace(4) %43, i64 %47
  %49 = load i16, ptr addrspace(4) %48, align 2, !tbaa !43
  %50 = zext i16 %49 to i64
  br label %76

51:                                               ; preds = %1
  %52 = load i32, ptr addrspace(4) @__oclc_ABI_version, align 4
  %53 = icmp slt i32 %52, 500
  br i1 %53, label %54, label %66

54:                                               ; preds = %51
  %55 = tail call align 4 dereferenceable(64) ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
  %56 = tail call i32 @llvm.amdgcn.workgroup.id.z()
  %57 = getelementptr inbounds i8, ptr addrspace(4) %55, i64 8
  %58 = load i16, ptr addrspace(4) %57, align 4, !range !39, !invariant.load !16, !noundef !16
  %59 = zext nneg i16 %58 to i32
  %60 = getelementptr inbounds %6, ptr addrspace(4) %55, i64 0, i32 8
  %61 = load i32, ptr addrspace(4) %60, align 4, !tbaa !45
  %62 = mul i32 %56, %59
  %63 = sub i32 %61, %62
  %64 = tail call i32 @llvm.umin.i32(i32 %63, i32 %59)
  %65 = zext nneg i32 %64 to i64
  br label %76

66:                                               ; preds = %51
  %67 = tail call i32 @llvm.amdgcn.workgroup.id.z()
  %68 = tail call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %69 = getelementptr inbounds i32, ptr addrspace(4) %68, i64 2
  %70 = load i32, ptr addrspace(4) %69, align 4, !tbaa !17
  %71 = icmp ult i32 %67, %70
  %72 = select i1 %71, i64 8, i64 11
  %73 = getelementptr inbounds i16, ptr addrspace(4) %68, i64 %72
  %74 = load i16, ptr addrspace(4) %73, align 2, !tbaa !43
  %75 = zext i16 %74 to i64
  br label %76

76:                                               ; preds = %66, %54, %41, %29, %17, %5, %1
  %77 = phi i64 [ 1, %1 ], [ %16, %5 ], [ %25, %17 ], [ %40, %29 ], [ %50, %41 ], [ %65, %54 ], [ %75, %66 ]
  ret i64 %77
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef nonnull align 4 ptr addrspace(4) @llvm.amdgcn.dispatch.ptr() #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workgroup.id.x() #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workgroup.id.y() #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workgroup.id.z() #6

; Function Attrs: convergent mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define internal i64 @__ockl_get_group_id(i32 noundef %0) #5 {
  switch i32 %0, label %8 [
    i32 0, label %2
    i32 1, label %4
    i32 2, label %6
  ]

2:                                                ; preds = %1
  %3 = tail call i32 @llvm.amdgcn.workgroup.id.x()
  br label %8

4:                                                ; preds = %1
  %5 = tail call i32 @llvm.amdgcn.workgroup.id.y()
  br label %8

6:                                                ; preds = %1
  %7 = tail call i32 @llvm.amdgcn.workgroup.id.z()
  br label %8

8:                                                ; preds = %6, %4, %2, %1
  %9 = phi i32 [ %7, %6 ], [ %5, %4 ], [ %3, %2 ], [ 0, %1 ]
  %10 = zext i32 %9 to i64
  ret i64 %10
}

attributes #0 = { convergent mustprogress noinline noreturn nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx90a" "target-features"="+16-bit-insts,+atomic-buffer-global-pk-add-f16-insts,+atomic-fadd-rtn-insts,+ci-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot3-insts,+dot4-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+gfx8-insts,+gfx9-insts,+gfx90a-insts,+mai-insts,+s-memrealtime,+s-memtime-inst,+wavefrontsize64" }
attributes #1 = { cold noreturn nounwind memory(inaccessiblemem: write) }
attributes #2 = { convergent mustprogress noinline nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx90a" "target-features"="+16-bit-insts,+atomic-buffer-global-pk-add-f16-insts,+atomic-fadd-rtn-insts,+ci-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot3-insts,+dot4-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+gfx8-insts,+gfx9-insts,+gfx90a-insts,+mai-insts,+s-memrealtime,+s-memtime-inst,+wavefrontsize64" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { convergent mustprogress noinline norecurse nounwind optnone "amdgpu-flat-work-group-size"="1,1024" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx90a" "target-features"="+16-bit-insts,+atomic-buffer-global-pk-add-f16-insts,+atomic-fadd-rtn-insts,+ci-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot3-insts,+dot4-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+gfx8-insts,+gfx9-insts,+gfx90a-insts,+mai-insts,+s-memrealtime,+s-memtime-inst,+wavefrontsize64" "uniform-work-group-size"="true" }
attributes #5 = { convergent mustprogress nofree norecurse nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx90a" "target-features"="+16-bit-insts,+atomic-buffer-global-pk-add-f16-insts,+atomic-fadd-rtn-insts,+ci-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot3-insts,+dot4-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+gfx8-insts,+gfx9-insts,+gfx90a-insts,+gws,+image-insts,+mai-insts,+s-memrealtime,+s-memtime-inst,+wavefrontsize64" }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #7 = { convergent norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx90a" "target-features"="+16-bit-insts,+atomic-buffer-global-pk-add-f16-insts,+atomic-fadd-rtn-insts,+ci-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot3-insts,+dot4-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+gfx8-insts,+gfx9-insts,+gfx90a-insts,+gws,+image-insts,+mai-insts,+s-memrealtime,+s-memtime-inst,+wavefrontsize64" }
attributes #8 = { convergent nocallback nofree nounwind willreturn memory(none) }
attributes #9 = { nocallback nofree nosync nounwind willreturn }
attributes #10 = { nounwind }
attributes #11 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #12 = { convergent nounwind }
attributes #13 = { convergent nounwind willreturn memory(none) }
attributes #14 = { cold convergent nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}
!opencl.ocl.version = !{!7, !7, !7, !7, !7, !7, !7, !7, !7, !7}

!0 = !{i32 1, !"amdhsa_code_object_version", i32 500}
!1 = !{i32 1, !"amdgpu_printf_kind", !"hostcall"}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!6 = !{!"AMD clang version 18.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-6.3.4 25012 e5bf7e55c91490b07c49d8960fa7983d864936c4)"}
!7 = !{i32 2, i32 0}
!8 = distinct !{!8, !9}
!9 = !{!"llvm.loop.mustprogress"}
!10 = distinct !{!10, !9}
!11 = distinct !{!11, !9}
!12 = distinct !{!12, !9}
!13 = distinct !{!13, !9}
!14 = distinct !{!14, !9}
!15 = !{i32 0, i32 1024}
!16 = !{}
!17 = !{!18, !18, i64 0}
!18 = !{!"int", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !{!22, !22, i64 0}
!22 = !{!"long", !19, i64 0}
!23 = !{i64 2662}
!24 = !{!25, !26, i64 0}
!25 = !{!"", !26, i64 0, !26, i64 8, !27, i64 16, !22, i64 24, !22, i64 32, !22, i64 40}
!26 = !{!"any pointer", !19, i64 0}
!27 = !{!"hsa_signal_s", !22, i64 0}
!28 = !{!25, !22, i64 40}
!29 = !{!25, !26, i64 8}
!30 = !{!31, !18, i64 16}
!31 = !{!"", !22, i64 0, !22, i64 8, !18, i64 16, !18, i64 20}
!32 = !{!31, !22, i64 8}
!33 = !{!31, !18, i64 20}
!34 = !{!31, !22, i64 0}
!35 = !{!36, !22, i64 16}
!36 = !{!"amd_signal_s", !22, i64 0, !19, i64 8, !22, i64 16, !18, i64 24, !18, i64 28, !22, i64 32, !22, i64 40, !19, i64 48, !19, i64 56}
!37 = !{!36, !18, i64 24}
!38 = !{!19, !19, i64 0}
!39 = !{i16 1, i16 1025}
!40 = !{!41, !18, i64 12}
!41 = !{!"hsa_kernel_dispatch_packet_s", !42, i64 0, !42, i64 2, !42, i64 4, !42, i64 6, !42, i64 8, !42, i64 10, !18, i64 12, !18, i64 16, !18, i64 20, !18, i64 24, !18, i64 28, !19, i64 32, !26, i64 40, !22, i64 48, !27, i64 56}
!42 = !{!"short", !19, i64 0}
!43 = !{!42, !42, i64 0}
!44 = !{!41, !18, i64 16}
!45 = !{!41, !18, i64 20}
