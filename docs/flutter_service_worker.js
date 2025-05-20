'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "7419bc7faa113b8bbb262ec96c0e3bdf",
"assets/AssetManifest.bin.json": "8eefa3bede488a4d00292d2a660a67b1",
"assets/AssetManifest.json": "e9351a2c1afb936c7b8f496c1a8046e1",
"assets/assets/fonts/Oxanium-VariableFont_wght.ttf": "81de8d6e17fbf408ab24bf57bfd1776e",
"assets/assets/icon/aicon.png": "d3a0c9eea6302bbdfd7c8c56df71e817",
"assets/assets/icon/assistify.png": "fcfda70df3be38bf3ec8459221b14504",
"assets/assets/icon/assistifyicon.png": "44af93179252d5d99d2bd4d894f916cd",
"assets/assets/icon/assistifyLogo.png": "732150117ee8121fd131e2256246a21f",
"assets/assets/icon/background.png": "a2a654249564062d76b8cfe27a70a2b8",
"assets/assets/icon/icona.png": "f5e0dec76f92be30f15aab2e5ffa8a0a",
"assets/assets/icon/icon_splash.png": "1dde1016a445254323c28b3b9d0b541b",
"assets/assets/icon/logoassistify.png": "7bca9dd9d4b205d7f3abbc7b7e45895e",
"assets/assets/images/Acting.png": "be1263077a3fb0cc0c648f47fe573d4b",
"assets/assets/images/artesmarciales.png": "c733f16328727f36786ac24086bf71bd",
"assets/assets/images/Boxing.png": "c63028c4edb4c6a6789e30e5f893c13b",
"assets/assets/images/ceramicagif.gif": "6cfd46a4cb9fa2a9deeca4fa7a98f4c0",
"assets/assets/images/ceramicamujer.gif": "edca0b9f1add565301cb23e8b090a98b",
"assets/assets/images/Cooking.png": "2c92baee067ee3fdcf7a2248dc7c70e5",
"assets/assets/images/CrossFit.png": "04abe92f190d75a41869af923a54e616",
"assets/assets/images/danza.png": "f928a62b63ec99cdc69d4ddd9fb719b9",
"assets/assets/images/Gymnastics.png": "4a23a8dc1f013925f2b83950bb1a68cc",
"assets/assets/images/Languages.png": "e3d8cac80af92be5ad4f33b156253041",
"assets/assets/images/libreta.png": "a55ebc2b55a97af54eba8e3f613ee1f7",
"assets/assets/images/musica.webp": "6ddbb08d2bd3e59d72cf362dd493385a",
"assets/assets/images/natacion.webp": "57fad9be7c6d0d0d740008f4dcfaae1c",
"assets/assets/images/Pilates.png": "83dbc5609168bb259a70a4cf5b67d5c0",
"assets/assets/images/pintura.webp": "366a9b8c869cae136d7e716449f91447",
"assets/assets/images/Tennis.png": "6efb1a18c1cadf943c1846d6999066d1",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.57%2520PM%2520(1).jpeg": "f1b84974932744810607b9b2fd605af2",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.57%2520PM%2520(2).jpeg": "a8596c92b077305972dd1282e3ff7577",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.57%2520PM%2520(3).jpeg": "21a9ebce3a80db2be12cc875b101b378",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.57%2520PM.jpeg": "f1b84974932744810607b9b2fd605af2",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.58%2520PM%2520(1).jpeg": "1c7d491602eb29a5b35d8a6b2e86e1a5",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.58%2520PM.jpeg": "7422318182570bd3e04a2ebe97acef88",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.59%2520PM%2520(1).jpeg": "3495a7d0a0ea8251ea9f1c328d5e74cc",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.59%2520PM%2520(2).jpeg": "5bc340e5aaeea7268ee04ac44b000aff",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.30.59%2520PM.jpeg": "eff5b047f1d99a261fd31ce9209abda3",
"assets/assets/images/WhatsApp%2520Image%25202025-02-02%2520at%252012.31.00%2520PM.jpeg": "c9d9f7bb0121d7941de31b2049c6f84b",
"assets/assets/images/WhatsApp%2520Video%25202025-02-02%2520at%25204.12.38%2520PM.mp4": "4d4d13b660bc7aa1b731c1b657a9ed39",
"assets/assets/onboarding/alumnoacciones.jpeg": "e05226356dc3042115c8f576ef891ad2",
"assets/assets/onboarding/crearclases.jpeg": "56a8686cf834f5edbf1386d40faad8f9",
"assets/assets/onboarding/crearusuarios.jpeg": "2655590d0836daa00bffed08e414d08c",
"assets/assets/onboarding/gestiondehorarios.jpeg": "9bfe9e023d1eb19c68aec3953d0e63d2",
"assets/assets/onboarding/inscripcion.jpeg": "8b33ee8275fdb1413d8e9ad2167a8d31",
"assets/assets/videos/video1.mp4": "0edc276abefb8f9c63f7f9fe8ea6b73c",
"assets/assets/videos/video2.mp4": "304283194473e08398e390142471817a",
"assets/assets/videos/video3.mp4": "c4cd1734ced00e4217ff60e81a48e970",
"assets/FontManifest.json": "53138c14ed6c50541821594117c7d647",
"assets/fonts/MaterialIcons-Regular.otf": "c024869f9e50350ddc7babc0df45f3f5",
"assets/NOTICES": "bf6cc2469b7907f6857933f37d914d11",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "00a0d5a58ed34a52b40eb372392a8b98",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "112614b66790de22b73dba1cf997c1bf",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "64857017d74b506478c9fed97eb72ce0",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "b72b63332efbd4577ae0f20412451aca",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "500379d65ddbb92c369ceb9035944332",
"icons/Icon-192.png": "ac3e9da2ec65e5d8697a149f8a490614",
"icons/Icon-512.png": "a306aa9f735e2bdab9cfe650fe7b1fe9",
"icons/Icon-maskable-192.png": "ac3e9da2ec65e5d8697a149f8a490614",
"icons/Icon-maskable-512.png": "a306aa9f735e2bdab9cfe650fe7b1fe9",
"index.html": "3766b314e2ce961b6db3da1cadbf007d",
"/": "3766b314e2ce961b6db3da1cadbf007d",
"main.dart.js": "62230821af6aec0ac6d7ebc4153aa669",
"manifest.json": "04eca14618c7a79efa1376e83af7c3d4",
"version.json": "7ce24a0ca8fb76e7c3f36cf522793f73"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
