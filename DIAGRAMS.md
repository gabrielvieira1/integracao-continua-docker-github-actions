# 📊 Visualização dos Diagramas

## Como Visualizar os Diagramas Mermaid

Os diagramas neste projeto usam **Mermaid**, que é suportado nativamente pelo GitHub. Aqui estão as formas de visualizá-los:

### 🌐 **No GitHub (Recomendado)**
1. Acesse o arquivo [ARCHITECTURE.md](./ARCHITECTURE.md) diretamente no GitHub
2. Os diagramas serão renderizados automaticamente
3. Use o modo claro/escuro para melhor visualização

### 💻 **No VS Code**
1. Instale a extensão "Mermaid Preview"
2. Abra o arquivo `ARCHITECTURE.md`
3. Use `Ctrl+Shift+P` → "Mermaid: Preview"

### 🔗 **Online**
1. Copie o código Mermaid
2. Cole em [mermaid.live](https://mermaid.live/)
3. Exporte como PNG/SVG se necessário

### 📱 **Em Outros Editores**
- **Obsidian**: Suporte nativo
- **Notion**: Use blocos de código mermaid
- **GitLab**: Suporte nativo
- **Confluence**: Plugin Mermaid

## 🎨 Diagrama Simples do Fluxo

Para uma visão rápida, aqui está o fluxo simplificado:

```
┌─────────────┐    ┌──────────┐    ┌───────────┐    ┌─────────────┐
│  git push   │───▶│  GitHub  │───▶│   CI/CD   │───▶│ Docker Hub  │
│             │    │ Actions  │    │ Pipeline  │    │   Registry  │
└─────────────┘    └──────────┘    └───────────┘    └─────────────┘
                        │               │                    │
                        ▼               ▼                    ▼
                   ┌──────────┐    ┌───────────┐    ┌─────────────┐
                   │ Secrets  │    │   Tests   │    │ Production  │
                   │   🔐     │    │    🧪     │    │ Environment │
                   └──────────┘    └───────────┘    └─────────────┘
```

## 📋 Legenda dos Símbolos

| Símbolo | Significado |
|---------|-------------|
| 👨‍💻 | Desenvolvedor |
| 🧪 | Testes |
| 🔨 | Build/Compilação |
| 🐳 | Docker/Container |
| 📦 | Artefato/Package |
| 🔐 | Secrets/Segurança |
| 🚀 | Deploy/Produção |
| ⚡ | GitHub Actions |
| 🐘 | PostgreSQL |
| 🔍 | Linting |
| 📊 | Monitoramento |
| ☁️ | Cloud/Nuvem |

## 🖼️ Screenshots dos Diagramas

*Os diagramas completos estão disponíveis em [ARCHITECTURE.md](./ARCHITECTURE.md)*

---

**💡 Dica**: Para a melhor experiência, visualize os diagramas diretamente no GitHub ou use o Mermaid Live Editor!
