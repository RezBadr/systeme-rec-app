# anime_recommendation_app

Projet : BADR REZOUKI, MAHMUTOVIC Elma, PELLARD Téa, JUANOLA Lily-Fleur

Frontend Flutter application for an anime recommendation service.

## Features

- **Login screen** (email/password authentication)
- **First-time onboarding**: user selects preferred genres via a form
- **Home screen** with tabs:
  - Recommandations par contenu
  - Recommandations par collaboration
  - Liste générale des animés
- **Anime detail page** with:
  - Description, image, genres
  - Average rating + rating submission
  - User comments + comment submission
- Communicates with a **Hono (TypeScript) backend** via REST APIs

## Running the app

1. Install dependencies:

```bash
flutter pub get
```

2. Run on a device or emulator:

```bash
flutter run
```

### Configurer l'URL du backend

Par défaut, l'app pointe vers `http://localhost:3000`. Si votre backend tourne sur une autre URL, lancez l'appli avec la variable d'environnement `API_BASE_URL` :

```bash
flutter run --dart-define=API_BASE_URL=https://api.mon-backend.com
```

## API endpoints attendus

L'application s'attend à ce que le backend expose des routes similaires à :

- `POST /auth/login` → `{ token, preferencesComplete }`
- `POST /user/preferences` (auth) → `{}`
- `GET /recommendations/content` (auth) → `{ items: [...] }`
- `GET /recommendations/collaboration` (auth) → `{ items: [...] }`
- `GET /anime` (auth) → `{ items: [...] }`
- `GET /anime/{id}` (auth) → `{ ...anime }`
- `GET /anime/{id}/comments` (auth) → `{ items: [...] }`
- `POST /anime/{id}/comments` (auth) → `{}`
- `POST /anime/{id}/rating` (auth) → `{}`

## Notes

- Le token d'authentification est stocké localement via `shared_preferences`.
- Le formulaire de préférences est requis uniquement lors du premier lancement après l'inscription.
