import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// ==========================================
// CONFIGURATION DU TEST
// Semaine 2 : test progressif 5K → 20K → 50K
// Think time réaliste : 5-15s entre actions
// (simule de vraies personnes qui lisent les pages)
// ==========================================
export const options = {
  stages: [
    { duration: '2m',  target: 1000  },  // Warm-up
    { duration: '3m',  target: 5000  },  // Palier 1 : 5K users
    { duration: '5m',  target: 5000  },  // Maintien 5K
    { duration: '3m',  target: 20000 },  // Palier 2 : 20K users
    { duration: '5m',  target: 20000 },  // Maintien 20K
    { duration: '3m',  target: 0     },  // Descente
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],  // 95% < 2s
    http_req_failed:   ['rate<0.01'],   // < 1% erreurs
    errors:            ['rate<0.01'],
  },
};

// ==========================================
// URL CIBLE
// ==========================================
const BASE_URL = __ENV.FRONTEND_URL || 'http://FRONTEND_LB_URL';

// Produits disponibles dans Online Boutique
const PRODUCTS = [
  'OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O',
  'L9ECAV2T0O', '2ZYFJ3GM2N', '0PUK6V6EV0',
  'LS4PSXUNUM', '9SIQT8TOJO', '6E92ZMYYFZ',
];

// ==========================================
// SCÉNARIO BLACK FRIDAY RÉALISTE
// Vrai parcours : Accueil → Browse → Produit → Panier
// Think time : 5-15s (temps de lecture humain)
// ==========================================
export default function () {
  // --- Page d'accueil ---
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, {
    'home: status 200': (r) => r.status === 200,
    'home: < 2s':       (r) => r.timings.duration < 2000,
  });
  errorRate.add(homeRes.status !== 200);
  responseTime.add(homeRes.timings.duration);

  // Temps de lecture de la page d'accueil (5-15s)
  sleep(5 + Math.random() * 10);

  // --- Page produit (browse aléatoire) ---
  const product = PRODUCTS[Math.floor(Math.random() * PRODUCTS.length)];
  const productRes = http.get(`${BASE_URL}/product/${product}`);
  check(productRes, {
    'product: status 200': (r) => r.status === 200,
    'product: < 2s':       (r) => r.timings.duration < 2000,
  });
  errorRate.add(productRes.status !== 200);
  responseTime.add(productRes.timings.duration);

  // Temps de lecture du produit (5-15s)
  sleep(5 + Math.random() * 10);

  // 70% des users ajoutent au panier (réaliste)
  if (Math.random() < 0.7) {
    const cartRes = http.post(`${BASE_URL}/cart`, {
      'product_id': product,
      'quantity':   '1',
    }, { redirects: 5 });
    check(cartRes, {
      'cart: status 200': (r) => r.status === 200,
      'cart: < 2s':       (r) => r.timings.duration < 2000,
    });
    errorRate.add(cartRes.status !== 200);
    responseTime.add(cartRes.timings.duration);

    // Réflexion avant de valider (8-20s)
    sleep(8 + Math.random() * 12);
  }
}

// ==========================================
// RÉSUMÉ FINAL
// ==========================================
export function handleSummary(data) {
  return {
    'stdout': textSummary(data),
    'k6/results/summary.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metrics = data.metrics;
  const passed = (metrics.http_req_failed?.values?.rate || 0) < 0.01
    && (metrics.http_req_duration?.values['p(95)'] || 9999) < 2000;

  return `
==========================================
  RÉSULTATS TEST DE CHARGE - BLACK FRIDAY
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

  Résultat         : ${passed ? '✅ SUCCÈS - SLA respecté' : '❌ ÉCHEC - SLA non respecté'}
==========================================
`;
}
