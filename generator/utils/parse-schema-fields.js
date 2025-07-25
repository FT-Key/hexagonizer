// generator/utils/parse-schema-fields.js
import fs from 'fs';

const [, , schemaPath] = process.argv;

let raw;
if (schemaPath && fs.existsSync(schemaPath)) {
  raw = fs.readFileSync(schemaPath, 'utf8');
} else {
  raw = await new Promise((resolve, reject) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => data += chunk);
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', reject);
  });
}

const schema = JSON.parse(raw);

const useTimestamps = schema.timestamps !== false;
const useSoftDelete = schema.softDelete !== false;
const useOwnership = schema.ownership !== false;
const useAuditable = schema.auditable !== false;

const BASE_GENERIC_FIELDS = [
  { name: 'id' }, // Siempre requerido
  { name: 'active', default: true },
  ...(useTimestamps ? [
    { name: 'createdAt', default: 'new Date()' },
    { name: 'updatedAt', default: 'new Date()' }
  ] : []),
  ...(useSoftDelete ? [
    { name: 'deletedAt', default: null, sensitive: true }
  ] : []),
  ...(useOwnership ? [
    { name: 'ownedBy', default: null, sensitive: true }
  ] : []),
  ...(useAuditable ? [
    { name: 'createdBy', default: null, sensitive: true },
    { name: 'updatedBy', default: null, sensitive: true }
  ] : [])
];

const ALL_GENERIC_NAMES = BASE_GENERIC_FIELDS.map(f => f.name);

const customFields = (schema.fields || [])
  .filter(f => !ALL_GENERIC_NAMES.includes(f.name))
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
    sensitive: f.sensitive ?? false,
    default: typeof f.default !== 'undefined' ? JSON.stringify(f.default) : '',
    dummy: typeof f.dummy !== 'undefined' ? f.dummy : `"${f.name}_test"`,
    updated: `"${f.name}_updated"`
  }));

const genericFields = BASE_GENERIC_FIELDS.map(({ name, ...rest }) => {
  const override = (schema.fields || []).find(f => f.name === name);

  return {
    name,
    required: name === 'id'
      ? true
      : (override?.required ?? false),
    type: override?.type ?? '',
    enum: override?.enum ?? null,
    format: override?.format ?? '',
    minLength: override?.minLength ?? '',
    maxLength: override?.maxLength ?? '',
    min: override?.min ?? '',
    max: override?.max ?? '',
    nullable: override?.nullable ?? false,
    sensitive: override?.sensitive ?? rest.sensitive ?? false,
    default: typeof override?.default !== 'undefined'
      ? JSON.stringify(override.default)
      : (typeof rest.default !== 'undefined' ? JSON.stringify(rest.default) : ''),
    dummy: typeof override?.dummy !== 'undefined'
      ? override.dummy
      : `"${name}_test"`,
    updated: `"${name}_updated"`
  };
});

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
