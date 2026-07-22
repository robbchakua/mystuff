import 'package:dad_app/utils/utils.dart';
import 'package:flutter/material.dart';

ThemeData darkTheme(BuildContext context) {
  isDarkTheme = true;
  final visibleButtonColor = MaterialStateProperty.resolveWith<Color>(
    (states) => states.contains(MaterialState.disabled)
        ? Colors.white54
        : Colors.white,
  );
  ThemeData themeData = ThemeData(
      drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.white,
          scrimColor: Color(0xC1000000)),
      snackBarTheme: const SnackBarThemeData(backgroundColor: Colors.black),
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: Colors.white),
      dialogTheme: const DialogTheme(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)))),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
        foregroundColor: visibleButtonColor,
        iconColor: visibleButtonColor,
        shadowColor: MaterialStateProperty.all(Colors.white),
      )),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          foregroundColor: visibleButtonColor,
          iconColor: visibleButtonColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: visibleButtonColor,
          iconColor: visibleButtonColor,
          side: MaterialStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(MaterialState.disabled)
                  ? Colors.white38
                  : Colors.white,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: visibleButtonColor,
          iconColor: visibleButtonColor,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
      ),
      brightness: Brightness.dark,
      dividerColor: Colors.grey[500]!,
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            EdgeInsets.symmetric(horizontal: screenWidth(context) / 30),
        filled: true,
        fillColor: Colors.transparent,
        errorStyle: const TextStyle(color: Colors.red),
        errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
            borderRadius: BorderRadius.all(Radius.circular(30))),
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30))),
        focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(width: 2, color: Theme.of(context).dividerColor),
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: TextStyle(
            fontSize: screenHeight(context) / 59, color: Colors.white),
        isDense: true,
        floatingLabelStyle: const TextStyle(color: Colors.white, fontSize: 20),
        labelStyle: const TextStyle(color: Colors.white),
        suffixIconColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white)),
      colorScheme: ColorScheme.dark(
          background: Colors.grey[800]!,
          primary: const Color(0xFF101010),
          onPrimary: Colors.white,
          secondary: Colors.black,
          onSecondary: Colors.white,
          tertiary: Colors.white,
          onTertiary: Colors.black,
          onSurface: Colors.white));
  return themeData;
}

// ThemeData lightTheme(BuildContext context) {
//   isDarkTheme = false;
//   ThemeData themeData = ThemeData(
//       textSelectionTheme:
//           const TextSelectionThemeData(cursorColor: Colors.black),
//       dialogTheme: const DialogTheme(
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(Radius.circular(30)))),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ButtonStyle(
//         iconColor: MaterialStateProperty.all(Colors.black),
//       )),
//       brightness: Brightness.light,
//       dividerColor: Colors.grey[500]!,
//       inputDecorationTheme: InputDecorationTheme(
//         contentPadding:
//             EdgeInsets.symmetric(horizontal: screenWidth(context) / 30),
//         filled: true,
//         fillColor: Colors.transparent,
//         errorStyle: const TextStyle(color: Colors.red),
//         errorBorder: const OutlineInputBorder(
//             borderSide: BorderSide(color: Colors.red),
//             borderRadius: BorderRadius.all(Radius.circular(30))),
//         border: const OutlineInputBorder(
//             borderRadius: BorderRadius.all(Radius.circular(30))),
//         focusedBorder: OutlineInputBorder(
//             borderSide:
//                 BorderSide(width: 2, color: Theme.of(context).dividerColor),
//             borderRadius: const BorderRadius.all(Radius.circular(20))),
//         floatingLabelBehavior: FloatingLabelBehavior.always,
//         hintStyle: TextStyle(
//             fontSize: screenHeight(context) / 59, color: Colors.black),
//         isDense: true,
//         suffixIconColor: Colors.black,
//       ),
//       appBarTheme: const AppBarTheme(
//           titleTextStyle: TextStyle(color: Colors.black),
//           iconTheme: IconThemeData(color: Colors.black)),
//       colorScheme: ColorScheme.light(
//           background: Colors.grey[200]!,
//           primary: Colors.grey[100]!,
//           secondary: Colors.white,
//           tertiary: Colors.black));
//
//   return themeData;
// }

Color middleGrey(BuildContext context) {
  return Theme.of(context).dividerColor;
}

Color primaryColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}

Color secondaryColor(BuildContext context) {
  return Theme.of(context).colorScheme.secondary;
}

Color inverseColor(BuildContext context) {
  return Theme.of(context).colorScheme.tertiary;
}

Color backgroundColor = const Color(0xFF1E1E1E);
