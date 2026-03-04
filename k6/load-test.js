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
const BASE_URL_FRANCE  = 'http://prod-france-alb-rayane-731669497.eu-west-2.elb.amazonaws.com';
const BASE_URL_GERMANY = 'http://prod-germany-alb-rayane-1694306237.eu-central-1.elb.amazonaws.com';

// On teste la France par défaut
const BASE_URL = BASE_URL_FRANCE;

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

  // --- Test 2 : Page principale ---
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, {
    'home status 200 ou 404': (r) => r.status === 200 || r.status === 404,
    'home répond < 2s': (r) => r.timings.duration < 2000,
  });
  errorRate.add(homeRes.status >= 500);
  responseTime.add(homeRes.timings.duration);

  sleep(1);
}

// ==========================================
// RÉSUMÉ FINAL
// ==========================================
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'results/summary.json': JSON.stringify(data, null, 2),
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
