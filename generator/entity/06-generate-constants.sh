#!/bin/bash
# generator/entity/06-generate-constants-mocks.sh
# shellcheck disable=SC2154
set -e

constants_file="src/domain/$entity/constants.js"
mocks_file="src/domain/$entity/mocks.js"

extract_schema_constants() {
  local tmp_script
  tmp_script=$(mktemp)

  cat >"$tmp_script" <<'EOF'
const fs = require("fs");

const input = JSON.parse(fs.readFileSync(0, "utf8"));
const fields = input.fields || [];

const constants = [];
const mockFields = {};

fields.forEach(field => {
  const { name, type, default: defaultVal, enum: enumVals } = field;

  if (defaultVal !== undefined && defaultVal !== null) {
    const constName = `DEFAULT_${name.toUpperCase()}`;
    let constValue = defaultVal;

    if (typeof defaultVal === "string" && !defaultVal.startsWith("new ")) {
      constValue = `'${defaultVal}'`;
    }
    constants.push(`export const ${constName} = ${constValue};`);
  }

  if (enumVals && Array.isArray(enumVals)) {
    const enumName = `${name.toUpperCase()}_OPTIONS`;
    const enumValues = enumVals.map(v => `'${v}'`).join(", ");
    constants.push(`export const ${enumName} = [${enumValues}];`);
    mockFields[name] = enumVals[0];
  } else {
    let mockValue;

    if (name === "id") {
      mockValue = "mock-id-123";
    } else {
      switch (type) {
        case "string":
          mockValue = `mock-${name}`;
          break;
        case "number":
          mockValue = Math.floor(Math.random() * 100) + 1;
          break;
        case "boolean":
          mockValue = defaultVal !== undefined ? defaultVal : true;
          break;
        case "date":
        case "Date":
          mockValue = "new Date()";
          break;
        default:
          if (defaultVal === "new Date()") {
            mockValue = "new Date()";
          } else if (typeof defaultVal === "string" && !defaultVal.startsWith("new ")) {
            mockValue = defaultVal;
          } else if (defaultVal !== undefined && defaultVal !== null) {
            mockValue = defaultVal;
          } else {
            mockValue = `mock-${name}`;
          }
      }
    }

    mockFields[name] = mockValue;
  }
});

const mockEntries = Object.entries(mockFields).map(([key, value]) => {
  let formattedValue = value;

  if (value === null || value === "null") {
  formattedValue = "null";
} else if (typeof value === "number") {
  formattedValue = value.toString();
} else if (typeof value === "boolean") {
  formattedValue = value.toString();
} else if (typeof value === "string") {
  // quitar comillas si vienen con ellas
  formattedValue = value.replace(/^"+|"+$/g, "").trim();
}

  const isCode = /^(new Date\(\)|null|true|false|[0-9]+(\.[0-9]+)?)$/.test(formattedValue);
  const finalValue = isCode ? formattedValue : `'${formattedValue.replace(/'/g, "\\'")}'`;

  return `  ${key}: ${finalValue},`;
}).join("\n");

const constantsEncoded = Buffer.from(constants.join("\n"), "utf8").toString("base64");
const mockEncoded = Buffer.from(mockEntries, "utf8").toString("base64");

console.log("constants_base64=" + constantsEncoded);
console.log("mock_base64=" + mockEncoded);
EOF

  # Ejecutar el script temporal pasando el schema por stdin
  eval "$(echo "$PARSED_FIELDS" | node "$tmp_script")"

  # Decodificar los valores
  constants_content="$(echo "$constants_base64" | base64 --decode)"
  mock_fields="$(echo "$mock_base64" | base64 --decode)"

  rm -f "$tmp_script"
}

confirm_file_overwrite() {
  local file="$1"
  local file_type="$2"

  if [[ -f "$file" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "⚠️  El archivo $file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "⏭️  Se omitió la generación de $file"
      return 1
    fi
  fi
  return 0
}

write_constants_file() {
  if ! confirm_file_overwrite "$constants_file" "constantes"; then
    return
  fi

  cat >"$constants_file" <<EOF
// Constantes relacionadas con $EntityPascal

// Valores por defecto
export const DEFAULT_ACTIVE = true;

// Constantes específicas de la entidad
$constants_content

// Configuración de la entidad
export const ${entity^^}_CONFIG = {
  tableName: '$entity',
  primaryKey: 'id',
  timestamps: true,
  softDelete: true
};

// Estados comunes
export const ENTITY_STATES = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  DELETED: 'deleted'
};
EOF

  echo "✅ Constantes generadas: $constants_file"
}

write_mocks_file() {
  if ! confirm_file_overwrite "$mocks_file" "mocks"; then
    return
  fi

  cat >"$mocks_file" <<EOF
// Mocks y datos de prueba para $EntityPascal
import { ${EntityPascal}Factory } from './${entity}-factory.js';

// Mock básico de $EntityPascal
export const mock${EntityPascal} = {
$mock_fields
};

// Array de mocks para testing
export const mock${EntityPascal}List = [
  mock${EntityPascal},
  {
    ...mock${EntityPascal},
    id: 'mock-id-456',
    active: false,
  },
  {
    ...mock${EntityPascal},
    id: 'mock-id-789',
    deletedAt: new Date().toISOString(),
  }
];

// Factory mock helper
export const create${EntityPascal}Mock = (overrides = {}) => {
  return { ...mock${EntityPascal}, ...overrides };
};

// Factory para instancias mock reales
export const create${EntityPascal}Instance = (overrides = {}) => {
  return ${EntityPascal}Factory.create(create${EntityPascal}Mock(overrides));
};
EOF

  echo "✅ Mocks generados: $mocks_file"
}

# Main execution
extract_schema_constants
write_constants_file
write_mocks_file
