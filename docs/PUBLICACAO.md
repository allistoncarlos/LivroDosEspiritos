# Publicação no TestFlight

Segue o processo padrão da skill `publicar-testflight`, com uma diferença: depois do
`xcodebuild archive` (passo 4), antes ou depois do `-exportArchive`, suba os dSYMs pro Sentry.

## Por quê

O SDK do Sentry (`sentry-cocoa`) foi integrado sem build phase de upload de dSYM: numa
build phase dentro do target, o script roda antes do Xcode gerar o dSYM (`GenerateDSYMFile`),
mesmo desabilitando "Based on dependency analysis" — problema conhecido do build system novo
do Xcode. A forma confiável é rodar o upload como um passo separado, depois que o archive já
terminou (nesse ponto o `.xcarchive/dSYMs/` já tem os arquivos corretos e completos).

## Passo extra

Depois do `xcodebuild archive ... -archivePath <path>.xcarchive`:

```bash
sentry-cli debug-files upload --include-sources "<path>.xcarchive/dSYMs"
```

Requer `sentry-cli` instalado (`brew install getsentry/tools/sentry-cli`) e um
`.sentryclirc` na raiz do repo (gitignored) com um auth token da org `alliston`
(Settings → Auth Tokens, escopo `org:ci`):

```ini
[auth]
token=sntrys_...

[defaults]
org=alliston
project=livro-dos-espiritos
```

Sem esse arquivo, o comando falha silenciosamente em autenticar. Confirme o upload em
https://alliston.sentry.io/settings/projects/livro-dos-espiritos/debug-symbols/.
