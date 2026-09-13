import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance =
      AppUpdateService._();

  // ============================================================
  // GITHUB CONFIGURATION
  // ============================================================

  static const String githubOwner =
      'routsourav9777-wq';

  static const String githubRepository =
      'bca_department_management';

  static const String githubApiUrl =
      'https://api.github.com/repos/'
      '$githubOwner/$githubRepository/releases/latest';

  // ============================================================
  // VARIABLES
  // ============================================================

  bool _automaticCheckRunning = false;

  bool _updateDialogShowing = false;

  String? _lastDismissedVersion;

  final ValueNotifier<double> _downloadProgress =
      ValueNotifier<double>(0.0);

  // ============================================================
  // MANUAL CHECK
  // ============================================================

  Future<void> checkForUpdate(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) {
      _showMessage(
        context,
        'Automatic APK update is available on Android only.',
        error: true,
      );

      return;
    }

    bool checkingDialogShown = false;

    try {
      _showCheckingDialog(context);

      checkingDialogShown = true;

      // --------------------------------------------------------
      // CURRENT VERSION
      // --------------------------------------------------------

      final PackageVersion currentVersion =
          await _getCurrentVersion();

      // --------------------------------------------------------
      // GITHUB RELEASE
      // --------------------------------------------------------

      final GitHubRelease release =
          await _getLatestGitHubRelease();

      if (!context.mounted) {
        return;
      }

      // --------------------------------------------------------
      // CLOSE CHECKING DIALOG
      // --------------------------------------------------------

      if (checkingDialogShown) {
        Navigator.of(context).pop();

        checkingDialogShown = false;
      }

      // --------------------------------------------------------
      // COMPARE
      // --------------------------------------------------------

      final int comparison =
          _compareVersion(
        release.versionCode,
        currentVersion.versionCode,
      );

      debugPrint(
        'Installed: '
        '${currentVersion.versionName}+'
        '${currentVersion.versionCode}',
      );

      debugPrint(
        'GitHub: '
        '${release.versionName}+'
        '${release.versionCode}',
      );

      // --------------------------------------------------------
      // UPDATE AVAILABLE
      // --------------------------------------------------------

      if (comparison > 0) {
        await _showUpdateDialog(
          context,
          currentVersion,
          release,
          forceShow: true,
        );

        return;
      }

      // --------------------------------------------------------
      // UP TO DATE
      // --------------------------------------------------------

      _showNoUpdateDialog(
        context,
        currentVersion,
      );
    } catch (e) {
      debugPrint(
        'Manual update check error: $e',
      );

      if (!context.mounted) {
        return;
      }

      if (checkingDialogShown) {
        Navigator.of(context).pop();

        checkingDialogShown = false;
      }

      _showMessage(
        context,
        'Unable to check for updates.\n'
        'Please check your internet connection.',
        error: true,
      );
    }
  }

  // ============================================================
  // AUTOMATIC CHECK
  // ============================================================

  Future<void> checkForUpdateAutomatically() async {
    if (!Platform.isAndroid) {
      return;
    }

    if (_automaticCheckRunning) {
      return;
    }

    _automaticCheckRunning = true;

    try {
      // --------------------------------------------------------
      // WAIT FOR APP UI
      // --------------------------------------------------------

      await Future<void>.delayed(
        const Duration(seconds: 2),
      );

      // --------------------------------------------------------
      // CURRENT CONTEXT
      // --------------------------------------------------------

      final BuildContext? context =
          navigatorKey.currentContext;

      if (context == null) {
        debugPrint(
          'Update check skipped: '
          'Navigator context not ready.',
        );

        return;
      }

      // --------------------------------------------------------
      // CURRENT VERSION
      // --------------------------------------------------------

      final PackageVersion currentVersion =
          await _getCurrentVersion();

      // --------------------------------------------------------
      // GITHUB RELEASE
      // --------------------------------------------------------

      final GitHubRelease release =
          await _getLatestGitHubRelease();

      if (!context.mounted) {
        return;
      }

      // --------------------------------------------------------
      // COMPARE
      // --------------------------------------------------------

      final int comparison =
          _compareVersion(
        release.versionCode,
        currentVersion.versionCode,
      );

      debugPrint(
        'Automatic update check: '
        '${currentVersion.versionName}+'
        '${currentVersion.versionCode} '
        'vs '
        '${release.versionName}+'
        '${release.versionCode}',
      );

      if (comparison <= 0) {
        debugPrint(
          'App is already up to date.',
        );

        return;
      }

      // --------------------------------------------------------
      // DON'T SHOW SAME DISMISSED VERSION AGAIN
      // --------------------------------------------------------

      if (_lastDismissedVersion ==
          release.versionName) {
        debugPrint(
          'Update already dismissed for '
          '${release.versionName}',
        );

        return;
      }

      // --------------------------------------------------------
      // SHOW UPDATE
      // --------------------------------------------------------

      await _showUpdateDialog(
        context,
        currentVersion,
        release,
        forceShow: false,
      );
    } catch (e) {
      // --------------------------------------------------------
      // AUTOMATIC CHECK SHOULD NEVER CRASH APP
      // --------------------------------------------------------

      debugPrint(
        'Automatic update check error: $e',
      );
    } finally {
      _automaticCheckRunning = false;
    }
  }

  // ============================================================
  // CURRENT APP VERSION
  // ============================================================

  Future<PackageVersion> _getCurrentVersion() async {
    final PackageInfo packageInfo =
        await PackageInfo.fromPlatform();

    final String versionName =
        packageInfo.version.trim().isEmpty
            ? '0.0.0'
            : packageInfo.version.trim();

    final int versionCode =
        int.tryParse(
              packageInfo.buildNumber.trim(),
            ) ??
            0;

    return PackageVersion(
      versionName: versionName,
      versionCode: versionCode,
    );
  }

  // ============================================================
  // GITHUB RELEASE
  // ============================================================

  Future<GitHubRelease> _getLatestGitHubRelease() async {
    final Uri uri =
        Uri.parse(githubApiUrl);

    final http.Response response =
        await http
            .get(
              uri,
              headers: const {
                'Accept':
                    'application/vnd.github+json',
                'X-GitHub-Api-Version':
                    '2022-11-28',
                'User-Agent':
                    'SAC-BCA-App',
              },
            )
            .timeout(
              const Duration(seconds: 20),
            );

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub API returned '
        '${response.statusCode}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid GitHub release response.',
      );
    }

    final String tagName =
        decoded['tag_name']
                ?.toString()
                .trim() ??
            '';

    final String releaseName =
        decoded['name']
                ?.toString()
                .trim() ??
            '';

    final String body =
        decoded['body']
                ?.toString()
                .trim() ??
            '';

    if (tagName.isEmpty) {
      throw Exception(
        'GitHub release tag not found.',
      );
    }

    // ==========================================================
    // FIND APK
    // ==========================================================

    String apkUrl = '';
    String apkName = '';

    final dynamic assets =
        decoded['assets'];

    if (assets is List) {
      for (final dynamic asset
          in assets) {
        if (asset
            is! Map<String, dynamic>) {
          continue;
        }

        final String name =
            asset['name']
                    ?.toString()
                    .trim() ??
                '';

        final String downloadUrl =
            asset['browser_download_url']
                    ?.toString()
                    .trim() ??
                '';

        if (name
                .toLowerCase()
                .endsWith('.apk') &&
            downloadUrl.isNotEmpty) {
          apkName = name;
          apkUrl = downloadUrl;

          break;
        }
      }
    }

    if (apkUrl.isEmpty) {
      throw Exception(
        'No APK found in latest GitHub release.',
      );
    }

    // ==========================================================
    // VERSION
    // ==========================================================

    final String versionName =
        _cleanVersionName(tagName);

    final int versionCode =
        _extractVersionCode(body);

    if (versionCode <= 0) {
      throw Exception(
        'GitHub release does not contain '
        'a valid versionCode.',
      );
    }

    return GitHubRelease(
      versionName: versionName,
      versionCode: versionCode,
      apkUrl: apkUrl,
      apkName: apkName,
      releaseName:
          releaseName.isEmpty
              ? versionName
              : releaseName,
      releaseNotes: body,
    );
  }

  // ============================================================
  // CLEAN VERSION
  // ============================================================

  String _cleanVersionName(
    String value,
  ) {
    String version =
        value.trim();

    if (version.startsWith('v') ||
        version.startsWith('V')) {
      version =
          version.substring(1);
    }

    return version;
  }

  // ============================================================
  // VERSION CODE
  // ============================================================

  int _extractVersionCode(
    String body,
  ) {
    final RegExp regex =
        RegExp(
      r'versionCode\s*:\s*(\d+)',
      caseSensitive: false,
    );

    final RegExpMatch? match =
        regex.firstMatch(body);

    if (match == null) {
      return 0;
    }

    return int.tryParse(
          match.group(1) ?? '',
        ) ??
        0;
  }

  // ============================================================
  // COMPARE
  // ============================================================

  int _compareVersion(
    int latestVersionCode,
    int currentVersionCode,
  ) {
    if (latestVersionCode >
        currentVersionCode) {
      return 1;
    }

    if (latestVersionCode <
        currentVersionCode) {
      return -1;
    }

    return 0;
  }

  // ============================================================
  // UPDATE DIALOG
  // ============================================================

  Future<void> _showUpdateDialog(
    BuildContext context,
    PackageVersion currentVersion,
    GitHubRelease release, {
    required bool forceShow,
  }) async {
    if (_updateDialogShowing) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    _updateDialogShowing = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons
                        .system_update_outlined,
                    color: Colors.purple,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'App Update Available',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A new version of SAC BCA '
                      'is available.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    _versionRow(
                      'Current version',
                      '${currentVersion.versionName}+'
                      '${currentVersion.versionCode}',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _versionRow(
                      'New version',
                      '${release.versionName}+'
                      '${release.versionCode}',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _versionRow(
                      'APK',
                      release.apkName,
                    ),

                    if (release
                        .releaseNotes
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 18,
                      ),

                      const Text(
                        "What's New",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Text(
                          release.releaseNotes,
                          maxLines: 10,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!forceShow)
                  TextButton(
                    onPressed: () {
                      _lastDismissedVersion =
                          release.versionName;

                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                        const Text('Later'),
                  ),

                if (forceShow)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                        const Text('Later'),
                  ),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );

                    _downloadAndInstall(
                      context,
                      release,
                    );
                  },
                  icon: const Icon(
                    Icons.download,
                  ),
                  label:
                      const Text('Update Now'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _updateDialogShowing = false;
    }
  }

  // ============================================================
  // VERSION ROW
  // ============================================================

  Widget _versionRow(
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DOWNLOAD + INSTALL
  // ============================================================

  Future<void> _downloadAndInstall(
    BuildContext context,
    GitHubRelease release,
  ) async {
    bool dialogShown = false;

    try {
      _downloadProgress.value =
          0.0;

      _showDownloadDialog(
        context,
        release,
      );

      dialogShown = true;

      // --------------------------------------------------------
      // TEMP DIRECTORY
      // --------------------------------------------------------

      final Directory directory =
          await getTemporaryDirectory();

      final String fileName =
          _safeFileName(
        release.apkName,
      );

      final String filePath =
          '${directory.path}/$fileName';

      final File file =
          File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      // --------------------------------------------------------
      // DOWNLOAD
      // --------------------------------------------------------

      final http.Client client =
          http.Client();

      try {
        final http.Request request =
            http.Request(
          'GET',
          Uri.parse(
            release.apkUrl,
          ),
        );

        request.headers.addAll(
          const {
            'Accept':
                'application/octet-stream',
            'User-Agent':
                'SAC-BCA-App',
          },
        );

        final http.StreamedResponse response =
            await client
                .send(request)
                .timeout(
                  const Duration(
                    minutes: 5,
                  ),
                );

        if (response.statusCode !=
            200) {
          throw Exception(
            'APK download failed: '
            '${response.statusCode}',
          );
        }

        final int? totalBytes =
            response.contentLength;

        int downloadedBytes = 0;

        final IOSink sink =
            file.openWrite();

        try {
          await for (
            final List<int> chunk
                in response.stream
          ) {
            downloadedBytes +=
                chunk.length;

            sink.add(chunk);

            if (totalBytes != null &&
                totalBytes > 0) {
              final double progress =
                  downloadedBytes /
                      totalBytes;

              _downloadProgress.value =
                  progress.clamp(
                0.0,
                1.0,
              );
            }
          }

          await sink.flush();
        } finally {
          await sink.close();
        }
      } finally {
        client.close();
      }

      // --------------------------------------------------------
      // CHECK APK
      // --------------------------------------------------------

      if (!await file.exists()) {
        throw Exception(
          'APK file was not created.',
        );
      }

      final int size =
          await file.length();

      if (size <= 0) {
        throw Exception(
          'Downloaded APK is empty.',
        );
      }

      _downloadProgress.value =
          1.0;

      // --------------------------------------------------------
      // CLOSE DOWNLOAD DIALOG
      // --------------------------------------------------------

      if (!context.mounted) {
        return;
      }

      if (dialogShown) {
        Navigator.of(context).pop();

        dialogShown = false;
      }

      // --------------------------------------------------------
      // OPEN INSTALLER
      // --------------------------------------------------------

      final OpenResult result =
          await OpenFilex.open(
        filePath,
        type:
            'application/vnd.android.package-archive',
      );

      debugPrint(
        'APK installer result: '
        '${result.type} - '
        '${result.message}',
      );

      if (result.type !=
          ResultType.done) {
        if (!context.mounted) {
          return;
        }

        _showMessage(
          context,
          'APK downloaded successfully, '
          'but Android could not open the installer.\n'
          'Please install the APK manually.',
          error: true,
        );
      }
    } catch (e) {
      debugPrint(
        'APK update error: $e',
      );

      if (!context.mounted) {
        return;
      }

      if (dialogShown) {
        Navigator.of(context).pop();

        dialogShown = false;
      }

      _showMessage(
        context,
        'Unable to download the update.\n'
        'Please try again.',
        error: true,
      );
    }
  }

  // ============================================================
  // SAFE FILE NAME
  // ============================================================

  String _safeFileName(
    String fileName,
  ) {
    String name =
        fileName.trim();

    if (name.isEmpty) {
      name =
          'SAC_BCA_Update.apk';
    }

    name = name.replaceAll(
      RegExp(
        r'[\\/:*?"<>|]',
      ),
      '_',
    );

    if (!name
        .toLowerCase()
        .endsWith('.apk')) {
      name = '$name.apk';
    }

    return name;
  }

  // ============================================================
  // CHECKING DIALOG
  // ============================================================

  void _showCheckingDialog(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(
                Radius.circular(18),
              ),
            ),
            content: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                CircularProgressIndicator(),

                SizedBox(
                  height: 18,
                ),

                Text(
                  'Checking for updates...',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DOWNLOAD DIALOG
  // ============================================================

  void _showDownloadDialog(
    BuildContext context,
    GitHubRelease release,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            title: const Text(
              'Downloading Update',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            content:
                ValueListenableBuilder<double>(
              valueListenable:
                  _downloadProgress,
              builder: (
                context,
                progress,
                child,
              ) {
                final bool hasProgress =
                    progress > 0;

                final int percentage =
                    (progress * 100)
                        .round()
                        .clamp(
                          0,
                          100,
                        );

                return Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.download_outlined,
                      size: 50,
                      color:
                          Colors.purple,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Text(
                      release.apkName,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    LinearProgressIndicator(
                      value: hasProgress
                          ? progress
                          : null,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      hasProgress
                          ? '$percentage%'
                          : 'Preparing download...',
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (hasProgress) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                        'Please do not close the app.',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NO UPDATE
  // ============================================================

  void _showNoUpdateDialog(
    BuildContext context,
    PackageVersion currentVersion,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You are up to date',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You are using the latest '
            'version of SAC BCA.\n\n'
            'Version: '
            '${currentVersion.versionName}\n'
            'Build: '
            '${currentVersion.versionCode}',
            style: const TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          backgroundColor: error
              ? Colors.red.shade700
              : Colors.green.shade700,
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(
            seconds: 5,
          ),
        ),
      );
  }
}

// =================================================================
// PACKAGE VERSION
// =================================================================

class PackageVersion {
  final String versionName;
  final int versionCode;

  const PackageVersion({
    required this.versionName,
    required this.versionCode,
  });
}

// =================================================================
// GITHUB RELEASE
// =================================================================

class GitHubRelease {
  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String apkName;
  final String releaseName;
  final String releaseNotes;

  const GitHubRelease({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    required this.apkName,
    required this.releaseName,
    required this.releaseNotes,
  });
}