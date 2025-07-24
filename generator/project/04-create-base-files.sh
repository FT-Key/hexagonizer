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
