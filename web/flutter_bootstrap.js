{{flutter_js}}
{{flutter_build_config}}

(async () => {
  const loading = document.getElementById('app-loading');
  const status = document.getElementById('app-loading-status');
  const card = document.getElementById('app-loading-card');
  const progress = document.getElementById('app-loading-progress');
  const retry = document.getElementById('app-loading-retry');
  let failed = false;
  const updateStatus = (message) => {
    if (status) status.textContent = message;
  };
  const finishLoading = () => {
    if (
      failed ||
      window.propertyShotBootstrapHasFailed ||
      !loading ||
      loading.classList.contains('is-ready')
    ) return;
    loading.setAttribute('aria-busy', 'false');
    loading.classList.add('is-ready');
    window.setTimeout(() => loading.remove(), 220);
  };
  const failLoading = (error) => {
    failed = true;
    if (window.propertyShotBootstrapFailed) {
      window.propertyShotBootstrapFailed(error);
      return;
    }
    if (loading) loading.setAttribute('aria-busy', 'false');
    if (card) {
      card.setAttribute('role', 'alert');
      card.setAttribute('aria-live', 'assertive');
    }
    if (progress) progress.hidden = true;
    if (retry) retry.hidden = false;
    updateStatus('게임을 불러오지 못했습니다. 다시 시도해 주세요.');
    console.error('Property Shot bootstrap failed', error);
  };

  if (retry) retry.addEventListener('click', () => window.location.reload());

  window.addEventListener(
    'flutter-first-frame',
    () => {
      updateStatus('항해 준비 완료');
      // SkWasm can dispatch the event just before the compositor presents the
      // first scene. Two browser frames plus a short guard prevent a blank seam.
      window.requestAnimationFrame(() => {
        window.requestAnimationFrame(() => window.setTimeout(finishLoading, 120));
      });
    },
    { once: true },
  );

  updateStatus('게임 엔진을 준비하는 중');
  try {
    await _flutter.loader.load({
      onEntrypointLoaded: async (engineInitializer) => {
        try {
          updateStatus('섬과 기록을 불러오는 중');
          const appRunner = await engineInitializer.initializeEngine();
          updateStatus('첫 화면을 그리는 중');
          await appRunner.runApp();
        } catch (error) {
          failLoading(error);
          throw error;
        }
      },
    });
  } catch (error) {
    failLoading(error);
  }
})();
