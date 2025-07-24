#!/usr/bin/env node
// Recibe JSON array en stdin y devuelve JSON con campos filtrados

const excludedFields = ["deletedAt", "ownedBy"];

let input = "";

process.stdin.on("data", (chunk) => {
  input += chunk;
});

process.stdin.on("end", () => {
  let fields;
  try {
    fields = JSON.parse(input);
  } catch (e) {
    console.error("❌ Error parseando JSON en filter-query-fields:", e.message);
    process.exit(1);
  }

  // Filtrar campos no sensibles y no excluidos
  const filtered = fields.filter(f => {
    const isSensitive = f.sensitive === true;
    const isExcluded = excludedFields.includes(f.name);
    return !isSensitive && !isExcluded;
  });

  // Crear listas únicas y ordenadas para searchable, sortable y filterable
  // Si el campo tiene la propiedad correspondiente a true, lo incluimos,
  // sino se asume que NO pertenece.

  const searchableFields = filtered.filter(f => f.searchable).map(f => f.name).sort();
  const sortableFields = filtered.filter(f => f.sortable).map(f => f.name).sort();
  const filterableFields = filtered.filter(f => f.filterable).map(f => f.name).sort();

  // Output JSON para bash procesar luego
  const output = {
    searchableFields,
    sortableFields,
    filterableFields
  };

  console.log(JSON.stringify(output));
});
