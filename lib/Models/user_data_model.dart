import 'package:cloud_firestore/cloud_firestore.dart';
import '../Enums/theme.dart';
import '../Enums/currency.dart';

class UserDataModel {
  final String uid;
  final String? email;
  final bool isAnonymous;
  final Currency defaultCurrency;
  final Theme theme;
  final double pollingTime;


  const UserDataModel({
    required this.uid,
    this.email,
    required this.isAnonymous,
    required this.defaultCurrency,
    required this.theme,
    required this.pollingTime,
  });

  //Factory to generate UserDataModel instance from the Firestore database
  factory UserDataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserDataModel(
      uid: doc.id,
      email: data['email'],
      isAnonymous: data['isAnonymous'] ?? true,
      defaultCurrency: Currency.fromCode(data['defaultCurrency']),
      theme: Theme.fromCode(data['theme']),
      pollingTime: (data['pollingTime'] as num?)?.toDouble() ?? 10.0,
    );
  }

  //Map method to save a UserDataModel to Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'email' : email,
      'isAnonymous' : isAnonymous,
      'defaultCurrency' : defaultCurrency.code,
      'theme' : theme.code,
      'pollingTime' : pollingTime,
    };
  }

}