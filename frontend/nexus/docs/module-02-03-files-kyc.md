# Module 2 — FileUpload + Module 3 — KYC

---

## Module 2 : FileUploadService

### Fichiers
| Fichier | Rôle |
|---|---|
| `features/files/data/file_upload_service.dart` | Appel API multipart |
| `features/files/presentation/providers/file_upload_provider.dart` | État Riverpod |

### Pourquoi un service séparé pour les fichiers ?

L'upload d'images est utilisé par KYC (document, selfie, relevé MoMo).
Demain il pourrait l'être par un écran de profil (avatar).
En isolant la logique dans `FileUploadService`, chaque feature consomme
le service sans dupliquer le code multipart.

### Compression automatique

```dart
static const int _maxBytes = 4 * 1024 * 1024; // 4 MB

if (await file.length() > _maxBytes) {
  fileToUpload = await _compress(file);
}
```

La limite backend est 5 MB, mais on compresse dès 4 MB pour avoir une marge.
`flutter_image_compress` (déjà dans pubspec) redimensionne à 1024px max
et réduit la qualité JPEG à 75 — imperceptible à l'œil mais divisible par 3.

### Provider Family

```dart
final fileUploadProvider = StateNotifierProvider.family<
    FileUploadNotifier, FileUploadState, String>(
  (ref, slot) => FileUploadNotifier(...),
);
```

Le paramètre `String` est un **slot** d'image : `'document'`, `'selfie'`, `'statement'`.
Chaque slot a son propre état indépendant. Ainsi, l'upload du selfie n'efface pas
l'état de l'upload du document. Usage dans un écran :

```dart
final docState  = ref.watch(fileUploadProvider('document'));
final selfState = ref.watch(fileUploadProvider('selfie'));
```

### Sealed class pour l'état

```dart
sealed class FileUploadState { ... }
final class FileUploadIdle    extends FileUploadState { ... }
final class FileUploadLoading extends FileUploadState { ... }
final class FileUploadSuccess extends FileUploadState { final String url; }
final class FileUploadError   extends FileUploadState { final String message; }
```

`sealed` + `final` = le compilateur garantit que le `switch` est exhaustif dans l'UI.
Si demain on ajoute un état `FileUploadCancelled`, le compilateur signalera
tous les switch qui ne le gèrent pas.

---

## Module 3 : KYC

### Fichiers
| Fichier | Rôle |
|---|---|
| `features/kyc/data/models/kyc_models.dart` | Requêtes/réponses typées |
| `features/kyc/data/repositories/kyc_repository.dart` | Appels API KYC |
| `features/kyc/presentation/providers/kyc_provider.dart` | Machine d'état KYC |
| `features/kyc/presentation/widgets/kyc_progress_bar.dart` | Barre de progression réutilisable |
| `features/kyc/presentation/screens/kyc_intro_screen.dart` | Écran d'introduction |
| `features/kyc/presentation/screens/kyc_document_screen.dart` | Upload document + selfie |
| `features/kyc/presentation/screens/kyc_financial_screen.dart` | Revenus + relevé MoMo |
| `features/kyc/presentation/screens/kyc_review_screen.dart` | Récapitulatif + soumission |
| `features/kyc/presentation/screens/kyc_pending_screen.dart` | Attente / Rejeté |

### Enums locaux KYC

Le fichier `kyc_models.dart` définit deux enums spécifiques au KYC :

- `DocumentType` (CNI, CIP, PASSEPORT, PERMIS) — avec `displayName` pour les chips
- `IncomeSource` (SALARIE, INDEPENDANT, COMMERCE, AGRICULTURE, TRANSFERT, AUTRE) — pour les radio buttons

Ces enums sont distincts des enums globaux (`app_enums.dart`) car ils sont
uniquement utilisés dans ce module.

### KycState et KycStep

La `KycState` mémorise à la fois l'étape courante (`KycStep`) et les données
collectées au fil des sessions (documentUrl, selfieUrl, etc.).

Cela permet :
1. Au `KycReviewScreen` d'afficher le récapitulatif sans refaire d'appel API
2. À `loadStatus()` de **reprendre au bon endroit** si l'utilisateur quitte et revient

```dart
KycStep _stepFromStatus(KycStatus status) => switch (status) {
  KycStatus.notStarted  => KycStep.intro,
  KycStatus.session1Done => KycStep.financial,
  KycStatus.session2Done => KycStep.review,
  KycStatus.validated   => KycStep.pending,
  KycStatus.rejected    => KycStep.rejected,
};
```

### Sync avec authProvider après session 3

```dart
// Dans submitSession3()
await _ref.read(authProvider.notifier).restoreSession();
```

Après la soumission finale, on force un rechargement du user global via
`/auth/me`. Ainsi, le `kycStatus` dans `AuthUser` est mis à jour immédiatement.
Le router détectera le changement et ne redirigera plus vers `/kyc` au prochain
démarrage de l'app.

### Navigation KYC

Les routes KYC sont **hors du shell** (pas de bottom nav) :

```
/kyc           → KycIntroScreen
/kyc/document  → KycDocumentScreen
/kyc/financial → KycFinancialScreen
/kyc/review    → KycReviewScreen
/kyc/pending   → KycPendingScreen
```

Elles sont imbriquées via `routes: [...]` dans le `GoRoute` parent `/kyc`.
Ainsi, `/kyc/document` hérite du contexte de `/kyc` sans duplication de code.

### `PopScope(canPop: false)` sur KycPendingScreen

L'écran "pending" empêche le retour arrière. L'utilisateur doit explicitement
cliquer sur "Retour à l'accueil". Raison : revenir en arrière après une soumission
n'a pas de sens (le dossier est déjà chez l'IMF).

### Radio buttons Flutter 3.32+

Flutter 3.32 a déprécié `Radio.groupValue` et `Radio.onChanged` au profit de `RadioGroup<T>`.
La nouvelle API :

```dart
RadioGroup<IncomeSource>(
  groupValue: selected,
  onChanged: (v) { if (v != null) onChanged(v); },
  child: Column(
    children: IncomeSource.values.map((s) =>
      Row(
        children: [
          Radio<IncomeSource>(value: s), // hérite du RadioGroup
          Text(s.displayName),
        ],
      )
    ).toList(),
  ),
)
```

Le `RadioGroup` est un `InheritedWidget` : tous les `Radio<T>` descendants
héritent automatiquement de `groupValue` et notifient `onChanged`.
