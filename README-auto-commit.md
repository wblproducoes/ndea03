# Comandos de Commit Automático (comprot)

## Script
- Local: `scripts/comprot.ps1`
- Plataforma: Windows/PowerShell

## Uso Básico
- Commit único:
  - `powershell -ExecutionPolicy Bypass -File scripts/comprot.ps1 -Message "progresso"`
- Loop automático a cada 2 minutos:
  - `powershell -ExecutionPolicy Bypass -File scripts/comprot.ps1 -Watch -IntervalMinutes 2`

## Inicializar Repositório e Usuário Local
- `powershell -ExecutionPolicy Bypass -File scripts/comprot.ps1 -Init -SetLocalUser -UserName "Auto Commit Bot" -UserEmail "bot@example.com"`

## Boas Práticas
- Mantenha `.env` e `node_modules/` fora dos commits (`.gitignore` já configurado).
- Não inclua segredos/credenciais em commit messages.

## Observações
- O script não faz `git push`; foque em commits locais. Configure remoto e push conforme sua necessidade.
- Mensagens são geradas automaticamente com timestamp quando `-Message` não é informado.
