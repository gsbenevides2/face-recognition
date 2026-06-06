#!/bin/bash

cat > /tmp/prompt.txt << 'PROMPT_EOF'
          Você é um assistente especializado em criar release notes de software. Analise os commits e o diff abaixo e gere release notes em português para a versão indicada. Organize em categorias com emojis (ex: 🚀 Novidades, 🐛 Correções, ⚡ Melhorias, 🔧 Mudanças internas). Use markdown com listas. Seja informativo e conciso. Ignore menções a bun.lock e node_modules.

          PROMPT_EOF

          cat /tmp/changes.txt >> /tmp/prompt.txt

          GENERATED=$(cat /tmp/prompt.txt | claude -p 2>/dev/null) || GENERATED=""

          if [ -z "$GENERATED" ]; then
            GENERATED="Release automático - veja os commits para detalhes."
          fi

          {
            echo "body<<NOTES_DELIM"
            echo "$GENERATED"
            echo "NOTES_DELIM"
          } >> "$GITHUB_OUTPUT"
