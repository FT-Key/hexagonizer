#!/bin/bash
# generator/entity/14-generate-tests.sh
# shellcheck disable=SC2154,SC2086
set -e

# =============================================================================
# CONFIGURACIÓN Y VALIDACIONES
# =============================================================================

readonly AUTO_CONFIRM="${AUTO_CONFIRM:-false}"

validate_environment() {
  if [[ -z "$PARSED_FIELDS" ]]; then
    echo "❌ No se encontraron campos en \$PARSED_FIELDS para generate-tests"
    exit 1
  fi

  if [[ -z "${entity:-}" ]]; then
    echo "❌ Variable 'entity' no definida"
    exit 1
  fi

  if [[ -z "${EntityPascal:-}" ]]; then
    echo "❌ Variable 'EntityPascal' no definida"
    exit 1
  fi
}

# =============================================================================
# PROCESAMIENTO DE CAMPOS
# =============================================================================

parse_fields() {
  local fields_js
  fields_js=$(node -e "
    try {
      const { fields } = JSON.parse(process.env.PARSED_FIELDS);
      if (!Array.isArray(fields) || fields.length === 0) {
        throw new Error('No se encontraron campos en el esquema');
      }
      fields.forEach((f, i) => {
        const dummy = String(f.dummy || '').replace(/\"/g, '');
        const updated = String(f.updated || '').replace(/\"/g, '');
        console.log('test_names[' + i + ']=\"' + f.name + '\"');
        console.log('test_dummy[' + i + ']=\"' + dummy + '\"');
        console.log('test_updated[' + i + ']=\"' + updated + '\"');
      });
    } catch (e) {
      console.error('❌ Error al parsear FIELDS en generate-tests:', e.message);
      process.exit(1);
    }
  " PARSED_FIELDS="$PARSED_FIELDS")

  eval "$fields_js"
}

build_test_data() {
  input_entries=""
  factory_asserts=""
  create_asserts=""
  update_entries=""
  update_asserts=""

  for i in "${!test_names[@]}"; do
    local name="${test_names[$i]}"
    local dummy="${test_dummy[$i]}"
    local updated="${test_updated[$i]}"

    input_entries+="    $name: $dummy,\n"
    factory_asserts+="  assert.strictEqual(entity.$name, data.$name);\n"
    create_asserts+="  assert.strictEqual(entity.$name, input.$name);\n"
    update_entries+="    $name: $updated,\n"
    update_asserts+="  assert.strictEqual(updated.$name, updateInput.$name);\n"
  done

  # Remover la última coma
  input_entries=$(echo -e "$input_entries" | sed '$s/,\n$//')
  update_entries=$(echo -e "$update_entries" | sed '$s/,\n$//')
}

# =============================================================================
# UTILIDADES
# =============================================================================

create_test_file() {
  local file_path="$1"
  shift

  if [[ -f "$file_path" ]]; then
    if [[ "$AUTO_CONFIRM" != true ]]; then
      read -rp "❗ El archivo $file_path ya existe. ¿Sobrescribir? (y/n): " confirm
      [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return
    fi
  fi

  cat >"$file_path" <<<"$*"
  echo "✅ Test generado: $file_path"
}

# =============================================================================
# GENERADORES DE TESTS
# =============================================================================

generate_create_test() {
  local test_path="$1"
  create_test_file "$test_path/create-$entity.test.js" "$(
    cat <<EOF
import assert from 'assert';
import { $EntityPascal } from '../../../src/domain/$entity/${entity}.js';
import { InMemory${EntityPascal}Repository } from '../../../src/infrastructure/$entity/in-memory-${entity}-repository.js';
import { Create$EntityPascal } from '../../../src/application/$entity/use-cases/create-$entity.js';

async function test${EntityPascal}Factory() {
  const data = {
    id: '123',
    active: true,
    createdAt: new Date('2025-01-01T00:00:00Z'),
    updatedAt: new Date('2025-01-01T00:00:00Z'),
    deletedAt: null,
    ownedBy: null,
$input_entries
  };

  const entity = new $EntityPascal(data);

  assert.strictEqual(entity.id, data.id);
  assert.strictEqual(entity.active, data.active);
  assert.strictEqual(entity.deletedAt, null);
  assert.strictEqual(entity.ownedBy, null);
$factory_asserts
  console.log('✅ $EntityPascal factory test passed');
}

async function testCreate${EntityPascal}() {
  const repo = new InMemory${EntityPascal}Repository();
  const create = new Create$EntityPascal(repo);

  const input = {
$input_entries
  };

  const entity = await create.execute(input);

  assert.ok(entity.id, 'Debe asignar id');
  assert.strictEqual(entity.active, true);
  assert.strictEqual(entity.deletedAt, null);
  assert.strictEqual(entity.ownedBy, null);
$create_asserts
  console.log('✅ create-$entity passed');
}

test${EntityPascal}Factory().catch(err => {
  console.error('❌ factory-$entity failed', err);
  process.exit(1);
});

testCreate${EntityPascal}().catch(err => {
  console.error('❌ create-$entity failed', err);
  process.exit(1);
});
EOF
  )"
}

generate_get_test() {
  local test_path="$1"
  create_test_file "$test_path/get-$entity.test.js" "$(
    cat <<EOF
import assert from 'assert';
import { InMemory${EntityPascal}Repository } from '../../../src/infrastructure/$entity/in-memory-${entity}-repository.js';
import { Create$EntityPascal } from '../../../src/application/$entity/use-cases/create-$entity.js';
import { Get$EntityPascal } from '../../../src/application/$entity/use-cases/get-$entity.js';

async function testGet${EntityPascal}() {
  const repo = new InMemory${EntityPascal}Repository();
  const create = new Create$EntityPascal(repo);
  const get = new Get$EntityPascal(repo);

  const input = {
$input_entries
  };

  const created = await create.execute(input);
  const fetched = await get.execute(created.id);

  assert.strictEqual(fetched.id, created.id);
  console.log('✅ get-$entity passed');
}

testGet${EntityPascal}().catch(err => {
  console.error('❌ get-$entity failed', err);
  process.exit(1);
});
EOF
  )"
}

generate_update_test() {
  local test_path="$1"
  create_test_file "$test_path/update-$entity.test.js" "$(
    cat <<EOF
import assert from 'assert';
import { InMemory${EntityPascal}Repository } from '../../../src/infrastructure/$entity/in-memory-${entity}-repository.js';
import { Create$EntityPascal } from '../../../src/application/$entity/use-cases/create-$entity.js';
import { Update$EntityPascal } from '../../../src/application/$entity/use-cases/update-$entity.js';

async function testUpdate${EntityPascal}() {
  const repo = new InMemory${EntityPascal}Repository();
  const create = new Create$EntityPascal(repo);
  const update = new Update$EntityPascal(repo);

  const input = {
$input_entries
  };

  const created = await create.execute(input);

  const updateInput = {
$update_entries
  };

  const updated = await update.execute(created.id, updateInput);

$update_asserts
  console.log('✅ update-$entity passed');
}

testUpdate${EntityPascal}().catch(err => {
  console.error('❌ update-$entity failed', err);
  process.exit(1);
});
EOF
  )"
}

generate_delete_test() {
  local test_path="$1"
  create_test_file "$test_path/delete-$entity.test.js" "$(
    cat <<EOF
import assert from 'assert';
import { InMemory${EntityPascal}Repository } from '../../../src/infrastructure/$entity/in-memory-${entity}-repository.js';
import { Create$EntityPascal } from '../../../src/application/$entity/use-cases/create-$entity.js';
import { Delete$EntityPascal } from '../../../src/application/$entity/use-cases/delete-$entity.js';
import { Get$EntityPascal } from '../../../src/application/$entity/use-cases/get-$entity.js';

async function testDelete${EntityPascal}() {
  const repo = new InMemory${EntityPascal}Repository();
  const create = new Create$EntityPascal(repo);
  const del = new Delete$EntityPascal(repo);
  const get = new Get$EntityPascal(repo);

  const input = {
$input_entries
  };

  const created = await create.execute(input);
  const deleted = await del.execute(created.id);
  assert.strictEqual(deleted, true);

  const fetched = await get.execute(created.id);
  assert.strictEqual(fetched, null);

  console.log('✅ delete-$entity passed');
}

testDelete${EntityPascal}().catch(err => {
  console.error('❌ delete-$entity failed', err);
  process.exit(1);
});
EOF
  )"
}

generate_deactivate_test() {
  local test_path="$1"
  create_test_file "$test_path/deactivate-$entity.test.js" "$(
    cat <<EOF
import assert from 'assert';
import { InMemory${EntityPascal}Repository } from '../../../src/infrastructure/$entity/in-memory-${entity}-repository.js';
import { Create$EntityPascal } from '../../../src/application/$entity/use-cases/create-$entity.js';
import { Deactivate$EntityPascal } from '../../../src/application/$entity/use-cases/deactivate-$entity.js';
import { Get$EntityPascal } from '../../../src/application/$entity/use-cases/get-$entity.js';

async function testDeactivate${EntityPascal}() {
  const repo = new InMemory${EntityPascal}Repository();
  const create = new Create$EntityPascal(repo);
  const deactivate = new Deactivate$EntityPascal(repo);
  const get = new Get$EntityPascal(repo);

  const input = {
$input_entries
  };

  const created = await create.execute(input);
  const deactivated = await deactivate.execute(created.id);

  assert.ok(deactivated, 'Debe devolver la entidad desactivada');
  assert.strictEqual(deactivated.active, false);

  const fetched = await get.execute(created.id);
  assert.strictEqual(fetched.active, false);

  console.log('✅ deactivate-$entity passed');
}

testDeactivate${EntityPascal}().catch(err => {
  console.error('❌ deactivate-$entity failed', err);
  process.exit(1);
});
EOF
  )"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
  echo "🔧 Iniciando generación de tests para entidad: $entity"

  # Validaciones
  validate_environment

  # Crear directorio de tests
  local test_path="tests/application/$entity"
  mkdir -p "$test_path"

  # Procesar campos
  parse_fields
  build_test_data

  # Generar todos los tests
  echo "📝 Generando archivos de test..."
  generate_create_test "$test_path"
  generate_get_test "$test_path"
  generate_update_test "$test_path"
  generate_delete_test "$test_path"
  generate_deactivate_test "$test_path"

  echo "✅ Tests generados exitosamente en: $test_path"
}

# =============================================================================
# PUNTO DE ENTRADA
# =============================================================================

# Ejecutar solo si el script es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Llamada implícita si fue sourced desde otro script
if [[ -n "${entity:-}" && -n "${EntityPascal:-}" ]]; then
  main "$@"
fi
