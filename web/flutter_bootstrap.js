{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const progressBar = document.getElementById('progress-bar');
    const loadingIndicator = document.getElementById('loading-indicator');

    // 플러터 엔진이 브라우저에 다운로드 완료된 상태 (메인 코드 로드 완료)
    if (progressBar) {
      window.loadingProgress = 90;
      progressBar.style.width = '90%';
    }
    
    // 엔진 초기화 (WebAssembly 컴파일 등)
    const appRunner = await engineInitializer.initializeEngine();
    
    // 앱 실행 준비 완료
    if (progressBar) {
      window.loadingProgress = 100;
      progressBar.style.width = '100%';
    }
    
    // 실제 플러터 앱 실행 (첫 프레임 렌더링)
    await appRunner.runApp();
    
    // 앱 화면이 뜨면 로딩 인디케이터 부드럽게 제거
    if (loadingIndicator) {
      if (window.loadingInterval) clearInterval(window.loadingInterval);
      if (window.progressInterval) clearInterval(window.progressInterval);
      loadingIndicator.style.opacity = '0';
      setTimeout(() => {
        if (loadingIndicator.parentNode) {
          loadingIndicator.remove();
        }
      }, 500); // 0.5초(페이드 아웃) 후 DOM에서 삭제
    }
  }
});
