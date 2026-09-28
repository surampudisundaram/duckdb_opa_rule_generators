if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    const swUrl = new URL('./sw.js', window.location.href);
    navigator.serviceWorker
      .register(swUrl, { scope: './' })
      .catch((error) => {
        console.warn('Duck-UI service worker registration failed:', error);
      });
  });
}
