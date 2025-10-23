import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrailerPlayerScreen extends StatefulWidget {
  final String movieTitle;
  final String trailerUrl;

  const TrailerPlayerScreen({
    super.key,
    required this.movieTitle,
    required this.trailerUrl,
  });

  @override
  State<TrailerPlayerScreen> createState() => _TrailerPlayerScreenState();
}

class _TrailerPlayerScreenState extends State<TrailerPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayer.convertUrlToId(widget.trailerUrl);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: false,
        enableCaption: true,
      ),
    );

    // Set preferred orientations for video playback
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Listen for full-screen changes
    _controller.addListener(() {
      if (_controller.value.isFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = _controller.value.isFullScreen;
        });
      }
    });
  }

  @override
  void dispose() {
    // Reset to portrait orientation when leaving the screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // The player forces portraitUp after exiting fullscreen
        // This ensures other orientations work afterwards too
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: primaryColor,
        progressColors: ProgressBarColors(
          playedColor: primaryColor,
          handleColor: primaryColor,
        ),
        topActions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.movieTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        bottomActions: [
          const CurrentPosition(),
          const SizedBox(width: 10),
          ProgressBar(
            isExpanded: true,
            colors: ProgressBarColors(
              playedColor: primaryColor,
              handleColor: primaryColor,
              backgroundColor: Colors.grey[700]!,
              bufferedColor: Colors.grey[500]!,
            ),
          ),
          const SizedBox(width: 10),
          const RemainingDuration(),
          const FullScreenButton(),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _isFullScreen 
              ? null 
              : AppBar(
                  title: Text(
                    'Trailer: ${widget.movieTitle}',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                  elevation: 0,
                ),
          body: Center(
            child: player,
          ),
        );
      },
    );
  }
}
