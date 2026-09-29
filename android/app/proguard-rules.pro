# CodeRank release keep rules.
#
# Flutter engine + plugins carry their own keep rules; these cover only the
# reflective seams R8 cannot see: Google Play Services safety-net fragments
# used by google_sign_in, and Firestore's model/annotation classes that are
# populated reflectively from wire data.

-keep class io.flutter.plugin.editing.** { *; }

# Firebase Firestore: field-level (de)serialization via reflection.
-keep class com.google.firebase.firestore.model.** { *; }
-keep class com.google.firebase.firestore.util.** { *; }

# google_sign_in: activity/result contracts are instantiated reflectively.
-keep class com.google.android.gms.auth.api.signin.** { *; }

# Flutter's embedding relies on annotated entry points surviving shrinkage.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
