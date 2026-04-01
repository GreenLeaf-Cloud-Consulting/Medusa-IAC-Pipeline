import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Métriques custom
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// ==========================================
// CONFIGURATION DU TEST
// ==========================================
export const options = {
  stages: [
    { duration: '1m', target: 100 },   // Montée progressive : 0 → 100 users
    { duration: '2m', target: 500 },   // Montée : 100 → 500 users
    { duration: '3m', target: 1000 },  // Pic : 1000 users simultanés
    { duration: '2m', target: 500 },   // Descente : 1000 → 500 users
    { duration: '1m', target: 0 },     // Fin : 500 → 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],  // 95% des requêtes < 2 secondes
    http_req_failed:   ['rate<0.05'],   // Moins de 5% d'erreurs
    errors:            ['rate<0.05'],
  },
};

// ==========================================
// URLS CIBLES
// ==========================================
const BASE_URL_BACKEND    = 'http://a8f909db5484b46ad8c7056c3ae00d6b-1014007585.eu-west-3.elb.amazonaws.com';
const BASE_URL_STOREFRONT = 'http://ac79d64780c8f428582ab270da8b13af-1880559677.eu-west-3.elb.amazonaws.com';
const PUBLISHABLE_KEY     = 'pk_74022c0fa1718d207c7aa3b42fca8a177094ec76b7619be5f047ceb0b81566da';

// On teste le backend par défaut
const BASE_URL = BASE_URL_BACKEND;

// ==========================================
// SCÉNARIO DE TEST
// ==========================================
export default function () {
  // --- Test 1 : Health check ---
  const healthRes = http.get(`${BASE_URL}/health`);
  check(healthRes, {
    'health check status 200': (r) => r.status === 200,
    'health check rapide < 500ms': (r) => r.timings.duration < 500,
  });
  errorRate.add(healthRes.status !== 200);
  responseTime.add(healthRes.timings.duration);

  sleep(0.5);

  // --- Test 2 : Liste des produits (requête DB via PgBouncer) ---
  const productsRes = http.get(`${BASE_URL}/store/products`, {
    headers: { 'x-publishable-api-key': PUBLISHABLE_KEY },
  });
  check(productsRes, {
    'products status 200': (r) => r.status === 200,
    'products répond < 2s': (r) => r.timings.duration < 2000,
  });
  errorRate.add(productsRes.status !== 200);
  responseTime.add(productsRes.timings.duration);

  sleep(1);
}

// ==========================================
// RÉSUMÉ FINAL
// ==========================================
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'k6/results/summary.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metrics = data.metrics;
  return `
==========================================
  RÉSULTATS TEST DE CHARGE - MEDUSA
==========================================
  Durée totale     : ${Math.round(data.state.testRunDurationMs / 1000)}s
  Requêtes totales : ${metrics.http_reqs?.values?.count || 0}
  Taux d'erreur    : ${((metrics.http_req_failed?.values?.rate || 0) * 100).toFixed(2)}%

  Temps de réponse :
    Médiane (p50)  : ${Math.round(metrics.http_req_duration?.values?.med || 0)}ms
    p95            : ${Math.round(metrics.http_req_duration?.values['p(95)'] || 0)}ms
    p99            : ${Math.round(metrics.http_req_duration?.values['p(99)'] || 0)}ms
    Maximum        : ${Math.round(metrics.http_req_duration?.values?.max || 0)}ms

  Débit            : ${(metrics.http_reqs?.values?.rate || 0).toFixed(2)} req/s
==========================================
`;
}
