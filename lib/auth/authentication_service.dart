import 'package:audio_flutter_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  FirebaseAuth _firebaseAuth;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  UserCredential _userCredential;

  AuthenticationService(this._firebaseAuth);

  Stream<User> get authStateChanges => _firebaseAuth.idTokenChanges();

  String getUserid() {
    return _firebaseAuth.currentUser.uid;
  }

  Future signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    print(googleUser.email);
    // Once signed in, return the UserCredential
    await auth
        .signInWithCredential(credential)
        .then((value) => _userCredential = value);

    // Firebase
    CollectionReference users = firestore.collection('users');

    final cekuser = await users.doc(googleUser.email).get();
    if (cekuser.exists) {
      users.doc(googleUser.email).set({
        'uid': _userCredential.user.uid,
        'name': googleUser.displayName,
        'email': googleUser.email,
        'photo': googleUser.photoUrl,
        'CreatedAt': _userCredential.user.metadata.creationTime.toString(),
        'lastlogin': _userCredential.user.metadata.lastSignInTime.toString(),
        // 'list_cari': (R,RE,REZA)
      }).then((value) async {
        String temp = '';
        try {
          for (var i = 0; i < googleUser.displayName.length; i++) {
            temp = temp + googleUser.displayName[i];
            await users.doc(googleUser.email).set({
              'list_cari': FieldValue.arrayUnion([temp.toUpperCase()])
            }, SetOptions(merge: true));
          }
        } catch (e) {
          print(e);
        }
      });
    } else {
      users.doc(googleUser.email).update({
        'lastlogout': _userCredential.user.metadata.lastSignInTime.toString()
      });
    }
    return MyHomePage(title: 'Your Audio Feed ');
  }


  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _firebaseAuth.currentUser;
  }

  Future<String> updateProfile(
      String url, String name, User firebaseUser) async {
    try {
      await firebaseUser.updateProfile(photoURL: url, displayName: name);
      await firebaseUser.reload();
      return 'Profile details updated';
    } catch (e) {
      return e.message;
    }
  }

  Future<String> signIn({String email, String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return "Signed in";
    } catch (e) {
      return e.message;
    }
  }

  Future<String> signUp({String email, String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      return "Signed up";
    } catch (e) {
      return e.message;
    }
  }
}
