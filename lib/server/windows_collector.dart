import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'system_info_collector.dart';

/// Windows 平台系统信息采集器
///
/// 通过 dart:ffi 调用 Windows API 实现系统信息采集：
/// - CPU：使用 GetSystemTimes() 计算使用率
/// - 内存：使用 GlobalMemoryStatusEx() 获取内存信息
/// - 磁盘：使用 GetDiskFreeSpaceExW() 获取磁盘空间
/// - 网络：使用 GetIfTable() 获取网络流量
class WindowsCollector extends SystemInfoCollector {
  // ==================== CPU 采集状态 ====================

  /// 上一次采样的空闲时间
  int _prevIdleTime = 0;

  /// 上一次采样的内核时间（包含空闲时间）
  int _prevKernelTime = 0;

  /// 上一次采样的用户时间
  int _prevUserTime = 0;

  /// 是否为首次 CPU 采样（首次采样无法计算差值，返回 0）
  bool _isFirstCpuSample = true;

  // ==================== 网络采集状态 ====================

  /// 上一次采样的接收字节数
  int _prevInOctets = 0;

  /// 上一次采样的发送字节数
  int _prevOutOctets = 0;

  /// 上一次网络采集时间
  DateTime? _prevNetworkTime;

  /// 构造函数
  WindowsCollector({super.collectionInterval});

  // ==================== Win32 DLL 加载 ====================

  /// kernel32.dll 动态库（系统核心库，始终已加载）
  static final DynamicLibrary _kernel32 = DynamicLibrary.process();

  /// iphlpapi.dll 动态库（IP 辅助库，用于网络接口查询）
  static final DynamicLibrary _iphlpapi = DynamicLibrary.open('iphlpapi.dll');

  // ==================== kernel32 函数指针查找 ====================

  /// 获取系统时间（用于 CPU 使用率计算）
  static final Pointer<NativeFunction<_GetSystemTimesNative>>
      _pGetSystemTimes = _kernel32.lookup('GetSystemTimes');

  /// 获取内存状态
  static final Pointer<NativeFunction<_GlobalMemoryStatusExNative>>
      _pGlobalMemoryStatusEx = _kernel32.lookup('GlobalMemoryStatusEx');

  /// 获取磁盘可用空间
  static final Pointer<NativeFunction<_GetDiskFreeSpaceExWNative>>
      _pGetDiskFreeSpaceExW = _kernel32.lookup('GetDiskFreeSpaceExW');

  /// 获取卷信息（文件系统类型等）
  static final Pointer<NativeFunction<_GetVolumeInformationWNative>>
      _pGetVolumeInformationW = _kernel32.lookup('GetVolumeInformationW');

  /// 获取逻辑驱动器位掩码
  static final Pointer<NativeFunction<_GetLogicalDrivesNative>>
      _pGetLogicalDrives = _kernel32.lookup('GetLogicalDrives');

  // ==================== iphlpapi 函数指针查找 ====================

  /// 获取网络接口表
  static final Pointer<NativeFunction<_GetIfTableNative>> _pGetIfTable =
      _iphlpapi.lookup('GetIfTable');

  // ==================== 原生函数签名定义 ====================

  /// GetSystemTimes 函数签名
  static final int Function(
    Pointer<FILETIME>,
    Pointer<FILETIME>,
    Pointer<FILETIME>,
  ) _nativeGetSystemTimes = _pGetSystemTimes
      .cast<NativeFunction<_GetSystemTimesNative>>()
      .asFunction();

  /// GlobalMemoryStatusEx 函数签名
  static final int Function(
    Pointer<MEMORYSTATUSEX>,
  ) _nativeGlobalMemoryStatusEx = _pGlobalMemoryStatusEx
      .cast<NativeFunction<_GlobalMemoryStatusExNative>>()
      .asFunction();

  /// GetDiskFreeSpaceExW 函数签名
  static final int Function(
    Pointer<Utf16>,
    Pointer<ULARGE_INTEGER>,
    Pointer<ULARGE_INTEGER>,
    Pointer<ULARGE_INTEGER>,
  ) _nativeGetDiskFreeSpaceExW = _pGetDiskFreeSpaceExW
      .cast<NativeFunction<_GetDiskFreeSpaceExWNative>>()
      .asFunction();

  /// GetVolumeInformationW 函数签名
  static final int Function(
    Pointer<Utf16>,
    Pointer<Utf16>,
    int,
    Pointer<Uint32>,
    Pointer<Uint32>,
    Pointer<Uint32>,
    Pointer<Utf16>,
    int,
  ) _nativeGetVolumeInformationW = _pGetVolumeInformationW
      .cast<NativeFunction<_GetVolumeInformationWNative>>()
      .asFunction();

  /// GetLogicalDrives 函数签名
  static final int Function() _nativeGetLogicalDrives = _pGetLogicalDrives
      .cast<NativeFunction<_GetLogicalDrivesNative>>()
      .asFunction();

  /// GetIfTable 函数签名
  static final int Function(
    Pointer<MIB_IFTABLE>,
    Pointer<Uint32>,
    int,
  ) _nativeGetIfTable =
      _pGetIfTable.cast<NativeFunction<_GetIfTableNative>>().asFunction();

  // ==================== 公开接口实现 ====================

  /// 采集 CPU 使用率
  ///
  /// 通过两次 GetSystemTimes() 快照的差值计算 CPU 使用率。
  /// 首次调用返回 0（需要两次采样才能计算差值）。
  ///
  /// 返回 CPU 使用率百分比（0-100）
  @override
  Future<double> collectCpuUsage() async {
    final pIdleTime = calloc<FILETIME>();
    final pKernelTime = calloc<FILETIME>();
    final pUserTime = calloc<FILETIME>();

    try {
      // 调用 Windows API 获取 CPU 时间
      final result = _nativeGetSystemTimes(
        pIdleTime,
        pKernelTime,
        pUserTime,
      );

      // API 调用失败
      if (result == 0) return 0.0;

      // 将 FILETIME 转换为 64 位整数
      final idleTime = _filetimeToInt64(pIdleTime.ref);
      final kernelTime = _filetimeToInt64(pKernelTime.ref);
      final userTime = _filetimeToInt64(pUserTime.ref);

      // 首次采样，记录基准值
      if (_isFirstCpuSample) {
        _prevIdleTime = idleTime;
        _prevKernelTime = kernelTime;
        _prevUserTime = userTime;
        _isFirstCpuSample = false;
        return 0.0;
      }

      // 计算两次采样之间的差值
      final idleDelta = idleTime - _prevIdleTime;
      final kernelDelta = kernelTime - _prevKernelTime;
      final userDelta = userTime - _prevUserTime;

      // 更新上一次采样值
      _prevIdleTime = idleTime;
      _prevKernelTime = kernelTime;
      _prevUserTime = userTime;

      // kernel 时间包含 idle 时间，因此：
      // 总时间 = kernel + user
      // 使用率 = (总时间 - idle) / 总时间 * 100
      final totalDelta = kernelDelta + userDelta;
      if (totalDelta <= 0) return 0.0;

      final usage = ((totalDelta - idleDelta) / totalDelta) * 100.0;
      return usage.clamp(0.0, 100.0);
    } finally {
      calloc.free(pIdleTime);
      calloc.free(pKernelTime);
      calloc.free(pUserTime);
    }
  }

  /// 采集内存使用情况
  ///
  /// 通过 GlobalMemoryStatusEx() 获取物理内存信息。
  /// 返回包含 used、total、usage 的 Map
  @override
  Future<Map<String, dynamic>> collectMemoryInfo() async {
    final pMemoryStatus = calloc<MEMORYSTATUSEX>();

    try {
      // 设置结构体大小（API 要求）
      pMemoryStatus.ref.dwLength = sizeOf<MEMORYSTATUSEX>();

      // 调用 Windows API
      final result = _nativeGlobalMemoryStatusEx(pMemoryStatus);
      if (result == 0) {
        return {'used': 0, 'total': 0, 'usage': 0.0};
      }

      // 读取内存信息
      final totalPhys = pMemoryStatus.ref.ullTotalPhys;
      final availPhys = pMemoryStatus.ref.ullAvailPhys;
      final usedPhys = totalPhys - availPhys;
      final usagePercent = totalPhys > 0 ? (usedPhys / totalPhys) * 100.0 : 0.0;

      return {
        'used': usedPhys,
        'total': totalPhys,
        'usage': usagePercent,
      };
    } finally {
      calloc.free(pMemoryStatus);
    }
  }

  /// 采集磁盘信息
  ///
  /// 通过 GetLogicalDrives() 枚举驱动器，
  /// 再用 GetDiskFreeSpaceExW() 获取每个驱动器的空间信息。
  @override
  Future<List<DiskInfo>> collectDiskInfo() async {
    final disks = <DiskInfo>[];

    // 获取可用驱动器位掩码（bit 0=A, bit 1=B, ... bit 25=Z）
    final driveMask = _nativeGetLogicalDrives();
    if (driveMask == 0) return disks;

    for (int i = 0; i < 26; i++) {
      // 检查该驱动器是否可用
      if (driveMask & (1 << i) == 0) continue;

      final driveLetter = String.fromCharCode(65 + i); // 'A' ~ 'Z'
      final drivePath = '$driveLetter:\\';

      // 查询磁盘空间
      final diskInfo = _queryDiskSpace(drivePath);
      if (diskInfo != null) {
        disks.add(diskInfo);
      }
    }

    return disks;
  }

  /// 采集网络流量
  ///
  /// 通过 GetIfTable() 获取所有网络接口的流量统计。
  /// 对比两次采样计算速率。
  @override
  Future<NetworkTraffic> collectNetworkTraffic() async {
    // 获取网络接口表
    final result = _queryNetworkInterfaces();

    if (result == null) {
      return const NetworkTraffic(
        uploadSpeed: 0,
        downloadSpeed: 0,
        totalUploaded: 0,
        totalDownloaded: 0,
      );
    }

    final (totalInOctets, totalOutOctets) = result;

    // 计算速率
    double uploadSpeed = 0;
    double downloadSpeed = 0;

    if (_prevNetworkTime != null) {
      final now = DateTime.now();
      final timeDelta = now.difference(_prevNetworkTime!).inMicroseconds;

      if (timeDelta > 0) {
        // 微秒转秒：除以 1,000,000
        final timeDeltaSeconds = timeDelta / 1000000.0;
        uploadSpeed = (totalOutOctets - _prevOutOctets) / timeDeltaSeconds;
        downloadSpeed = (totalInOctets - _prevInOctets) / timeDeltaSeconds;

        // 确保速率不为负数（可能因计数器溢出导致）
        if (uploadSpeed < 0) uploadSpeed = 0;
        if (downloadSpeed < 0) downloadSpeed = 0;
      }
    }

    // 更新上一次采样值
    _prevInOctets = totalInOctets;
    _prevOutOctets = totalOutOctets;
    _prevNetworkTime = DateTime.now();

    return NetworkTraffic(
      uploadSpeed: uploadSpeed,
      downloadSpeed: downloadSpeed,
      totalUploaded: totalInOctets,
      totalDownloaded: totalOutOctets,
    );
  }

  // ==================== 内部辅助方法 ====================

  /// 将 FILETIME 结构体转换为 64 位整数
  static int _filetimeToInt64(FILETIME ft) {
    return ((ft.dwHighDateTime & 0xFFFFFFFF) << 32) |
        (ft.dwLowDateTime & 0xFFFFFFFF);
  }

  /// 查询指定驱动器的磁盘空间信息
  DiskInfo? _queryDiskSpace(String drivePath) {
    final pFreeBytesAvailable = calloc<ULARGE_INTEGER>();
    final pTotalBytes = calloc<ULARGE_INTEGER>();
    final pTotalFreeBytes = calloc<ULARGE_INTEGER>();
    final pDrivePath = drivePath.toNativeUtf16();

    try {
      // 查询磁盘空间
      final result = _nativeGetDiskFreeSpaceExW(
        pDrivePath,
        pFreeBytesAvailable,
        pTotalBytes,
        pTotalFreeBytes,
      );

      if (result == 0) return null;

      final totalSpace = pTotalBytes.ref.QuadPart;
      final freeSpace = pTotalFreeBytes.ref.QuadPart;
      final usedSpace = totalSpace - freeSpace;
      final usage = totalSpace > 0 ? (usedSpace / totalSpace) * 100.0 : 0.0;

      // 获取文件系统类型
      final fileSystem = _queryFileSystemType(drivePath);

      return DiskInfo(
        mountPoint: drivePath,
        fileSystem: fileSystem,
        totalSpace: totalSpace,
        usedSpace: usedSpace,
        freeSpace: freeSpace,
        usage: usage,
      );
    } finally {
      calloc.free(pFreeBytesAvailable);
      calloc.free(pTotalBytes);
      calloc.free(pTotalFreeBytes);
      calloc.free(pDrivePath);
    }
  }

  /// 查询指定驱动器的文件系统类型
  String _queryFileSystemType(String drivePath) {
    final pDrivePath = drivePath.toNativeUtf16();
    final pFsNameBuffer = calloc<Uint16>(256);
    final pFsFlags = calloc<Uint32>();

    try {
      final result = _nativeGetVolumeInformationW(
        pDrivePath,
        nullptr, // 不需要卷名
        0,
        nullptr, // 不需要序列号
        nullptr, // 不需要最大组件长度
        pFsFlags,
        pFsNameBuffer.cast(),
        256,
      );

      if (result == 0) return 'Unknown';

      return pFsNameBuffer.cast<Utf16>().toDartString();
    } finally {
      calloc.free(pDrivePath);
      calloc.free(pFsNameBuffer);
      calloc.free(pFsFlags);
    }
  }

  /// 查询所有网络接口的流量统计
  (int, int)? _queryNetworkInterfaces() {
    final pSize = calloc<Uint32>();

    try {
      // 第一次调用获取所需缓冲区大小
      _nativeGetIfTable(nullptr, pSize, 0);

      final bufSize = pSize.value;
      if (bufSize == 0) return null;

      // 分配缓冲区
      final pBuffer = calloc.allocate<Uint8>(bufSize);

      try {
        // 第二次调用获取实际数据
        final result = _nativeGetIfTable(pBuffer.cast(), pSize, 0);
        if (result != 0) return null;

        // 读取接口数量（MIB_IFTABLE 的第一个 DWORD）
        final numEntries = pBuffer.cast<Uint32>().value;

        int totalInOctets = 0;
        int totalOutOctets = 0;

        // 遍历每个接口行
        const headerSize = 4; // sizeof(DWORD)
        final rowSize = sizeOf<MIB_IFROW>();

        for (int i = 0; i < numEntries; i++) {
          final rowAddress = pBuffer.address + headerSize + i * rowSize;
          final row = Pointer<MIB_IFROW>.fromAddress(rowAddress).ref;

          // 跳过回环接口（类型 24 = IF_TYPE_SOFTWARE_LOOPBACK）
          if (row.dwType == _kIfTypeSoftwareLoopback) continue;

          // 累加流量（32 位无符号计数器）
          totalInOctets += row.dwInOctets & 0xFFFFFFFF;
          totalOutOctets += row.dwOutOctets & 0xFFFFFFFF;
        }

        return (totalInOctets, totalOutOctets);
      } finally {
        calloc.free(pBuffer);
      }
    } finally {
      calloc.free(pSize);
    }
  }
}

// ==================== Win32 原生结构体定义 ====================

/// FILETIME 结构体
final class FILETIME extends Struct {
  @Uint32()
  external int dwLowDateTime;

  @Uint32()
  external int dwHighDateTime;
}

/// MEMORYSTATUSEX 结构体
final class MEMORYSTATUSEX extends Struct {
  @Uint32()
  external int dwLength;

  @Uint32()
  external int dwMemoryLoad;

  @Uint64()
  external int ullTotalPhys;

  @Uint64()
  external int ullAvailPhys;

  @Uint64()
  external int ullTotalPageFile;

  @Uint64()
  external int ullAvailPageFile;

  @Uint64()
  external int ullTotalVirtual;

  @Uint64()
  external int ullAvailVirtual;

  @Uint64()
  external int ullAvailExtendedVirtual;
}

/// ULARGE_INTEGER 结构体
final class ULARGE_INTEGER extends Struct {
  @Uint64()
  external int QuadPart;
}

/// MIB_IFROW 结构体
final class MIB_IFROW extends Struct {
  /// 接口描述（宽字符数组，MAXLEN_IFDESCR = 256）
  @Array(256)
  external Array<Uint16> wszDescr;

  @Uint32()
  external int dwDescrLen;

  @Uint32()
  external int dwType;

  @Uint32()
  external int dwMtu;

  @Uint32()
  external int dwSpeed;

  /// 物理地址（MAXLEN_PHYSADDR = 8）
  @Array(8)
  external Array<Uint8> bPhysAddr;

  @Uint32()
  external int dwPhysAddrLen;

  @Uint32()
  external int dwAdminStatus;

  @Uint32()
  external int dwOperStatus;

  @Uint32()
  external int dwLastChange;

  @Uint32()
  external int dwInOctets;

  @Uint32()
  external int dwInUcastPkts;

  @Uint32()
  external int dwInNUcastPkts;

  @Uint32()
  external int dwInDiscards;

  @Uint32()
  external int dwInErrors;

  @Uint32()
  external int dwInUnknownProtos;

  @Uint32()
  external int dwOutOctets;

  @Uint32()
  external int dwOutUcastPkts;

  @Uint32()
  external int dwOutNUcastPkts;

  @Uint32()
  external int dwOutDiscards;

  @Uint32()
  external int dwOutErrors;

  @Uint32()
  external int dwOutQLen;

  @Uint32()
  external int dwDescrLen2;

  /// 接口名称（宽字符数组，MAX_INTERFACE_NAME_LEN = 256）
  @Array(256)
  external Array<Uint16> wszName;
}

/// MIB_IFTABLE 结构体（变长结构体头部）
final class MIB_IFTABLE extends Struct {
  @Uint32()
  external int dwNumEntries;
}

// ==================== 原生函数签名 ====================

/// GetSystemTimes 函数签名
typedef _GetSystemTimesNative = Uint32 Function(
  Pointer<FILETIME> lpIdleTime,
  Pointer<FILETIME> lpKernelTime,
  Pointer<FILETIME> lpUserTime,
);

/// GlobalMemoryStatusEx 函数签名
typedef _GlobalMemoryStatusExNative = Uint32 Function(
  Pointer<MEMORYSTATUSEX> lpBuffer,
);

/// GetDiskFreeSpaceExW 函数签名
typedef _GetDiskFreeSpaceExWNative = Uint32 Function(
  Pointer<Utf16> lpDirectoryName,
  Pointer<ULARGE_INTEGER> lpFreeBytesAvailableToCaller,
  Pointer<ULARGE_INTEGER> lpTotalNumberOfBytes,
  Pointer<ULARGE_INTEGER> lpTotalNumberOfFreeBytes,
);

/// GetVolumeInformationW 函数签名
typedef _GetVolumeInformationWNative = Uint32 Function(
  Pointer<Utf16> lpRootPathName,
  Pointer<Utf16> lpVolumeNameBuffer,
  Uint32 nVolumeNameSize,
  Pointer<Uint32> lpVolumeSerialNumber,
  Pointer<Uint32> lpMaximumComponentLength,
  Pointer<Uint32> lpFileSystemFlags,
  Pointer<Utf16> lpFileSystemNameBuffer,
  Uint32 nFileSystemNameSize,
);

/// GetLogicalDrives 函数签名
typedef _GetLogicalDrivesNative = Uint32 Function();

/// GetIfTable 函数签名
typedef _GetIfTableNative = Uint32 Function(
  Pointer<MIB_IFTABLE> pIfTable,
  Pointer<Uint32> pdwSize,
  Uint32 bOrder,
);

// ==================== 常量定义 ====================

/// 回环网络接口类型（IF_TYPE_SOFTWARE_LOOPBACK = 24）
const int _kIfTypeSoftwareLoopback = 24;
