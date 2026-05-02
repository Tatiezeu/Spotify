import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/email_signup_screen.dart';
import 'screens/auth/password_signup_screen.dart';
import 'screens/auth/profile_signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/player/now_playing_screen.dart';
import 'screens/artist/artist_screen.dart';
import 'screens/album/album_screen.dart';
import 'screens/playlist/playlist_screen.dart';
import 'screens/playlist/create_playlist_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/player/queue_screen.dart';
import 'services/api_service.dart';
import 'package:provider/provider.dart';
import 'providers/player_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Sportify app starting...');
  
  await ApiService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: const SpotifyCloneApp(),
    ),
  );
}

class SpotifyCloneApp extends StatelessWidget {
  const SpotifyCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup/email': (context) => const EmailSignupScreen(),
        '/signup/password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final email = args is String ? args : '';
          return PasswordSignupScreen(email: email);
        },
        '/signup/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return ProfileSignupScreen(
            email: args?['email'] ?? '',
            password: args?['password'] ?? '',
          );
        },
        '/login': (context) => const WelcomeScreen(),
        '/home': (context) => const MainScreen(),
        '/now-playing': (context) => const NowPlayingScreen(),
        '/artist': (context) => const ArtistScreen(),
        '/album': (context) => const AlbumScreen(),
        '/playlist': (context) => const PlaylistScreen(),
        '/playlist/create': (context) => const CreatePlaylistScreen(),
        '/liked-songs': (context) => const PlaylistScreen(isLikedSongs: true),
        '/settings': (context) => const SettingsScreen(),
        '/queue': (context) => QueueScreen(
          queue: const [
            {'title': 'One Of The Girls - Sped Up', 'artist': 'The Weeknd', 'image': 'https://picsum.photos/200?track=1'},
            {'title': 'Bring It On', 'artist': 'P-Square', 'image': 'https://picsum.photos/200?track=2'},
          ],
          onPlay: (index) {},
        ),
      },
    );
  }
}
