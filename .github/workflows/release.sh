#!/usr/bin/env bash

set -euo pipefail

# =========================
# Verifica mudança de versão
# =========================
echo "Verificando mudança de versão..."

NEW_VERSION=$(jq -r '.version // empty' package.json)

if [ -z "$NEW_VERSION" ]; then
    echo "Nenhuma versão encontrada em package.json"
    exit 0
fi

OLD_VERSION=$(
    git show HEAD~1:package.json 2>/dev/null \
    | jq -r '.version // empty' 2>/dev/null \
    || echo ""
)

if [ "$NEW_VERSION" = "$OLD_VERSION" ]; then
    echo "A Versão não mudou ($NEW_VERSION)"
    exit 0
fi

echo "Nova versão detectada: $NEW_VERSION"

# =========================
# Obtém tag anterior
# =========================

PREV_TAG=$(git tag --sort=-version:refname | head -1)

echo "Tag anterior: ${PREV_TAG:-<nenhuma>}"

# =========================
# Monta contexto para IA
# =========================
echo "Montando contexto para geração de release notes..."
VERSION="$NEW_VERSION"

{
    echo "Versão: v${VERSION}"
    echo

    echo "=== COMMITS ==="

    if [ -z "$PREV_TAG" ]; then
        git log --format="- %s (%h by %an)"
    else
        git log "${PREV_TAG}..HEAD" --format="- %s (%h by %an)"
    fi

    echo
    echo "=== DIFF (sem arquivos de lock e node_modules) ==="

    if [ -z "$PREV_TAG" ]; then
        git diff HEAD~5..HEAD -- . ':!bun.lock' ':!node_modules' 2>/dev/null | head -c 40000
    else
        git diff "${PREV_TAG}..HEAD" -- . ':!bun.lock' ':!node_modules' 2>/dev/null | head -c 40000
    fi
} > /tmp/changes.txt
echo "Contexto montado em /tmp/changes.txt"

# =========================
# Instala OpenCode
# =========================
echo "Instalando OpenCode CLI..."

npm install -g opencode-ai@1.15.13

echo "OpenCode CLI instalado: $(opencode --version)"

# =========================
# Gera release notes
# =========================
echo "Gerando release notes com IA..."

cat > /tmp/prompt.txt << 'EOF'
Você é um assistente especializado em criar release notes de software.

Analise os commits e o diff abaixo e gere release notes em português para a versão indicada.

Organize em categorias com emojis:
- 🚀 Novidades
- 🐛 Correções
- ⚡ Melhorias
- 🔧 Mudanças internas

Use markdown com listas.

Seja informativo e conciso.

Ignore menções a bun.lock e node_modules.

EOF

cat /tmp/changes.txt >> /tmp/prompt.txt

GENERATED=$(opencode run --model openrouter/openrouter/auto "$(cat /tmp/prompt.txt)" 2>/dev/null || true)

echo "Release notes geradas (ou fallback):"
echo "$GENERATED"

if [ -z "$GENERATED" ]; then
    echo "Nenhuma release note gerada, usando fallback."
    GENERATED="Release automático - veja os commits para detalhes."
fi

echo "$GENERATED" > /tmp/release_notes.md

# =========================
# Cria tag caso não exista
# =========================

echo "Criando tag ${VERSION} se não existir..."

TAG="v${VERSION}"

if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    git tag "$TAG"
    git push origin "$TAG"
fi

# =========================
# Obtém owner/repo
# =========================
echo "Obtendo informações do repositório..."

REMOTE_URL=$(git remote get-url origin)

if [[ "$REMOTE_URL" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
else
    echo "Não foi possível identificar owner/repo"
    exit 1
fi

# =========================
# Cria Release no GitHub
# =========================
echo "Criando release ${TAG} no GitHub..."

curl \
    -sS \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${OWNER}/${REPO}/releases" \
    -d @- <<EOF
{
  "tag_name": "${TAG}",
  "name": "${TAG}",
  "body": $(jq -Rs . < /tmp/release_notes.md),
  "make_latest": "true"
}
EOF

echo "Release ${TAG} criada com sucesso. No GitHub."

# =========================
# Publica imagem Docker no GitHub Container Registry
# =========================

REPO_NAME="${FULL_REPO##*/}"
REPO_OWNER="${FULL_REPO%%/*}"
REGISTRY="ghcr.io"
IMAGE_NAME="${REPO_NAME}"
IMAGE_URL="${REGISTRY}/${REPO_OWNER}/${IMAGE_NAME}"
LATEST_TAG="${IMAGE_URL}:latest"
MINOR_VERSION=$(echo "$VERSION" | cut -d. -f1-2)
MINOR_TAG="${IMAGE_URL}:${MINOR_VERSION}"
MAJOR_VERSION=$(echo "$VERSION" | cut -d. -f1)
MAJOR_TAG="${IMAGE_URL}:${MAJOR_VERSION}"
VERSION_TAG="${IMAGE_URL}:${VERSION}"

echo "Logando no Github Container Registry..."

echo "${GITHUB_TOKEN}" | docker login ${REGISTRY} -u "${REPO_OWNER}" --password-stdin
echo "Publicando imagem Docker com tag ${VERSION}..."

docker build -t "${VERSION_TAG}" .
docker tag "${VERSION_TAG}" "${LATEST_TAG}"
docker tag "${VERSION_TAG}" "${MINOR_TAG}"
docker tag "${VERSION_TAG}" "${MAJOR_TAG}"
docker push "${VERSION_TAG}"
docker push "${LATEST_TAG}"
docker push "${MINOR_TAG}"
docker push "${MAJOR_TAG}"
echo "Imagem Docker publicada com tags: ${VERSION_TAG}, ${LATEST_TAG}, ${MINOR_TAG}, ${MAJOR_TAG}"

# =========================
# Despacha Coolify
# =========================

echo "Despachando Coolify"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
-X POST "${ COOLIFY_WEBHOOK_URL }" \
-H "Authorization: Bearer ${COOLIFY_TOKEN }")

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Coolify despachado com sucesso."
else
    echo "Falha ao despachar Coolify. Status HTTP: $HTTP_STATUS"
fi