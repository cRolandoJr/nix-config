# Proceso correcto para conectar

## 1. Ver que aparezca
```bash
lsblk
```

## 2. Re-montar (los directorios /mnt/old-home y /mnt/old-root siguen ahí, no hace falta recrearlos)
```bash
sudo mount -o ro /dev/sda4 /mnt/old-home
sudo mount -o ro /dev/sda3 /mnt/old-root
```

## 3. Verificar
```bash
findmnt /mnt/old-home
```

Detalle importante: la letra sda puede cambiar a sdb u otra cuando lo reconectás (depende del orden en que el kernel detecta dispositivos USB). Por eso siempre lsblk primero antes de mountear. Si querés montaje robusto independiente de la letra, usás el UUID:

# Ver UUIDs
```bash
sudo blkid /dev/sd*
```
# Mount por UUID (ejemplo)
```bash
sudo mount -o ro UUID=XXXX-YYYY /mnt/old-home
```

# Flujo para copiar archivos

# verificaf que esta montado
```bash
mount | grep old-home
ls /mnt/old-home/Rolando/  # debería listar carpetas
```
## 1) explorar antes de copiar

 Tamaño de una carpeta
```bash
sudo du -sh /mnt/old-home/Rolando/CARPETA/
```

 Ver contenido (incluyendo ocultos)
```bash
ls -la /mnt/old-home/Rolando/CARPETA/
```

 Estructura hasta 2 niveles
```bash
tree -L 2 /mnt/old-home/Rolando/CARPETA/
```

 Tamaño desglosado para decidir qué excluir
```bash
sudo du -sh /mnt/old-home/Rolando/CARPETA/*  | sort -h
```
## 2) Copia básica con rsync (recomendado)

```bash
rsync -ah --info=progress2 ORIGEN DESTINO
```

Flags:

-a (archive): mantiene permisos, timestamps, dueños, symlinks
-h (human): muestra tamaños legibles
--info=progress2: progress bar total

ORIGEN/ con barra → copia el contenido dentro de DESTINO
ORIGEN sin barra → copia la carpeta entera dentro de DESTINO

# Ejemplo
```
# Copiar el contenido de Wallpapers/ a ~/Wallpapers/ (los archivos sueltos quedan en ~/Wallpapers/)
rsync -ah --info=progress2 /mnt/old-home/Rolando/Wallpapers/ ~/Wallpapers/

# Copiar la carpeta entera (queda ~/Wallpapers/Wallpapers/)
rsync -ah --info=progress2 /mnt/old-home/Rolando/Wallpapers ~/
```

# IMPORTANTE

## 3) copia con excludes (proyectos grandes)

```bash
rsync -ah --info=progress2 \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='build' \
  --exclude='dist' \
  --exclude='target' \
  --exclude='vendor' \
  --exclude='.gradle' \
  --exclude='.dart_tool' \
  --exclude='ios/Pods' \
  --exclude='.cache' \
  ORIGEN/ DESTINO/
```
## 4) para archivos sueltos: cp

```bash
cp /mnt/old-home/Rolando/algo.md ~/
cp -rp /mnt/old-home/Rolando/.config/algo ~/.config/   # -r recursivo, -p preserva permisos
```

## 5) Para keys y configs sensibles
SSH, GPG, etc. necesitan permisos correctos después de copiar:

```bash
# SSH
cp -rp /mnt/old-home/Rolando/.ssh ~/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/config 2>/dev/null
chmod 644 ~/.ssh/*.pub ~/.ssh/known_hosts 2>/dev/null
```
```bash
# GPG
cp -rp /mnt/old-home/Rolando/.gnupg ~/
chmod 700 ~/.gnupg
find ~/.gnupg -type f -exec chmod 600 {} \;
find ~/.gnupg -type d -exec chmod 700 {} \;
```

## 6) Verificar despues de copiar

```bash
# Tamaño del destino
du -sh ~/CARPETA_NUEVA/
```
```bash
# Comparar contenido (sin transferir, solo dry-run)
rsync -ahn --delete /mnt/old-home/Rolando/CARPETA/ ~/CARPETA_NUEVA/
``` 
El -n (dry-run) te muestra qué transferiría sin hacerlo. Si dice "nothing to do", la copia está completa.

Tips útiles

No necesitás sudo para copiar a tu home (sí para crear directorios en /etc, /var, etc.)
Si una copia se corta, volvés a tirar el mismo rsync — es resumable, no re-transfiere lo ya copiado
Permisos de carpetas creadas con sudo en /mnt/...: nada raro, leéis con tu user sin sudo porque está montado read-only mostly readable
Para mover en lugar de copiar: mv ORIGEN DESTINO (pero solo si el destino y origen están en el mismo filesystem; en diferentes discos, mv internamente hace cp+rm). En tu caso, mejor siempre rsync/cp del USB al SSD, nunca mv, porque si se corta perdés datos del origen sin garantía de que estén bien en el destino.
Si querés que los archivos en destino sean tuyos (no del UID viejo de Arch): rsync los copia con el dueño actual del proceso (vos). cp -rp también. No necesitas chown adicional.


# Proceso correcto para desconectar

## 1. Salí de cualquier shell que tenga el cwd ahí (importante)
cd ~

## 2. Desmontar las dos particiones que montamos
sudo umount /mnt/old-home
sudo umount /mnt/old-root

## 3. Verificar que se desmontaron
mount | grep old-

## Si no devuelve nada → desmontados ✅

## 4. Opcional pero limpio: power-off el USB
udisksctl power-off -b /dev/sda
