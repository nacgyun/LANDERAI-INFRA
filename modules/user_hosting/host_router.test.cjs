const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const terraform = fs.readFileSync(path.join(__dirname, 'main.tf'), 'utf8');
const html = fs.readFileSync(path.join(__dirname, 'errors/404.html'), 'utf8')
  .replace('${main_page_url}', 'https://app.example.com/');
const source = terraform.match(/code\s*=\s*<<-JAVASCRIPT\r?\n([\s\S]*?)\r?\n\s*JAVASCRIPT/)[1]
  .replace('${var.base_domain}', 'sites.example.com')
  .replace('${jsonencode(local.not_found_html)}', JSON.stringify(html));
const context = vm.createContext({});
vm.runInContext(source, context);

function route(host, uri = '/', method = 'GET') {
  return context.handler({ request: { headers: { host: { value: host } }, uri, method } });
}

test('valid and nonexistent site names route to their own S3 objects', () => {
  assert.equal(route('cafe.sites.example.com').uri, '/published/cafe/index.html');
  assert.equal(route('nonexistent.sites.example.com').uri, '/published/nonexistent/index.html');
});

test('missing subpaths are preserved for S3 to return 404', () => {
  assert.equal(route('cafe.sites.example.com', '/missing').uri, '/published/cafe/missing');
  assert.equal(route('cafe.sites.example.com', '/missing/').uri, '/published/cafe/missing/index.html');
});

test('invalid site name returns the same HTML with HTTP 404', () => {
  const response = route('-invalid.sites.example.com');
  assert.equal(response.statusCode, 404);
  assert.equal(response.body, html);
  assert.equal(response.headers['content-type'].value, 'text/html; charset=utf-8');
  assert.equal(response.headers['cache-control'].value, 'no-store');
});

test('HEAD error response has no body', () => {
  const response = route('-invalid.sites.example.com', '/', 'HEAD');
  assert.equal(response.statusCode, 404);
  assert.equal(response.body, '');
});

test('unrelated host remains a bad request', () => {
  assert.equal(route('cafe.other.example.com').statusCode, 400);
});

test('rendered function fits the CloudFront 10 KB code limit', () => {
  assert.ok(Buffer.byteLength(source, 'utf8') <= 10240);
});
