const XLSX = require('xlsx');
const http = require('http');

const EXCEL = '//192.168.11.160/publico/CONTROLE DE VEICULOS/CONTROLE DE FROTA 2026.xlsx';
const API = 'http://192.168.11.57:3000';
const LOGIN_USER = process.argv[2] || 'admin';
const LOGIN_PASS = process.argv[3] || '';
const RAW_TOKEN = process.argv[4] || '';

const SKIP_SHEETS = new Set(['C_Veic','C_Mot','C_Outros','GI','GG1','GG2','CV','Manutencao','JAN','FEV','MAR','ABR','MAI','JUN','JUL','AGO','SET','OUT','NOV','DEZ','Grafico1','6C00','6B00']);
const TIPO_MAP = {'CARRO':'carro','CAMINHÃO':'caminhao','CAMINHONETE':'caminhao','CAMIONETE':'caminhao','SUV':'carro','MOTO':'moto','QUAD':'moto'};

function excelDate(serial) {
  if (!serial || typeof serial !== 'number' || serial < 1000) return null;
  const d = new Date(Math.round((serial - 25569) * 86400 * 1000));
  return d.toISOString().split('T')[0];
}

function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = http.request({
      hostname:'192.168.11.57', port:3000, path, method,
      headers:{
        'Content-Type':'application/json',
        ...(data ? {'Content-Length':Buffer.byteLength(data)} : {}),
        ...(token ? {'Authorization':'Bearer '+token} : {})
      }
    }, res => {
      let buf = '';
      res.on('data', c => buf += c);
      res.on('end', () => {
        try { resolve({status:res.statusCode, data:JSON.parse(buf)}); }
        catch { resolve({status:res.statusCode, data:buf}); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function main() {
  let TOKEN;
  if (RAW_TOKEN) {
    TOKEN = RAW_TOKEN;
    console.log('✓ Usando token direto');
  } else {
    if (!LOGIN_PASS) { console.error('Usage: node import-excel.js <login> <senha> [token]'); process.exit(1); }
    const lr = await request('POST', '/api/auth/login', {login:LOGIN_USER, senha:LOGIN_PASS});
    if (!lr.data.token) { console.error('Login failed:', JSON.stringify(lr.data)); process.exit(1); }
    TOKEN = lr.data.token;
    console.log('✓ Login OK');
  }
  console.log('✓ Login OK');

  const wb = XLSX.readFile(EXCEL);

  // Parse C_Veic
  const cvRows = XLSX.utils.sheet_to_json(wb.Sheets['C_Veic'], {header:1});
  const vehicles = [];
  for (let i = 5; i < cvRows.length; i++) {
    const r = cvRows[i];
    const placa = r[3];
    if (!placa || typeof placa !== 'string' || placa.trim().length < 4) continue;
    const tipo_raw = (r[2] || '').toString().toUpperCase().trim();
    if (!tipo_raw && !(r[4])) continue; // skip separator rows
    const mm = (r[4] || '').toString().split('/');
    const marca = (mm[0] || '').trim();
    const modelo = (mm.slice(1).join('/') || '').trim();
    vehicles.push({
      placa: placa.toString().trim().toUpperCase().replace(/\s+/g,'-'),
      tipo: TIPO_MAP[tipo_raw] || 'carro',
      marca, modelo,
      cor: (r[7] || '').toString().trim(),
      ano: parseInt(r[8]) || null,
    });
  }
  console.log(`→ ${vehicles.length} veículos no C_Veic`);

  // Get existing vehicles
  const exRes = await request('GET', '/api/veiculos', null, TOKEN);
  const existing = {};
  for (const v of (exRes.data || [])) existing[v.placa] = v.id;

  // Create vehicles
  const vehicleMap = {...existing}; // placa -> id
  for (const v of vehicles) {
    if (vehicleMap[v.placa]) { console.log(`  skip (já existe): ${v.placa}`); continue; }
    const payload = {
      placa: v.placa, nome: [v.marca, v.modelo].filter(Boolean).join(' '),
      marca: v.marca, modelo: v.modelo, cor: v.cor, ano: v.ano,
      tipo: v.tipo,
      combustivel: v.tipo === 'moto' ? 'gasolina' : 'flex',
      tanque: v.tipo === 'moto' ? 12 : 50,
    };
    const r = await request('POST', '/api/veiculos', payload, TOKEN);
    if (r.status === 201 || r.status === 200) {
      vehicleMap[v.placa] = r.data.id || r.data.veiculo?.id;
      console.log(`  ✓ veiculo: ${v.placa}`);
    } else {
      console.error(`  ✗ veiculo ${v.placa}:`, JSON.stringify(r.data));
    }
  }

  // Build plate-suffix -> vehicleId map
  const suffixMap = {};
  for (const [placa, id] of Object.entries(vehicleMap)) {
    const clean = placa.replace(/[-\s]/g,'');
    suffixMap[clean.slice(-4)] = id;
    suffixMap[clean.slice(-5)] = id;
    suffixMap[clean] = id;
  }
  // Special: FAN 0148 -> OJC-0148
  if (vehicleMap['OJC-0148']) suffixMap['FAN0148'] = vehicleMap['OJC-0148'];

  // Process vehicle sheets
  const sheetNames = wb.SheetNames.filter(s => !SKIP_SHEETS.has(s));
  const templateRow = JSON.stringify([45750,35201,'FIAT','CORREIA DENTADA',60,60,20,20]);

  for (const sheet of sheetNames) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets[sheet], {header:1});
    const dataRows = rows.slice(3).filter(r => r.length > 0 && r[0] && typeof r[0] === 'number');

    if (dataRows.length === 0) { console.log(`  skip (sem dados): ${sheet}`); continue; }
    // Skip pure template sheets (only 1 row = exact template)
    if (dataRows.length === 1 && JSON.stringify(dataRows[0]) === templateRow) {
      console.log(`  skip (template): ${sheet}`); continue;
    }

    const sheetKey = sheet.replace(/[-\s]/g,'');
    const vid = suffixMap[sheetKey] || suffixMap[sheetKey.slice(-4)] || suffixMap[sheetKey.slice(-5)];
    if (!vid) {
      console.log(`  skip (sem veiculo match): ${sheet}`); continue;
    }

    console.log(`\n→ ${sheet} (${Object.keys(vehicleMap).find(k => vehicleMap[k] === vid)})`);

    // Group by date+oficina for maintenance
    const groups = new Map();
    const fuelRows = [];

    for (const row of dataRows) {
      const dateStr = excelDate(row[0]);
      if (!dateStr) continue;
      const oficina = (row[2] || '').toString().trim();
      const descricao = (row[3] || '').toString().trim();
      const valor = parseFloat(row[4]) || 0;
      const maoObra = parseFloat(row[5]) || 0;
      const litros = parseFloat(row[6]) || 0;
      const valorAbast = parseFloat(row[7]) || 0;
      const obs = (row[8] || '').toString().trim();

      // Skip summary/total rows
      const descUp = descricao.toUpperCase();
      if (descUp.includes('VALOR TOTAL') || descUp.includes('TOTAL COM DESCONTO')) continue;

      // Fuel record
      if (litros > 0) {
        fuelRows.push({dateStr, oficina, litros, total: valorAbast, obs});
      }

      // Maintenance item
      if (descricao || oficina) {
        const key = dateStr + '|' + oficina;
        if (!groups.has(key)) groups.set(key, {dateStr, oficina, valor:0, items:[], obs});
        const g = groups.get(key);
        g.valor += valor + maoObra;
        if (descricao) g.items.push(descricao);
        if (obs && !g.obs) g.obs = obs;
      }
    }

    // Post maintenance records
    let mCount = 0;
    for (const [, g] of groups) {
      if (g.valor === 0 && g.items.length === 0) continue;
      const descricao = g.items.slice(0, 5).join(', ') + (g.items.length > 5 ? ` (+${g.items.length-5})` : '');
      const tipo = descricao.toLowerCase().match(/preventiv|revis/) ? 'preventiva' : 'corretiva';
      const r = await request('POST', '/api/manutencoes', {
        veiculo_id: vid, data: g.dateStr, tipo,
        descricao: descricao || g.oficina || 'Manutenção',
        oficina: g.oficina, valor: g.valor,
        obs: g.obs, status: 'concluida',
      }, TOKEN);
      if (r.status === 201 || r.status === 200) mCount++;
      else console.error(`    ✗ manut ${g.dateStr}:`, JSON.stringify(r.data));
    }
    if (mCount) console.log(`    ✓ ${mCount} manutenções`);

    // Post fuel records
    let fCount = 0;
    for (const f of fuelRows) {
      const preco = f.litros > 0 && f.total > 0 ? f.total / f.litros : 0;
      const r = await request('POST', '/api/abastecimentos', {
        veiculo_id: vid, data: f.dateStr,
        combustivel: 'flex', posto: f.oficina,
        litros: f.litros, preco, total: f.total,
        cheio: true, obs: f.obs,
      }, TOKEN);
      if (r.status === 201 || r.status === 200) fCount++;
      else console.error(`    ✗ abast ${f.dateStr}:`, JSON.stringify(r.data));
    }
    if (fCount) console.log(`    ✓ ${fCount} abastecimentos`);
  }

  console.log('\n✓ Importação concluída!');
}

main().catch(err => { console.error(err); process.exit(1); });
