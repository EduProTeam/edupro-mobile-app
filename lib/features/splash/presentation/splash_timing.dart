/// Times measured from the first rasterized Flutter splash frame.
abstract final class SplashTiming {
  static const minimumDisplay = Duration(milliseconds: 2800);
  static const exitTransition = Duration(milliseconds: 350);
  static const entrance = Duration(milliseconds: 1500);
  static const logoStart = Duration.zero;
  static const logoEnd = Duration(milliseconds: 1000);
  static const letterEStart = Duration.zero;
  static const letterEEnd = Duration(milliseconds: 650);
  static const letterPStart = Duration(milliseconds: 100);
  static const letterPEnd = Duration(milliseconds: 750);
  static const capStart = Duration(milliseconds: 250);
  static const capEnd = Duration(milliseconds: 900);
  static const tasselStart = Duration(milliseconds: 400);
  static const tasselEnd = Duration(milliseconds: 1000);
  static const wordmarkStart = Duration(milliseconds: 600);
  static const wordmarkEnd = Duration(milliseconds: 1100);
  static const taglineStart = Duration(milliseconds: 850);
  static const taglineEnd = Duration(milliseconds: 1300);
  static const finishingStart = Duration(milliseconds: 1100);
  static const finishingEnd = entrance;
  static const initializationTimeout = Duration(seconds: 15);
}
