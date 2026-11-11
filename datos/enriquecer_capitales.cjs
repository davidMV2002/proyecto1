// Enriquecimiento optativo de capitales: por defecto solo comprueba (sin escribir).
// Ejecutar desde la raíz: node datos/enriquecer_capitales.cjs
// Para aplicar, tras revisar la salida: node datos/enriquecer_capitales.cjs --aplicar
// Requiere Firebase CLI instalada e iniciada con acceso al proyecto.
const path = require('node:path');
const dataset = require('./capitales_consultas.json');
const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const root = 'projects/proyecto1-98a31/databases/(default)/documents';
const endpoint = `https://firestore.googleapis.com/v1/${root}`;
const campos = ['zona', 'poblacion', 'anioPoblacion', 'fuentePoblacion', 'fechaAnadida'];
const valorFirestore = (campo, valor) => campo === 'fechaAnadida'
  ? { timestampValue: valor }
  : typeof valor === 'number' ? { integerValue: String(valor) } : { stringValue: valor };

(async () => {
  if (process.argv.slice(2).some(x => x !== '--aplicar')) throw Error('Opción no reconocida');
  const cuenta = auth.getGlobalDefaultAccount();
  if (!cuenta?.tokens?.refresh_token) throw Error('Inicia sesión con Firebase CLI antes de continuar');
  const token = await auth.getAccessToken(cuenta.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const headers = { Authorization: `Bearer ${token.access_token}` };
  const response = await fetch(`${endpoint}/Capitales?pageSize=100`, {headers});
  const data = await response.json();
  if (!response.ok) throw Error(`Error al leer Firestore: HTTP ${response.status}`);
  if (data.nextPageToken) throw Error('Más de 100 capitales; revisa manualmente antes de continuar');
  const docs = new Map((data.documents || []).map(d => [d.name.split('/').pop(), d]));
  const writes = [];
  for (const capital of dataset.capitales) {
    const doc = docs.get(capital.id);
    if (!doc) throw Error(`No existe el documento ${capital.id}`);
    if (new Date(doc.createTime).getTime() !== new Date(capital.fechaAnadida).getTime()) {
      throw Error(`La fecha de creación de ${capital.id} no coincide; revisa antes de modificar`);
    }
    const actualizaciones = {};
    for (const campo of campos) {
      const deseado = valorFirestore(campo, capital[campo]);
      const actual = doc.fields?.[campo];
      if (actual && JSON.stringify(actual) !== JSON.stringify(deseado)) {
        throw Error(`${capital.id}.${campo} ya contiene un valor distinto; no se sobrescribirá`);
      }
      if (!actual) actualizaciones[campo] = deseado;
    }
    const rutas = Object.keys(actualizaciones);
    if (rutas.length) writes.push({
      update: {name: doc.name, fields: actualizaciones},
      updateMask: {fieldPaths: rutas},
      currentDocument: {updateTime: doc.updateTime},
    });
  }
  console.log(`${dataset.capitales.length} capitales comprobadas; ${writes.length} requieren nuevos campos.`);
  if (!process.argv.includes('--aplicar')) {
    console.log('Modo de comprobación: no se han modificado datos.');
    return;
  }
  if (!writes.length) { console.log('Los datos ya estaban actualizados.'); return; }
  const result = await fetch(`${endpoint}:commit`, {
    method: 'POST', headers: {...headers, 'Content-Type': 'application/json'}, body: JSON.stringify({writes}),
  });
  const body = await result.json();
  if (!result.ok) throw Error(`No se han aplicado los cambios: HTTP ${result.status} (${body.error?.message || 'error'})`);
  console.log(`Actualización atómica completada: ${body.writeResults.length} documentos.`);
})().catch(e => {console.error(e.message); process.exitCode = 1;});
