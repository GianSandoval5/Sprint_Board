# SprintBoard

SprintBoard is a Flutter mobile copilot for hackathon teams using Backboard as the orchestration layer. It turns one messy sprint into five coordinated lanes: `Idea`, `Frontend`, `Backend`, `README`, and `Demo`.

The app is built to show a real Backboard integration, not a thin chat wrapper:

- One assistant powers the whole project.
- Five persistent threads split the work by lane.
- Shared memory keeps decisions consistent across those threads.
- Assistant-level document uploads provide RAG over briefs, specs, and notes.
- Custom tool calls generate task boards, rubric scoring, README drafts, and demo scripts.
- Hive stores the local workspace so the app can resume quickly.

## Author

- Gian Sandoval
- LinkedIn: https://www.linkedin.com/in/giansandoval
- GitHub: https://github.com/GianSandoval5

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

## Why this project fits the hackathon

Backboard is strongest when you actually demonstrate state, memory, documents, and tools together. SprintBoard is designed around exactly that workflow:

1. Upload the challenge brief or product docs.
2. Ask the assistant to choose the strongest concept.
3. Switch to another lane and prove the memory survives the transition.
4. Use a tool call to turn that context into deliverables or a polished README.
5. Finish by generating the demo script from the same shared project state.

## Product flow

### 1. Bootstrap

The app creates:

- One Backboard assistant with SprintBoard-specific instructions.
- Five threads, one per lane.
- A local Hive workspace containing the API key, runtime preferences, assistant id, and thread ids.

### 2. Operate by lane

Each lane has its own conversation history:

- `Idea`: scope, concept, category fit, prize angle.
- `Frontend`: UX flow, screen plan, visual polish.
- `Backend`: architecture, integration decisions, delivery risks.
- `README`: narrative, architecture summary, setup copy.
- `Demo`: show order, pacing, closing line.

### 3. Add context

Documents are uploaded to the assistant, so they become shared context across all five threads.

### 4. Execute with tools

The assistant can request these local functions:

- `create_task_board`
- `score_against_rubric`
- `generate_readme`
- `build_demo_script`

The Flutter app resolves those tool calls locally and submits the outputs back to Backboard until the run completes.

## Architecture

The codebase follows a clean, feature-driven split:

```text
lib/
  main.dart
  src/
    app.dart
    core/
      config/
      constants/
      errors/
      theme/
    features/
      board/
        data/
          datasources/
          repositories/
          services/
        domain/
          entities/
          repositories/
        presentation/
          controllers/
          pages/
```

### Layers

- `domain`: entities and repository contracts.
- `data`: Backboard HTTP client, Hive persistence, tool-call toolkit, repository implementation.
- `presentation`: Riverpod state controller plus responsive Flutter UI.

## Tech stack

- Flutter
- Riverpod
- Hive / Hive Flutter
- HTTP
- File Picker
- Google Fonts
- Backboard API

## Backboard mapping

SprintBoard is aligned to the Backboard model described in the official docs:

- `POST /assistants`
- `POST /assistants/{assistant_id}/threads`
- `POST /threads/{thread_id}/messages`
- `POST /threads/{thread_id}/runs/{run_id}/submit-tool-outputs`
- assistant document uploads and document status polling
- memory modes and optional web search per message

Relevant docs:

- Quickstart: https://docs.backboard.io/quickstart
- Assistants: https://docs.backboard.io/concepts/assistants
- Messages: https://docs.backboard.io/concepts/messages
- Tool calls: https://docs.backboard.io/sdk/tool-calls
- Documents: https://docs.backboard.io/sdk/documents
- Authentication and key handling: https://docs.backboard.io/authentication

## Security note

Backboard's authentication guide explicitly says API keys should not be exposed in client-side or mobile apps. This repo therefore does **not** hardcode any key.

Current behavior:

- The key can be injected with `--dart-define=BACKBOARD_API_KEY=...`
- Or typed into the app during local demo setup
- The value is stored only in local Hive storage on the current device

For a public production deployment, move the remote datasource behind your own backend or edge function and keep the Backboard key server-side.

## Running locally

### Prerequisites

- Flutter SDK installed
- A valid Backboard API key

### Install dependencies

```bash
flutter pub get
```

### Run with a preloaded key

```bash
flutter run --dart-define=BACKBOARD_API_KEY=YOUR_BACKBOARD_KEY
```

### Or run without injecting the key

```bash
flutter run
```

Then paste the key into the bootstrap screen.

## Demo script suggestion

Use this order for a 2-3 minute hackathon demo:

1. Bootstrap the workspace.
2. Upload the challenge brief.
3. In `Idea`, ask for the best project direction.
4. Switch to `README` or `Demo` and prove the assistant remembers the same concept.
5. Trigger a tool-backed request like README generation or rubric scoring.
6. End on the polished board and the generated project story.

## What is persisted locally

Hive stores:

- Backboard API key
- assistant id
- selected lane
- memory mode
- web search toggle
- provider + model
- thread ids by lane

Backboard remains the source of truth for:

- thread history
- shared memory
- uploaded documents
- tool-call lifecycle

## Android permissions

The Android manifest includes the minimum permission required by this app:

- `android.permission.INTERNET` for Backboard API requests and document upload.

The file picker relies on the system document picker, so no broad storage permission was added.

## Validation targets

The intended verification path for this repo is:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Next improvements

- Add a secure proxy/backend for production key handling.
- Add document deletion and thread cleanup actions.
- Add streaming responses instead of the current non-streaming loop.
- Add richer analytics around retrieved memories/files and context usage.
