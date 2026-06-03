# Face Recognition

Sistema de Reconhecimento de Rostos usando IA.

## Como rodar

### Pré-requisitos

- [Bun](https://bun.sh) instalado
- Postgres com extensão PGVector

### Instalação

```bash
bun install
```

### Desenvolvimento

```bash
bun run dev
```

Acesse http://localhost:3000

### Produção

```bash
bun run build
bun run start
```

## Variáveis de Ambiente

Veja [`docs/variaveis-ambiente.md`](./docs/variaveis-ambiente.md).

## Tecnologias

- Bun + TypeScript
- Next.js + TailwindCSS + DaisyUI
- ElysiaJS (API)
- Postgres + PGVector

## Licença

MIT
