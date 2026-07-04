# Renombrar la carpeta de un repo Git rompe sus worktrees vinculados (gitdir apunta a ruta vieja)

> Auto-generated from learning proposal PROP-1783194781491-6f9eea

## Context
Dev multi-worktree del ecosistema PS tras renombrar el repo principal (bonita-ai-agent-mcp -> ofelia-ai-agent-mcp)

## Description
Cuando se renombra o mueve la CARPETA del repo principal que tiene git worktrees vinculados (git worktree add), los worktrees dejan de funcionar: cada worktree guarda un fichero '.git' de texto con 'gitdir: <ruta-absoluta>/.git/worktrees/<nombre>' apuntando a la ruta ANTIGUA. Al desaparecer esa ruta, cualquier comando git en el worktree falla con 'fatal: not a git repository: (NULL)' y parece que se ha perdido todo. En realidad no se pierde nada: los objetos y refs siguen en el repo renombrado, solo el puntero está obsoleto. Muy confuso porque el worktree tiene todos los ficheros en disco intactos.

## Problem
Tras renombrar el repo principal, 4 worktrees hermanos daban 'fatal: not a git repository (NULL)' y parecían huérfanos/perdidos, bloqueando todo el trabajo git (status, commit, push).

## Solution
Reparar cada worktree reescribiendo su fichero '.git' para apuntar a la ruta nueva: printf 'gitdir: <NUEVA_RUTA>/.git/worktrees/<nombre>\n' > <worktree>/.git . El fichero inverso del padre (.git/worktrees/<nombre>/gitdir) suele seguir correcto si solo cambió el nombre del repo, no el de los worktrees. Verificar con 'git -C <worktree> status -sb'. Antes de cualquier reset/reclone destructivo, confirmar que las ramas están pusheadas (git log <branch> --not --remotes y git ls-remote) para no perder commits. Regla: al renombrar/mover un repo con worktrees, arreglar los punteros gitdir de todos los worktrees (o recrearlos).

## Action Items
- [ ] Documentar en claude-code-toolkit el gotcha: renombrar/mover un repo con worktrees rompe los punteros gitdir de los worktrees vinculados
- [ ] Aportar snippet de reparacion: reescribir <worktree>/.git con la ruta nueva; verificar con git -C <worktree> status
- [ ] Recordatorio de seguridad: antes de reset --hard/reclone, verificar ramas pusheadas con 'git log <branch> --not --remotes' y 'git ls-remote'

## References
- Proposal: PROP-1783194781491-6f9eea
- Category: pattern
- Priority: medium
