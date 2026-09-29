# Git: separar identidad personal vs. trabajo

> Actualizado 2026-07-20. Tu setup **ya automatiza** la identidad por ubicación —
> lo que antes hacías a mano (`git config user.email` por repo) ahora es automático
> si clonás los repos de trabajo bajo `~/work/`.

## Cómo funciona hoy (2 piezas ya configuradas)

**1. SSH — alias `github-work`** (`~/.ssh/config`): usa tu clave de trabajo
(`id_ed25519_work`) en vez de la personal. Ya está puesto.

**2. Identidad automática por carpeta** (`~/projects/nix-config/home/rolando.nix`,
`programs.git`): un `includeIf "gitdir:~/work/**"` aplica `~/work/.gitconfig-empresa`
(name=Rolando, email=<mail-trabajo>) a **cualquier repo bajo `~/work/`**.
Fuera de `~/work/` usás tu identidad personal global. **No hay que tocar nada por repo.**

## El único flujo que tenés que recordar

**Repo personal** — como siempre:
```bash
git clone git@github.com:cRolandoJr/repo.git      # en ~/projects/ o donde sea
```

**Repo de trabajo** — dos condiciones: alias `github-work` + clonar dentro de `~/work/`:
```bash
cd ~/work
git clone git@github-work:Empresa/proyecto.git    # ⚠️ github-work, no github.com
```
Listo. El email corporativo se aplica solo por estar bajo `~/work/`.

## Verificar que quedó bien (1 comando)

Dentro del repo recién clonado:
```bash
git config user.email        # debe dar <mail-trabajo> en ~/work/**
                             # y tu email personal fuera de ahí
```

## Si un repo de trabajo quedó fuera de `~/work/`

Ahí el includeIf no aplica y tenés que setear la identidad a mano (el flujo viejo):
```bash
git config user.email "<mail-trabajo>"
```
Mejor movelo a `~/work/` y evitás el paso manual.
