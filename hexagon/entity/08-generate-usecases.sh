#!/bin/bash
# shellcheck disable=SC2154

# Función para pluralizar de forma simple (puede mejorarse)
pluralize() {
  local word="$1"
  if [[ "$word" == *s ]]; then
    echo "${word}es"
  else
    echo "${word}s"
  fi
}

# Función para generar casos de uso
generate_use_case() {
  local action=$1
  local file_path="src/application/$entity/use-cases/${action}-${entity}.js"
  mkdir -p "$(dirname "$file_path")"

  if [[ -f "$file_path" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "⚠️  El archivo $file_path ya existe. ¿Deseas sobrescribirlo? []: " confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
      echo "⏭️  Omitido: $file_path"
      return
    fi
  fi

  if [[ "$action" == "create" ]]; then
    {
      echo "import { ${EntityPascal}Factory } from '../../../domain/$entity/${entity}-factory.js';"
      echo "import crypto from 'crypto';"
      echo ""
      echo "export class Create${EntityPascal} {"
      echo "  constructor(repository) {"
      echo "    this.repository = repository;"
      echo "  }"
      echo ""
      echo "  async execute(data) {"
      if $has_json; then
        echo "    const entity = ${EntityPascal}Factory.create({"
        echo "      ...data,"
        echo "      id: crypto.randomUUID(),"
        echo "    });"
        echo "    return this.repository.save(entity);"
      else
        echo "    // TODO: completar lógica con atributos personalizados"
        echo "    const entity = { id: crypto.randomUUID(), ...data };"
        echo "    return this.repository.save(entity);"
      fi
      echo "  }"
      echo "}"
    } >"$file_path"

  elif [[ "$action" == "update" ]]; then
    {
      echo "import { ${EntityPascal}Factory } from '../../../domain/$entity/${entity}-factory.js';"
      echo ""
      echo "export class Update${EntityPascal} {"
      echo "  constructor(repository) {"
      echo "    this.repository = repository;"
      echo "  }"
      echo ""
      echo "  async execute(id, data) {"
      echo "    if (!id) throw new Error('${EntityPascal} id is required');"
      echo "    const existing = await this.repository.findById(id);"
      echo "    if (!existing) throw new Error('${EntityPascal} not found');"
      if $has_json; then
        echo "    const updated = ${EntityPascal}Factory.create({"
        echo "      ...existing,"
        echo "      ...data,"
        echo "      id: existing.id,"
        echo "    });"
        echo "    return this.repository.save(updated);"
      else
        echo "    const updated = { ...existing, ...data };"
        echo "    return this.repository.save(updated);"
      fi
      echo "  }"
      echo "}"
    } >"$file_path"

  elif [[ "$action" == "get" ]]; then
    {
      echo "export class Get${EntityPascal} {"
      echo "  constructor(repository) {"
      echo "    this.repository = repository;"
      echo "  }"
      echo ""
      echo "  async execute(id) {"
      echo "    if (!id) throw new Error('${EntityPascal} id is required');"
      echo "    return this.repository.findById(id);"
      echo "  }"
      echo "}"
    } >"$file_path"

  elif [[ "$action" == "delete" ]]; then
    {
      echo "export class Delete${EntityPascal} {"
      echo "  constructor(repository) {"
      echo "    this.repository = repository;"
      echo "  }"
      echo ""
      echo "  async execute(id) {"
      echo "    if (!id) throw new Error('${EntityPascal} id is required');"
      echo "    return this.repository.deleteById(id);"
      echo "  }"
      echo "}"
    } >"$file_path"

  elif [[ "$action" == "deactivate" ]]; then
    {
      echo "export class Deactivate${EntityPascal} {"
      echo "  constructor(repository) {"
      echo "    this.repository = repository;"
      echo "  }"
      echo ""
      echo "  async execute(id) {"
      echo "    if (!id) throw new Error('${EntityPascal} id is required');"
      echo "    return this.repository.deactivateById(id);"
      echo "  }"
      echo "}"
    } >"$file_path"

  elif [[ "$action" == "list" ]]; then
    local plural_pascal
    plural_pascal="$(pluralize "$EntityPascal")"
    {
      echo "export class List${plural_pascal} {"
      echo "  constructor(repository) {"
      echo "    this.repository = repository;"
      echo "  }"
      echo ""
      echo "  /**"
      echo "   * @param {Object} options"
      echo "   * @param {Object} options.filters"
      echo "   * @param {string} options.search"
      echo "   * @param {Object} options.pagination"
      echo "   * @param {Object} options.sort"
      echo "   * @returns {Promise<${EntityPascal}[]>}"
      echo "   */"
      echo "  async execute({ filters, search, pagination, sort }) {"
      echo "    return this.repository.findAll({ filters, search, pagination, sort });"
      echo "  }"
      echo "}"
    } >"$file_path"
  fi
}

# 3. USE CASES
for action in create get update delete deactivate list; do
  usecase_file="src/application/$entity/use-cases/${action}-${entity}.js"
  if [[ -f "$usecase_file" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "⚠️  Ya existe $usecase_file. ¿Sobrescribir? [y/n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "⏭️  Omitido: $usecase_file"
      continue
    fi
  fi
  generate_use_case "$action"
done

echo "✅ Casos de uso generados."
