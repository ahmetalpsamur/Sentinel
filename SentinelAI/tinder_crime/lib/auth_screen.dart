import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'home_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAuthority = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isHovering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate authentication
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (_, __, ___) => CrimeDetectionHomePage(
          isAuthority: _isAuthority,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    Colors.black,
                    Colors.grey[900]!,
                  ],
                  stops: const [0.1, 1],
                ),
              ),
            ),
          ),

          // Red accent shapes
          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[900]!.withOpacity(0.15),
              ),
            ),
          ),

          Positioned(
            bottom: -size.width * 0.3,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[800]!.withOpacity(0.1),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.1,
                vertical: size.height * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Logo with animation
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/ShilDir_only_logo_transparent.png',
                      height: size.height * 0.15,
                      color: Colors.red[700],
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Animated title
                  AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'ShielDir',
                        textStyle: GoogleFonts.orbitron(
                          color: Colors.red[700],
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    totalRepeatCount: 1,
                  ),

                  const SizedBox(height: 10),

                  // Subtitle with fade animation
                  SizedBox(
                    height: 30, // Yazının yaklaşık yüksekliği
                    child: AnimatedTextKit(
                      animatedTexts: [
                        FadeAnimatedText(
                          'Secure Access Portal',
                          textStyle: GoogleFonts.rajdhani(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                      isRepeatingAnimation: true,
                      repeatForever: true, // Sürekli tekrar etsin
                      totalRepeatCount: 999999, // Alternatif: çok yüksek değer
                      pause: const Duration(milliseconds: 500),
                    ),
                  ),


                  SizedBox(height: size.height * 0.05),

                  // Form with neumorphic effect
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.red[900]!.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey[800]!.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'EMAIL',
                              labelStyle: GoogleFonts.rajdhani(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red[700]!,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: Colors.grey[500],
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'PASSWORD',
                              labelStyle: GoogleFonts.rajdhani(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red[700]!,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.grey[500],
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[500],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Authority checkbox with cool animation
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isAuthority = !_isAuthority;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isAuthority
                                    ? Colors.red[900]!.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isAuthority
                                      ? Colors.red[700]!
                                      : Colors.grey[700]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Bu satırı ekleyin
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: _isAuthority
                                        ? Icon(
                                      Icons.verified_user,
                                      color: Colors.red[700],
                                      size: 24,
                                    )
                                        : Icon(
                                      Icons.person_outline,
                                      color: Colors.grey[500],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible( // Bu widgetı ekleyin
                                    child: FittedBox( // Bu widgetı ekleyin
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Law Enforcement Authority',
                                        style: GoogleFonts.rajdhani(
                                          color: Colors.grey[300],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Login button with hover effect
                          MouseRegion(
                            onEnter: (_) => setState(() => _isHovering = true),
                            onExit: (_) => setState(() => _isHovering = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red[800]!,
                                    Colors.red[600]!,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isHovering
                                    ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.6),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                                    : [],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: Size(double.infinity, 50), // Sabit yükseklik ekledik
                                  padding: const EdgeInsets.symmetric(horizontal: 16), // Yan padding ekledik
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                )
                                    : FittedBox( // Row'u FittedBox ile sarmaladık
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min, // Row'un minimum genişlikte olmasını sağladık
                                    children: [
                                      Text(
                                        'ACCESS SECURE SYSTEM',
                                        style: GoogleFonts.orbitron(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                        maxLines: 1, // Tek satırda kalmasını sağladık
                                        overflow: TextOverflow.ellipsis, // Taşma durumunda ... göster
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Forgot password with cool animation
                          TextButton(
                            onPressed: () {
                              // Add forgot password functionality
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.rajdhani(
                                color: Colors.red[400],
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Footer text
                  Text(
                    '© 2023 CRIME SWIPER | SECURE LAW ENFORCEMENT PORTAL',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: Colors.grey[600],
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}