// Elm boot for the eHS Dashboards mock (offline, no network).
//
// The dashboards are entirely self-contained: all figures live in the Elm app
// (see elm/src/Data.elm). The only ports are outgoing — `printPage` opens the
// browser print dialog, and `exportData` is a stub the mock just logs (a real
// build would stream a CSV/PDF here).

(() => {
  'use strict';

  const startElm = (node) => {
    if (!window.Elm || !window.Elm.Main) {
      node.textContent = 'Elm bundle not loaded.';
      return;
    }

    const app = window.Elm.Main.init({ node, flags: {} });

    if (app.ports && app.ports.printPage) {
      app.ports.printPage.subscribe(() => window.print());
    }
    if (app.ports && app.ports.exportData) {
      app.ports.exportData.subscribe((what) => {
        // Mock: a real dashboard would generate and download a file here.
        console.log('[eHS mock] Export requested:', what);
      });
    }
  };

  const boot = () => {
    document.querySelectorAll('[data-dashboards-app]').forEach(startElm);
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
