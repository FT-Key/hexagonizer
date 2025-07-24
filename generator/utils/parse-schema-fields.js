// generator/utils/parse-schema-fields.js
import fs from 'fs';

// Detectar si se pasa un path como argumento
const [, , schemaPath] = process.argv;

let raw;
if (schemaPath && fs.existsSync(schemaPath)) {
  raw = fs.readFileSync(schemaPath, 'utf8');
} else {
  // Leer desde stdin si no se pasa path
  raw = await new Promise((resolve, reject) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => data += chunk);
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', reject);
  });
}

const schema = JSON.parse(raw);

const GENERIC_FIELDS = ['id', 'active', 'createdAt', 'updatedAt', 'deletedAt', 'ownedBy'];

const customFields = (schema.fields || [])
  .filter(f => !GENERIC_FIELDS.includes(f.name))
  .map(f => ({
    name: f.name,
    required: f.required ?? false,
    type: f.type ?? '',
    enum: f.enum ?? null,
    format: f.format ?? '',
    minLength: f.minLength ?? '',
    maxLength: f.maxLength ?? '',
    min: f.min ?? '',
    max: f.max ?? '',
    nullable: f.nullable ?? false,
    dummy: typeof f.dummy !== 'undefined' ? f.dummy : `"${f.name}_test"`,
    updated: `"${f.name}_updated"`
  }));

const genericFields = GENERIC_FIELDS.map(name => {
  const originalField = (schema.fields || []).find(f => f.name === name);

  return {
    name,
    required: originalField?.required ?? false,
    type: originalField?.type ?? '',
    enum: originalField?.enum ?? null,
    format: originalField?.format ?? '',
    minLength: originalField?.minLength ?? '',
    maxLength: originalField?.maxLength ?? '',
    min: originalField?.min ?? '',
    max: originalField?.max ?? '',
    nullable: originalField?.nullable ?? false,
    dummy: originalField && typeof originalField.dummy !== 'undefined' ? originalField.dummy : `"${name}_test"`,
    updated: `"${name}_updated"`
  };
});

// Unificar campos en un solo array fields
const fields = [...genericFields, ...customFields];

const methods = (schema.methods || []).map(m => ({
  name: m.name,
  params: m.params ?? [],
  body: m.body ?? ''
}));

console.log(JSON.stringify({
  fields,
  methods
}));
