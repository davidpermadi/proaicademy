// Zero-dependency static file server for ProAIcademy.
// Usage: node server.js [port]   (default port 3000)
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || process.argv[2] || 3000;
const ROOT = __dirname;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.map': 'application/json; charset=utf-8',
};

const server = http.createServer((req, res) => {
  try {
    let urlPath = decodeURIComponent(req.url.split('?')[0]);
    if (urlPath === '/') urlPath = '/app.html'; // default to the local app entry

    // Prevent path traversal.
    const filePath = path.normalize(path.join(ROOT, urlPath));
    if (!filePath.startsWith(ROOT)) {
      res.writeHead(403);
      return res.end('403 Forbidden');
    }

    fs.stat(filePath, (err, stat) => {
      if (err || !stat.isFile()) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        return res.end('404 Not Found: ' + urlPath);
      }
      const ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, {
        'Content-Type': MIME[ext] || 'application/octet-stream',
        'Cache-Control': 'no-cache',
      });
      fs.createReadStream(filePath).pipe(res);
    });
  } catch (e) {
    res.writeHead(500);
    res.end('500 Server Error');
  }
});

server.listen(PORT, () => {
  console.log(`\n  ProAIcademy running at:  http://localhost:${PORT}\n`);
  console.log(`  Entry points:`);
  console.log(`    http://localhost:${PORT}/            -> app.html (live dc-runtime, offline)`);
  console.log(`    http://localhost:${PORT}/index.html  -> prebuilt self-contained bundle\n`);
  console.log(`  Press Ctrl+C to stop.\n`);
});
