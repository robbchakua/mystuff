import 'dart:math';

class AppDetails {
  static String version = "1.0.0-rc";
  static DateTime versionDate = DateTime(2024, 01, 28);
  static String myEmail = "rusmarkcompany@gmail.com";
  static String myNumber = "+254722471362";
}

final double fiftyMeters = 4.50968209 * (pow(10, -4).toDouble());
const double showMarkersRadius = 13.4448358386;

class Urls {
  static String baseUrl = "https://rusmark.io.ke";
  static String postUrl = "$baseUrl/post.php";
  static String userUrl = "$baseUrl/user.php";
}

///A requests that indicates the desired action to be performed for a given resource
enum RequestType {
  get,
  login,
  session,
  logout,
  postItem,
  putItem,
  dropItem,
  emailCheck,
  postUser,
  putUser,
  dropUser,
  listUsers,
  postBin,
  putBin,
  dropBin,
  getBinAccess,
  grantBinAccess,
  revokeBinAccess,
}

class InputErrors {
  static RegExp emailChars = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  static RegExp uppercaseChars = RegExp(r'^(?=.*?[A-Z])');
  static RegExp numberChars = RegExp(r'^(?=.*?[0-9])');
  static RegExp specialChars = RegExp(r'^(?=.*?[!@#\$&*~])');
  static String shortPassword = 'Password length is too short (min. 10)';
  static String empty = 'This field cannot be empty';
  static String emailError = 'Not a valid Email';
  static String longName = 'Password length is too long (max 20)';
  static String missingNumber = 'Password must have a number';
  static String missingSpecialChar = 'Password must have a special character';
  static String missingUppercase = 'Password must have an uppercase character';
  static String emptyPassword = 'Password cannot be empty';
  static String emptyUsername = 'Name is empty';
  static String emptyEmail = 'Email cannot be empty';
}
