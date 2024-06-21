self.addEventListener('install', function(event) {
	console.log('install');
	event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', async function(event) {
	console.log('activate');
	event.waitUntil(self.clients.claim());
});
