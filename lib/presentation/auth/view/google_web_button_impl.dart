import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:fe/core/config/app_config.dart';
import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web/web.dart' as web;

extension type _CredentialResponse(JSObject _) implements JSObject {
  external String get credential;
}

@JS('Object')
external JSObject _newObject();

@JS('google.accounts.id.initialize')
external void _gisInitialize(JSObject config);

@JS('google.accounts.id.renderButton')
external void _gisRenderButton(web.Element element, JSObject config);

const _viewType = 'google-gsi-btn';
bool _factoryRegistered = false;
bool _gsiInitialized = false;
void Function(String idToken)? _currentGoogleCallback;

void _ensureFactory() {
  if (_factoryRegistered) return;
  _factoryRegistered = true;
  ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
    final div = web.document.createElement('div') as web.HTMLDivElement;
    div.id = 'gsi-div-$viewId';
    div.style.height = '50px';
    div.style.width = '100%';
    return div;
  });
}

void _ensureGsiInitialized() {
  if (_gsiInitialized) return;
  try {
    if ((web.window as dynamic).__healthMateGsiInitDone == true) {
      _gsiInitialized = true;
      return;
    }
  } catch (_) {}
  _gsiInitialized = true;
  final callback = ((JSObject resp) {
    final idToken = _CredentialResponse(resp).credential;
    _currentGoogleCallback?.call(idToken);
  }).toJS;
  final initCfg = _newObject();
  initCfg['client_id'] = AppConfig.googleClientId.toJS;
  initCfg['callback'] = callback;
  _gisInitialize(initCfg);
  try {
    (web.window as dynamic).__healthMateGsiInitDone = true;
  } catch (_) {}
}

class GoogleWebButton extends StatefulWidget {
  const GoogleWebButton({super.key});

  @override
  State<GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<GoogleWebButton> {
  int? _viewId;

  @override
  void initState() {
    super.initState();
    _ensureFactory();
  }

  void _onViewCreated(int id) {
    _viewId = id;
    _trySetup();
  }

  void _trySetup() {
    if (!mounted || _viewId == null) return;
    if (AppConfig.googleClientId.isEmpty) {
      // Không retry: thiếu cấu hình thì có thử lại bao nhiêu lần cũng vô ích.
      debugPrint(
        '[GoogleSignIn] Thiếu GOOGLE_CLIENT_ID trong .env — bỏ qua nút Google.',
      );
      return;
    }
    final el = web.document.getElementById('gsi-div-$_viewId');
    if (el == null) {
      Future.delayed(const Duration(milliseconds: 100), _trySetup);
      return;
    }
    try {
      _ensureGsiInitialized();
      _currentGoogleCallback = (String idToken) {
        if (mounted) {
          context.read<AuthFormBloc>().add(
            GoogleLoginSubmitted(idToken: idToken),
          );
        }
      };

      final btnCfg = _newObject();
      btnCfg['type'] = 'standard'.toJS;
      btnCfg['theme'] = 'outline'.toJS;
      btnCfg['size'] = 'large'.toJS;
      _gisRenderButton(el, btnCfg);
    } catch (_) {
      Future.delayed(const Duration(milliseconds: 200), _trySetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: HtmlElementView(
        viewType: _viewType,
        onPlatformViewCreated: _onViewCreated,
      ),
    );
  }
}
