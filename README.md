# Livro dos Espíritos — iOS

App iOS em SwiftUI com as **1019 perguntas** do *Livro dos Espíritos* (tradução Guillon Ribeiro), extraídas das páginas 55–460 do PDF.

## Funcionalidades

- Navegação por **Partes** → **Capítulos** → **Seções** → **Perguntas**
- Detalhe de cada pergunta com resposta dos Espíritos, comentário de Kardec e notas/adendos
- **Busca** por palavra-chave, número, tema, resposta ou comentário
- **Pergunta do dia** — notificação local às 19:30 com pergunta aleatória, sem repetir até completar as 1019

## Como abrir

1. Abra `LivroDosEspiritos.xcodeproj` no Xcode
2. Selecione um simulador ou dispositivo iOS 17+
3. Execute com ⌘R

## Estrutura

- `LivroDosEspiritos/` — código SwiftUI do app
- `LivroDosEspiritos/Resources/questions.json` — dados das 1019 perguntas

## Sentry Session Replay

### Install

Make sure your Sentry Cocoa SDK version is at least 8.43.0. If you already have the SDK installed, you can update it to the latest version with:

```swift
.package(url: "https://github.com/getsentry/sentry-cocoa", from: "9.34.0"),
```

To set up the integration, add the following to your Sentry initialization:

```swift
SentrySDK.start(configureOptions: { options in
    options.dsn = "https://a2a799dae1e645132fe3b444011c6535@o4512157514924032.ingest.us.sentry.io/4512157542514688"
    options.debug = true

    options.sessionReplay.onErrorSampleRate = 1.0
    options.sessionReplay.sessionSampleRate = 0.1
})
```

### Configure SDK

The SDK aggressively redacts all text and images by default. You can easily configure the unmasking or masking behavior. Learn more about configuring Session Replay by reading the [configuration docs](https://docs.sentry.io/platforms/apple/guides/ios/session-replay/#privacy).

The following code is the default configuration, which masks and blocks everything.

```swift
options.sessionReplay.maskAllText = true
options.sessionReplay.maskAllImages = true
```

### Verify

While you're testing, we recommend that you set `options.sessionReplay.sessionSampleRate` to `1.0`. This ensures that every user session will be sent to Sentry.

Once testing is complete, we recommend lowering this value in production. We still recommend keeping `options.sessionReplay.onErrorSampleRate` set to `1.0`.
