import 'dart:async';
import 'dart:io';
import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/utils/responsive.dart';
import 'package:bayt_alhikma/view_model/download_audio.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class NowPlayingScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  const NowPlayingScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late final AudioPlayer _player;
  final GlobalKey _waveKey = GlobalKey();

  // Timer to save progress periodically
  Timer? _saveTimer;

  bool _isDownloading = false;
  bool _isDownloaded = false;

  // Helper to get Language
  bool isArabicLocale([bool listen = true]) {
    return Provider.of<LanguageProvider>(context, listen: listen).isArabic;
  }

  // Generate a consistent ID/Filename for this book
  String get _fileName {
    final title = widget.book['nameEN'] ?? widget.book['title'] ?? 'audiobook';
    return title
        .toString()
        .replaceAll(RegExp(r'[^\w\s]+'), '') // Remove special chars
        .replaceAll(' ', '_'); // Replace spaces with underscores
  }

  // Use the filename as the unique ID for storage
  String get _bookId => _fileName;

  // Visualization samples
  final List<double> _samples = [
    0.2,
    0.25,
    0.3,
    0.4,
    0.35,
    0.6,
    0.5,
    0.4,
    0.45,
    0.6,
    0.7,
    0.65,
    0.55,
    0.5,
    0.45,
    0.4,
    0.38,
    0.36,
    0.33,
    0.31,
    0.35,
    0.4,
    0.45,
    0.5,
    0.58,
    0.62,
    0.6,
    0.5,
    0.42,
    0.38,
    0.3,
    0.25,
    0.2,
    0.22,
    0.28,
    0.34,
    0.4,
    0.45,
    0.5,
    0.46,
  ];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();

    // Start periodic save timer (every 5 seconds)
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_player.playing) {
        _saveProgress();
      }
    });
  }

  Future<void> _init() async {
    try {
      final audioUrl =
          widget.book['audio'] ??
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

      // 1. Determine Local Path
      final dir = await getApplicationDocumentsDirectory();
      final localPath = "${dir.path}/audio/$_fileName.mp3";
      final file = File(localPath);

      // 2. Set Audio Source (Offline vs Online)
      if (await file.exists()) {
        debugPrint("Playing Offline File: $localPath");
        await _player.setFilePath(localPath);
        if (mounted) setState(() => _isDownloaded = true);
      } else {
        debugPrint("Playing Online Stream");
        await _player.setUrl(audioUrl);
        if (mounted) setState(() => _isDownloaded = false);
      }

      // 3. Mark this as the Last Played Book (for Recommended Screen)
      // Make sure you added `saveLastPlayedBookId` to LocalStorageService!
      await LocalStorageService.saveLastPlayedBookId(
        widget.book['id'] ?? _bookId,
      );

      // 4. Restore Playback Position
      final savedMs = await LocalStorageService.getPlaybackPosition(_bookId);
      if (savedMs > 0) {
        debugPrint("Resuming from $savedMs ms");
        await _player.seek(Duration(milliseconds: savedMs));
      }
    } catch (e) {
      debugPrint("Error initializing audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading audio: $e')));
      }
    }
  }

  void _saveProgress() {
    final currentMs = _player.position.inMilliseconds;
    if (currentMs > 0) {
      LocalStorageService.savePlaybackPosition(_bookId, currentMs);
    }
  }

  Future<void> _handleDownload() async {
    final audioUrl =
        widget.book['audio'] ??
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

    // Request permissions
    var status = await Permission.storage.request();

    if (status.isGranted ||
        await Permission.storage.isLimited ||
        Platform.isAndroid) {
      setState(() => _isDownloading = true);

      try {
        final savedPath = await downloadAudio(
          audioUrl,
          "$_fileName.mp3",
          onProgress: (received, total) {
            // Optional: update a progress bar specifically for download
          },
        );

        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to $savedPath')));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
        }
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to download.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Save one last time before destroying the player
    _saveProgress();
    _saveTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  double _progressFraction(Duration position, Duration? duration) {
    if (duration == null || duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  void _handleSeekFromGlobal(Offset globalPosition) {
    final renderBox = _waveKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final local = renderBox.globalToLocal(globalPosition);
    final frac = (local.dx / renderBox.size.width).clamp(0.0, 1.0);
    final dur = _player.duration;

    if (dur != null) {
      final newPos = dur * frac;
      _player.seek(newPos);
      // Save immediately on manual seek
      LocalStorageService.savePlaybackPosition(_bookId, newPos.inMilliseconds);
    }
  }

  Widget _buildCover() {
    final w = Responsive.wp(context, 0.58);
    final h = w;
    final url = (widget.book['image'] ?? widget.book['img'] ?? '').toString();

    if (url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return Image.network(
        url,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Image.asset(
          'images/hero.png',
          width: w,
          height: h,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      'images/hero.png',
      width: w,
      height: h,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final bool isArabic = isArabicLocale();

    final title = isArabic
        ? widget.book['nameAR'] ?? widget.book['title']
        : widget.book['nameEN'] ?? widget.book['title'];

    final author = isArabic
        ? widget.book['authorAR'] ?? widget.book['author']
        : widget.book['authorEN'] ?? widget.book['author'];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
            ),

            // Cover & Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ClipOval(child: _buildCover()),
                      const Positioned(
                        top: 16,
                        child: Text(
                          'Now Playing',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black45),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      title.toString(),
                      textAlign: TextAlign.center,
                      style:  TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    author.toString(),
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Waveform & Timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, posSnapshot) {
                  final position = posSnapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: _player.durationStream,
                    builder: (context, durSnapshot) {
                      final duration = durSnapshot.data;
                      final fraction = _progressFraction(position, duration);
                      return Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                _fmt(position),
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  key: _waveKey,
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (tap) =>
                                      _handleSeekFromGlobal(tap.globalPosition),
                                  onHorizontalDragUpdate: (drag) =>
                                      _handleSeekFromGlobal(
                                        drag.globalPosition,
                                      ),
                                  child: SizedBox(
                                    height: Responsive.hp(context, 0.07),
                                    child: Stack(
                                      children: [
                                        // Background Wave
                                        Align(
                                          alignment: isArabic
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: _samples
                                                .map(
                                                  (s) => Container(
                                                    width: Responsive.wp(
                                                      context,
                                                      0.01,
                                                    ),
                                                    height:
                                                        Responsive.hp(
                                                          context,
                                                          0.015,
                                                        ) +
                                                        (s *
                                                            Responsive.hp(
                                                              context,
                                                              0.04,
                                                            )),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                        // Active Wave (Colored)
                                        ClipRect(
                                          child: Align(
                                            alignment: isArabic
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            widthFactor: fraction,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: _samples
                                                  .map(
                                                    (s) => Container(
                                                      width:
                                                          4, // Fixed width for cleaner look
                                                      height: 12 + (s * 36),
                                                      decoration: BoxDecoration(
                                                        color: AppStyles
                                                            .primaryGold,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                duration != null ? _fmt(duration) : '--:--',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 26),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Download Button
                  if (_isDownloading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      onPressed: _isDownloaded ? null : _handleDownload,
                      icon: Icon(
                        _isDownloaded
                            ? Icons.cloud_done
                            : Icons.cloud_download_outlined,
                        color: _isDownloaded ? Colors.green : Colors.black,
                      ),
                    ),

                  // Previous
                  IconButton(
                    onPressed: () {
                      _player.seek(Duration.zero);
                    },
                    icon: const Icon(Icons.skip_previous),
                  ),

                  // Play/Pause
                  StreamBuilder<bool>(
                    stream: _player.playingStream,
                    builder: (context, snap) {
                      final isPlaying = snap.data ?? false;
                      return ElevatedButton(
                        onPressed: () {
                          if (isPlaying) {
                            _player.pause();
                          } else {
                            _player.play();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(18),
                          backgroundColor: AppStyles.primaryGold,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      );
                    },
                  ),

                  // Next (Skip to End)
                  IconButton(
                    onPressed: () {
                      final d = _player.duration;
                      if (d != null) _player.seek(d);
                    },
                    icon: const Icon(Icons.skip_next),
                  ),

                  // Loop Mode
                  StreamBuilder<LoopMode>(
                    stream: _player.loopModeStream,
                    builder: (context, snapshot) {
                      final mode = snapshot.data ?? LoopMode.off;
                      return IconButton(
                        onPressed: () {
                          if (mode == LoopMode.off) {
                            _player.setLoopMode(LoopMode.all);
                          } else if (mode == LoopMode.all) {
                            _player.setLoopMode(LoopMode.one);
                          } else {
                            _player.setLoopMode(LoopMode.off);
                          }
                        },
                        icon: Icon(
                          mode == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: mode == LoopMode.off
                              ? Colors.black
                              : AppStyles.primaryGold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
