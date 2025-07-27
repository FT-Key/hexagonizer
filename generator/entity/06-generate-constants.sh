#!/bin/bash
# generator/entity/06-generate-constants-mocks.sh
# shellcheck disable=SC2154
set -e

constants_file="src/domain/$entity/constants.js"
mocks_file="src/domain/$entity/mocks.js"

extract_schema_constants() {
  eval "$(echo "$PARSED_FIELDS" | node -e "
    const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    const fields = input.fields || [];
    
    const constants = [];
    const mockFields = {};

    fields.forEach(field => {
      const { name, type, default: defaultVal, enum: enumVals } = field;
      
      // Generate constants for defaults and enums
      if (defaultVal !== undefined && defaultVal !== null) {
        const constName = \`DEFAULT_\${name.toUpperCase()}\`;
        let constValue = defaultVal;
        
        if (typeof defaultVal === 'string' && !defaultVal.startsWith('new ')) {
          constValue = \`'\${defaultVal}'\`;
        }
        constants.push(\`export const \${constName} = \${constValue};\`);
      }
      
      // Generate enum constants
      if (enumVals && Array.isArray(enumVals)) {
        const enumName = \`\${name.toUpperCase()}_OPTIONS\`;
        const enumValues = enumVals.map(v => \`'\${v}'\`).join(', ');
        constants.push(\`export const \${enumName} = [\${enumValues}];\`);
        
        // Add first enum value as mock
        mockFields[name] = \`'\${enumVals[0]}'\`;
      } else {
        // Generate mock values based on type
        switch (type) {
          case 'string':
            mockFields[name] = name === 'id' ? \`'mock-\${name}-123'\` : \`'mock-\${name}'\`;
            break;
          case 'number':
            mockFields[name] = Math.floor(Math.random() * 100) + 1;
            break;
          case 'boolean':
            mockFields[name] = defaultVal !== undefined ? defaultVal : true;
            break;
          default:
            if (defaultVal !== undefined) {
              mockFields[name] = defaultVal === 'new Date()' ? 'new Date().toISOString()' : defaultVal;
            } else {
              mockFields[name] = \`'mock-\${name}'\`;
            }
        }
      }
    });

    // Output for bash variables
    console.log(\`constants_content='\${constants.join('\\n')}'\`);
    
    const mockEntries = Object.entries(mockFields).map(([key, value]) => {
      const formattedValue = typeof value === 'string' && !value.includes('(') ? value : value;
      return \`  \${key}: \${formattedValue},\`;
    }).join('\\n');
    
    console.log(\`mock_fields='\${mockEntries}'\`);
  ")"
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
