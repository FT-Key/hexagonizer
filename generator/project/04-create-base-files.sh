#!/bin/bash
# hexagonizer/project/03-create-base-files.sh

files=(.gitignore .gitattributes .prettierrc README.md)
for f in "${files[@]}"; do
  if [ -e "$f" ]; then
    echo "⚠️ $f ya existe, no se sobrescribe."
  else
    touch "$f"
    echo "✅ $f creado."
  fi
done

# Para package-lock.json que debe tener contenido
if [ -e "package-lock.json" ]; then
  echo "⚠️ package-lock.json ya existe, no se sobrescribe."
else
  echo "{}" >package-lock.json
  echo "✅ package-lock.json creado con contenido base."
fi
