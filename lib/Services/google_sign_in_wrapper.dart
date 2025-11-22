// Conditional export: chooses web or mobile implementation depending on platform.
export 'google_sign_in_wrapper_mobile.dart'
    if (dart.library.html) 'google_sign_in_wrapper_web.dart';
