#!/usr/bin/env node
// Push shortlist rows to the Google Sheet tracker. Service-account JWT, no deps.
//   node career-ops-sheet.mjs rows.json   → appends rows not already present (dedup by URL)
//   node career-ops-sheet.mjs --format    → (re)apply header, dropdown, colors, widths; idempotent
// Formatting is applied automatically on first run (empty sheet).
import { readFileSync } from 'node:fs';
import { createSign } from 'node:crypto';

const KEY = '/home/tupreti/.config/career-ops/sa.json';
const SHEET_ID = readFileSync('/home/tupreti/.config/career-ops/sheet-id', 'utf8').trim();
const HEADER = ['Date', 'Company', 'Role', 'Job Listing', 'Score /5', 'Resume', 'Cover Letter', 'Status', 'Notes'];
const STATUSES = ['Evaluated', 'Applied', 'Responded', 'Interview', 'Offer', 'Hired', 'Rejected', 'Discarded', 'SKIP'];
const URL_COL = 3, STATUS_COL = 7; // 0-based
const API = `https://sheets.googleapis.com/v4/spreadsheets/${SHEET_ID}`;

async function token() {
  const sa = JSON.parse(readFileSync(KEY, 'utf8'));
  const now = Math.floor(Date.now() / 1000);
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64({ iss: sa.client_email, scope: 'https://www.googleapis.com/auth/spreadsheets', aud: sa.token_uri, iat: now, exp: now + 3600 })}`;
  const sig = createSign('RSA-SHA256').update(unsigned).sign(sa.private_key, 'base64url');
  const r = await fetch(sa.token_uri, { method: 'POST', body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${sig}` }) });
  const j = await r.json();
  if (!j.access_token) throw new Error(`token: ${JSON.stringify(j)}`);
  return j.access_token;
}

async function api(tok, path, opts = {}) {
  const r = await fetch(`${API}${path}`, { ...opts, headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' } });
  const j = await r.json();
  if (!r.ok) throw new Error(`${path}: ${j.error?.message ?? r.status}`);
  return j;
}

const rows = process.argv[2] && process.argv[2] !== '--format' ? JSON.parse(readFileSync(process.argv[2], 'utf8')) : [];
const tok = await token();
const meta = await api(tok, '?fields=sheets.properties');
const { title, sheetId } = meta.sheets[0].properties;
const existing = (await api(tok, `/values/${encodeURIComponent(title)}!A:I`)).values ?? [];

const rgb = (hex) => ({ red: parseInt(hex.slice(0, 2), 16) / 255, green: parseInt(hex.slice(2, 4), 16) / 255, blue: parseInt(hex.slice(4, 6), 16) / 255 });
const STATUS_COLORS = { Applied: '2563eb', Responded: 'd97706', Interview: 'ea580c', Offer: '16a34a', Hired: '15803d', Rejected: 'dc2626', Discarded: '6b7280', SKIP: '9ca3af' };
const WIDTHS = [100, 150, 320, 260, 70, 240, 240, 120, 460];
const cols = (start, end = start + 1) => ({ sheetId, startColumnIndex: start, endColumnIndex: end });
const body = (c) => ({ ...cols(c), startRowIndex: 1 });

async function format() {
  await api(tok, `/values/${encodeURIComponent(title)}!A1?valueInputOption=RAW`, { method: 'PUT', body: JSON.stringify({ values: [HEADER] }) });
  const cur = (await api(tok, '?fields=sheets(properties.sheetId,conditionalFormats,bandedRanges)')).sheets.find((x) => x.properties.sheetId === sheetId);
  const requests = [
    // wipe prior rules so re-runs don't stack them
    ...(cur.conditionalFormats ?? []).map(() => ({ deleteConditionalFormatRule: { sheetId, index: 0 } })),
    ...(cur.bandedRanges ?? []).map((b) => ({ deleteBanding: { bandedRangeId: b.bandedRangeId } })),
    { updateSheetProperties: { properties: { sheetId, title: 'Tracker', tabColorStyle: { rgbColor: rgb('16a34a') }, gridProperties: { frozenRowCount: 1, frozenColumnCount: 2 } }, fields: 'title,tabColorStyle,gridProperties.frozenRowCount,gridProperties.frozenColumnCount' } },
    { repeatCell: { range: { sheetId, startRowIndex: 0, endRowIndex: 1 }, cell: { userEnteredFormat: { backgroundColor: rgb('1f2937'), horizontalAlignment: 'CENTER', verticalAlignment: 'MIDDLE', textFormat: { bold: true, foregroundColor: rgb('ffffff'), fontSize: 11 } } }, fields: 'userEnteredFormat(backgroundColor,horizontalAlignment,verticalAlignment,textFormat)' } },
    { updateDimensionProperties: { range: { sheetId, dimension: 'ROWS', startIndex: 0, endIndex: 1 }, properties: { pixelSize: 36 }, fields: 'pixelSize' } },
    ...WIDTHS.map((w, i) => ({ updateDimensionProperties: { range: { sheetId, dimension: 'COLUMNS', startIndex: i, endIndex: i + 1 }, properties: { pixelSize: w }, fields: 'pixelSize' } })),
    { repeatCell: { range: { sheetId, startRowIndex: 1 }, cell: { userEnteredFormat: { verticalAlignment: 'TOP', wrapStrategy: 'CLIP' } }, fields: 'userEnteredFormat(verticalAlignment,wrapStrategy)' } },
    ...[2, 8].map((c) => ({ repeatCell: { range: body(c), cell: { userEnteredFormat: { wrapStrategy: 'WRAP' } }, fields: 'userEnteredFormat.wrapStrategy' } })),
    ...[0, 4, 7].map((c) => ({ repeatCell: { range: body(c), cell: { userEnteredFormat: { horizontalAlignment: 'CENTER' } }, fields: 'userEnteredFormat.horizontalAlignment' } })),
    ...[5, 6].map((c) => ({ repeatCell: { range: body(c), cell: { userEnteredFormat: { textFormat: { fontFamily: 'Roboto Mono', fontSize: 9, foregroundColor: rgb('6b7280') } } }, fields: 'userEnteredFormat.textFormat' } })),
    { repeatCell: { range: body(STATUS_COL), cell: { userEnteredFormat: { textFormat: { bold: true } } }, fields: 'userEnteredFormat.textFormat.bold' } },
    { setDataValidation: { range: body(STATUS_COL), rule: { condition: { type: 'ONE_OF_LIST', values: STATUSES.map((s) => ({ userEnteredValue: s })) }, showCustomUi: true, strict: true } } },
    { addBanding: { bandedRange: { range: { sheetId, startRowIndex: 0, startColumnIndex: 0, endColumnIndex: HEADER.length }, rowProperties: { headerColor: rgb('1f2937'), firstBandColor: rgb('ffffff'), secondBandColor: rgb('f3f4f6') } } } },
    ...Object.entries(STATUS_COLORS).map(([v, hex]) => ({ addConditionalFormatRule: { index: 0, rule: { ranges: [body(STATUS_COL)], booleanRule: { condition: { type: 'TEXT_EQ', values: [{ userEnteredValue: v }] }, format: { backgroundColor: rgb(hex), textFormat: { foregroundColor: rgb('ffffff'), bold: true } } } } } })),
    { addConditionalFormatRule: { index: 0, rule: { ranges: [body(4)], gradientRule: { minpoint: { color: rgb('fecaca'), type: 'NUMBER', value: '3' }, midpoint: { color: rgb('fef3c7'), type: 'NUMBER', value: '4' }, maxpoint: { color: rgb('bbf7d0'), type: 'NUMBER', value: '5' } } } } },
    { setBasicFilter: { filter: { range: { sheetId, startRowIndex: 0, startColumnIndex: 0, endColumnIndex: HEADER.length } } } },
  ];
  await api(tok, ':batchUpdate', { method: 'POST', body: JSON.stringify({ requests }) });
}

if (process.argv[2] === '--format') { await format(); console.log(JSON.stringify({ sheet: title, formatted: true })); process.exit(0); }
if (existing.length === 0) await format();
// text scores ("4.0/5") defeat the gradient; normalize column E to numbers in place
const textScores = existing.slice(1).filter((r) => r[4] && isNaN(Number(r[4])));
if (textScores.length) await api(tok, `/values/${encodeURIComponent(title)}!E2?valueInputOption=USER_ENTERED`, { method: 'PUT',
  body: JSON.stringify({ values: existing.slice(1).map((r) => [parseFloat(r[4]) || '']) }) });

const seen = new Set(existing.slice(1).map((r) => r[URL_COL]));
const fresh = rows.filter((r) => r.url && !seen.has(r.url))
  .map((r) => [r.date, r.company, r.role, r.url, parseFloat(r.score) || '', r.resume ?? '', r.cover ?? '', 'Evaluated', r.notes ?? '']);
if (fresh.length) await api(tok, `/values/${encodeURIComponent(title)}!A:I:append?valueInputOption=USER_ENTERED`, { method: 'POST', body: JSON.stringify({ values: fresh }) });
console.log(JSON.stringify({ sheet: title, existing: existing.length - 1, added: fresh.length, skipped: rows.length - fresh.length }));
