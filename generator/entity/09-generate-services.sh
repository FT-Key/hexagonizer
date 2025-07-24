#!/bin/bash
# shellcheck disable=SC2154
# 3.5. SERVICES

services_path="src/application/$entity/services"
readme_file="$services_path/README.md"
service_file="$services_path/get-active-${entity}.js"

# Crear carpeta de servicios con README
if [[ -d "$services_path" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  La carpeta $services_path ya existe. ¿Deseas sobrescribir el README? [y/n]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "// Servicios para la entidad $EntityPascal" >"$readme_file"
    echo "📄 README.md actualizado."
  else
    echo "⏭️  README no modificado."
  fi
else
  mkdir -p "$services_path"
  echo "// Servicios para la entidad $EntityPascal" >"$readme_file"
  echo "📁 Carpeta y README creados: $services_path"
fi

# Archivo del servicio getActive
if [[ -f "$service_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $service_file ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Servicio omitido: $service_file"
    exit 0
  fi
fi

# Escribir servicio
cat <<EOF >"$service_file"
export async function getActive${EntityPascal}s(repository) {
  const all = await repository.findAll();
  return all.filter(item => item.active);
}
EOF

echo "✅ Servicio generado: $service_file"
