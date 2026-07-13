const express = require('express');
const cors = require('cors');
const axios = require('axios');
const dns = require('dns');
const { promisify } = require('util');
const whois = require('node-whois');
const crypto = require('crypto');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Promisify DNS methods
const resolve4 = promisify(dns.resolve4);
const resolve6 = promisify(dns.resolve6);
const resolveMx = promisify(dns.resolveMx);
const resolveTxt = promisify(dns.resolveTxt);
const resolveNs = promisify(dns.resolveNs);
const resolveCname = promisify(dns.resolveCname);
const resolveSoa = promisify(dns.resolveSoa);
const whoisLookup = promisify(whois.lookup);

// ============================================
// 1. DNS Lookup
// ============================================
app.get('/api/dns/:domain', async (req, res) => {
  const domain = req.params.domain;
  try {
    const results = {};

    try { results.A = await resolve4(domain); } catch (e) { results.A = []; }
    try { results.AAAA = await resolve6(domain); } catch (e) { results.AAAA = []; }
    try { results.MX = await resolveMx(domain); } catch (e) { results.MX = []; }
    try {
      const txtRecords = await resolveTxt(domain);
      results.TXT = txtRecords.map(r => r.join(''));
    } catch (e) { results.TXT = []; }
    try { results.NS = await resolveNs(domain); } catch (e) { results.NS = []; }
    try { results.CNAME = await resolveCname(domain); } catch (e) { results.CNAME = []; }
    try { results.SOA = await resolveSoa(domain); } catch (e) { results.SOA = null; }

    res.json({ success: true, domain, records: results });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// 2. WHOIS Lookup
// ============================================
app.get('/api/whois/:domain', async (req, res) => {
  const domain = req.params.domain;
  try {
    const data = await whoisLookup(domain);
    // Parse WHOIS raw text into key-value pairs
    const parsed = {};
    const lines = data.split('\n');
    for (const line of lines) {
      const idx = line.indexOf(':');
      if (idx > 0) {
        const key = line.substring(0, idx).trim();
        const val = line.substring(idx + 1).trim();
        if (key && val && !key.startsWith('%') && !key.startsWith('#')) {
          if (parsed[key]) {
            if (Array.isArray(parsed[key])) {
              parsed[key].push(val);
            } else {
              parsed[key] = [parsed[key], val];
            }
          } else {
            parsed[key] = val;
          }
        }
      }
    }
    res.json({ success: true, domain, raw: data, parsed });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// 3. Subdomain Finder (Hybrid crt.sh + HackerTarget)
// ============================================
app.get('/api/subdomains/:domain', async (req, res) => {
  const domain = req.params.domain;
  const subdomainsSet = new Set();

  // 1. Try crt.sh
  try {
    const response = await axios.get(`https://crt.sh/?q=%.${domain}&output=json`, {
      timeout: 7000,
      headers: { 
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' 
      }
    });
    if (response.data && Array.isArray(response.data)) {
      response.data.forEach(entry => {
        if (entry.name_value) {
          entry.name_value.split('\n').forEach(name => {
            const cleanName = name.trim().toLowerCase().replace(/^\*\./, '');
            if (cleanName.endsWith(domain)) {
              subdomainsSet.add(cleanName);
            }
          });
        }
      });
    }
  } catch (error) {
    console.error(`[crt.sh] Error querying subdomains for ${domain}: ${error.message}`);
  }

  // 2. Try HackerTarget as fallback if crt.sh failed or returned empty results
  if (subdomainsSet.size === 0) {
    try {
      const response = await axios.get(`https://api.hackertarget.com/hostsearch/?q=${domain}`, {
        timeout: 6000
      });
      if (response.data && typeof response.data === 'string' && !response.data.includes('error limit exceeded')) {
        const lines = response.data.split('\n');
        lines.forEach(line => {
          const parts = line.split(',');
          if (parts[0]) {
            const cleanName = parts[0].trim().toLowerCase();
            if (cleanName.endsWith(domain)) {
              subdomainsSet.add(cleanName);
            }
          }
        });
      }
    } catch (error) {
      console.error(`[HackerTarget] Fallback failed for ${domain}: ${error.message}`);
    }
  }

  const subdomains = [...subdomainsSet].sort();
  res.json({ 
    success: true, 
    domain, 
    count: subdomains.length, 
    subdomains 
  });
});

// ============================================
// 4. Technology Detection (HTTP Headers analysis)
// ============================================
app.get('/api/tech/:domain', async (req, res) => {
  const domain = req.params.domain;
  try {
    const url = domain.startsWith('http') ? domain : `https://${domain}`;
    const response = await axios.get(url, {
      timeout: 10000,
      maxRedirects: 5,
      headers: { 'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/125.0.0.0 Mobile Safari/537.36' },
      validateStatus: () => true
    });

    const headers = response.headers;
    const body = typeof response.data === 'string' ? response.data : '';
    const technologies = [];

    // Server detection
    if (headers['server']) {
      technologies.push({ category: 'Web Server', name: headers['server'], source: 'HTTP Header' });
    }
    if (headers['x-powered-by']) {
      technologies.push({ category: 'Framework', name: headers['x-powered-by'], source: 'HTTP Header' });
    }

    // CMS detection from HTML
    if (body.includes('wp-content') || body.includes('wp-includes')) {
      technologies.push({ category: 'CMS', name: 'WordPress', source: 'HTML Analysis' });
    }
    if (body.includes('Joomla')) {
      technologies.push({ category: 'CMS', name: 'Joomla', source: 'HTML Analysis' });
    }
    if (body.includes('Drupal')) {
      technologies.push({ category: 'CMS', name: 'Drupal', source: 'HTML Analysis' });
    }
    if (body.includes('/sites/default/files')) {
      technologies.push({ category: 'CMS', name: 'Drupal', source: 'HTML Analysis' });
    }

    // JS Framework detection
    if (body.includes('react') || body.includes('__NEXT_DATA__') || body.includes('_next/')) {
      technologies.push({ category: 'JavaScript Framework', name: 'React / Next.js', source: 'HTML Analysis' });
    }
    if (body.includes('ng-') || body.includes('angular')) {
      technologies.push({ category: 'JavaScript Framework', name: 'Angular', source: 'HTML Analysis' });
    }
    if (body.includes('vue') || body.includes('__vue__')) {
      technologies.push({ category: 'JavaScript Framework', name: 'Vue.js', source: 'HTML Analysis' });
    }
    if (body.includes('jquery') || body.includes('jQuery')) {
      technologies.push({ category: 'JavaScript Library', name: 'jQuery', source: 'HTML Analysis' });
    }
    if (body.includes('bootstrap')) {
      technologies.push({ category: 'CSS Framework', name: 'Bootstrap', source: 'HTML Analysis' });
    }
    if (body.includes('tailwind')) {
      technologies.push({ category: 'CSS Framework', name: 'Tailwind CSS', source: 'HTML Analysis' });
    }

    // Security headers
    const securityHeaders = {};
    const secHeaders = [
      'strict-transport-security', 'content-security-policy',
      'x-frame-options', 'x-content-type-options',
      'x-xss-protection', 'referrer-policy',
      'permissions-policy', 'access-control-allow-origin'
    ];
    for (const h of secHeaders) {
      if (headers[h]) securityHeaders[h] = headers[h];
    }

    res.json({
      success: true,
      domain,
      technologies,
      securityHeaders,
      allHeaders: headers
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// 5. IP & Hosting Information
// ============================================
app.get('/api/ip/:domain', async (req, res) => {
  const domain = req.params.domain;
  try {
    let ip;
    try {
      const ips = await resolve4(domain);
      ip = ips[0];
    } catch (e) {
      return res.status(400).json({ success: false, error: 'Could not resolve domain' });
    }

    // Use ip-api.com for geolocation (free, no key required)
    const geoResponse = await axios.get(`http://ip-api.com/json/${ip}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,asname,reverse,query`, {
      timeout: 10000
    });

    res.json({
      success: true,
      domain,
      ip,
      hosting: geoResponse.data
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// 6. Port Information (Passive - via Shodan InternetDB)
// ============================================
app.get('/api/ports/:domain', async (req, res) => {
  const domain = req.params.domain;
  try {
    let ip;
    try {
      const ips = await resolve4(domain);
      ip = ips[0];
    } catch (e) {
      return res.status(400).json({ success: false, error: 'Could not resolve domain' });
    }

    // Shodan InternetDB is free and doesn't require an API key
    const shodanResponse = await axios.get(`https://internetdb.shodan.io/${ip}`, {
      timeout: 10000
    });

    res.json({
      success: true,
      domain,
      ip,
      ports: shodanResponse.data.ports || [],
      hostnames: shodanResponse.data.hostnames || [],
      cpes: shodanResponse.data.cpes || [],
      vulns: shodanResponse.data.vulns || [],
      tags: shodanResponse.data.tags || []
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// 7. Hash Identifier & Checker
// ============================================
app.post('/api/hash/identify', (req, res) => {
  const { hash } = req.body;
  if (!hash) return res.status(400).json({ success: false, error: 'Hash is required' });

  const cleanHash = hash.trim();
  const length = cleanHash.length;
  const possibleTypes = [];

  if (/^[a-f0-9]+$/i.test(cleanHash)) {
    if (length === 32) possibleTypes.push('MD5', 'NTLM');
    if (length === 40) possibleTypes.push('SHA-1');
    if (length === 56) possibleTypes.push('SHA-224');
    if (length === 64) possibleTypes.push('SHA-256');
    if (length === 96) possibleTypes.push('SHA-384');
    if (length === 128) possibleTypes.push('SHA-512');
  }
  if (cleanHash.startsWith('$2a$') || cleanHash.startsWith('$2b$') || cleanHash.startsWith('$2y$')) {
    possibleTypes.push('bcrypt');
  }
  if (cleanHash.startsWith('$1$')) possibleTypes.push('MD5 Crypt');
  if (cleanHash.startsWith('$5$')) possibleTypes.push('SHA-256 Crypt');
  if (cleanHash.startsWith('$6$')) possibleTypes.push('SHA-512 Crypt');
  if (cleanHash.startsWith('$argon2')) possibleTypes.push('Argon2');

  if (possibleTypes.length === 0) possibleTypes.push('Unknown');

  res.json({ success: true, hash: cleanHash, length, possibleTypes });
});

// Generate hash from text
app.post('/api/hash/generate', (req, res) => {
  const { text, algorithm } = req.body;
  if (!text) return res.status(400).json({ success: false, error: 'Text is required' });

  const algo = algorithm || 'md5';
  try {
    const hash = crypto.createHash(algo).update(text).digest('hex');
    res.json({ success: true, text, algorithm: algo, hash });
  } catch (error) {
    res.status(400).json({ success: false, error: `Unsupported algorithm: ${algo}` });
  }
});

// ============================================
// 8. Full Recon (All-in-One)
// ============================================
app.get('/api/recon/:domain', async (req, res) => {
  const domain = req.params.domain;
  const results = { domain, timestamp: new Date().toISOString() };

  // DNS
  try {
    const dnsResults = {};
    try { dnsResults.A = await resolve4(domain); } catch (e) { dnsResults.A = []; }
    try { dnsResults.MX = await resolveMx(domain); } catch (e) { dnsResults.MX = []; }
    try {
      const txtRecords = await resolveTxt(domain);
      dnsResults.TXT = txtRecords.map(r => r.join(''));
    } catch (e) { dnsResults.TXT = []; }
    try { dnsResults.NS = await resolveNs(domain); } catch (e) { dnsResults.NS = []; }
    try { dnsResults.CNAME = await resolveCname(domain); } catch (e) { dnsResults.CNAME = []; }
    results.dns = dnsResults;
  } catch (e) { results.dns = { error: e.message }; }

  // IP Info
  try {
    if (results.dns && results.dns.A && results.dns.A.length > 0) {
      const ip = results.dns.A[0];
      results.ip = ip;
      const geoResponse = await axios.get(`http://ip-api.com/json/${ip}?fields=status,country,countryCode,regionName,city,isp,org,as,asname,lat,lon,query`, { timeout: 8000 });
      results.hosting = geoResponse.data;
    }
  } catch (e) { results.hosting = { error: e.message }; }

  // Ports (Shodan InternetDB)
  try {
    if (results.ip) {
      const shodanResponse = await axios.get(`https://internetdb.shodan.io/${results.ip}`, { timeout: 8000 });
      results.ports = shodanResponse.data;
    }
  } catch (e) { results.ports = { error: e.message }; }

  res.json({ success: true, ...results });
});

// ============================================
// Health check
// ============================================
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', version: '1.0.0', name: 'ReconX Backend' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 ReconX Backend running on port ${PORT}`);
});
