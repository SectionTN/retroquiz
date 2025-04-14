import 'dart:ui' as ui;
import "dart:async";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nes_ui/nes_ui.dart';
import 'dart:math' as math;

import 'package:spritewidget/spritewidget.dart';

// The state of our login process
enum LoginState { initial, loading, success, error }

// Login state notifier
class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(LoginState.initial);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    try {
      state = LoginState.loading;

      // Start the Google sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = LoginState.initial; // User canceled the sign-in
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      await _auth.signInWithCredential(credential);

      state = LoginState.success;
    } catch (e) {
      print("Error signing in: $e");
      state = LoginState.error;
    }
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier();
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _titleBounceAnimation;
  late Animation<double> _subtitleBounceAnimation;
  late Animation<double> _scaleAnimation;

  late NodeWithSize _rootNode;
  bool _spriteLoaded = false;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _titleBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticInOut));

    _subtitleBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticInOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rootNode = NodeWithSize(const Size(400, 400));

    _loadSprite();
  }

  Future<void> _loadSprite() async {
    // Load the sprite image
    final ByteData data = await rootBundle.load(
      'assets/sprites/pumpkin_dude.png',
    );
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    // Create sprite texture
    final spriteTexture = SpriteTexture(image);

    // Assuming the sprite sheet has 8 frames in a horizontal row
    final int frameCount = 8;
    final double frameWidth = image.width / frameCount;
    final List<Sprite> frames = [];

    for (int i = 0; i < frameCount; i++) {
      // Create sprite using the correct constructor
      frames.add(
        Sprite(
          spriteTexture,
          Rect.fromLTWH(i * frameWidth, 0, frameWidth, image.height.toDouble()),
        ),
      );
    }

    // Create animation - using the appropriate constructor
    final spriteAnim = SpriteAnimationGroupNode(
      frames, // List of sprites for frames
      0.1, // Frame time in seconds
    );

    // Position the animation in center
    spriteAnim.position = Offset(
      _rootNode.size.width / 2,
      _rootNode.size.height / 2,
    );
    spriteAnim.size = const Size(64, 64);

    // Add to scene
    _rootNode.addChild(spriteAnim);

    // Mark sprite as loaded
    setState(() {
      _spriteLoaded = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return Scaffold(
      body: NesContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _titleBounceAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: const Text('RetroQuiz', style: TextStyle(fontSize: 32)),
              ),

              const SizedBox(height: 20),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _subtitleBounceAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'please login to continue',
                  style: TextStyle(
                    fontSize: 8,
                    color: ColorScheme.of(context).onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Sprite widget display
              Transform.rotate(
                angle: math.sin(_controller.value * math.pi) * 0.05,
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: _spriteLoaded
                      ? SpriteWidget(_rootNode)
                      : const NesContainer(
                          child: Center(child: Text('Loading...')),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Login button with state handling
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: loginState == LoginState.loading
                        ? 1.0 + (_controller.value * 0.1)
                        : 1.0,
                    child: child,
                  );
                },
                child: NesButton(
                  type: NesButtonType.primary,
                  onPressed: loginState == LoginState.loading
                      ? null
                      : () =>
                          ref.read(loginProvider.notifier).signInWithGoogle(),
                  child: SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sign in with'),
                        const SizedBox(width: 8),
                        if (loginState == LoginState.loading)
                          const Icon(FontAwesomeIcons.spinner, size: 24)
                        else
                          const Icon(FontAwesomeIcons.google),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Error message
              if (loginState == LoginState.error)
                const NesContainer(
                  width: 280,
                  child: Text(
                    'Error signing in. Please try again.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
