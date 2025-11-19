abstract class Routes {
  Routes._();
  
  static const splash = Paths.splash;
  static const auth = Paths.auth;
  static const home = Paths.home;
  static const createFamily = Paths.createFamily;
  static const alarm = Paths.alarm;
  static const documents = Paths.documents;
  static const expense = Paths.expense;
  static const passwords = Paths.passwords;
}

abstract class Paths {
  Paths._();
  
  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const createFamily = '/create-family';
  static const alarm = '/alarm';
  static const documents = '/documents';
  static const expense = '/expense';
  static const passwords = '/passwords';
}
