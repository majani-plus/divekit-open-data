// Theme switch and sticky-header hairline. Same rules as divekit.app: follow the
// system theme; `?theme=light|dark` is the only override, and the switch writes it.
(() => {
  const root = document.documentElement;
  const urlTheme = () => {
    const t = new URLSearchParams(location.search).get('theme');
    return t === 'light' || t === 'dark' ? t : null;
  };
  const systemDark = matchMedia('(prefers-color-scheme: dark)');
  const effective = () => urlTheme() || (systemDark.matches ? 'dark' : 'light');

  const apply = () => {
    const dark = effective() === 'dark';
    root.classList.toggle('dark', dark);
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#1a1916' : '#f7f6f2');
    document.querySelectorAll('.theme-switch').forEach((el) => el.setAttribute('aria-checked', String(dark)));
  };

  document.querySelectorAll('.theme-switch').forEach((el) =>
    el.addEventListener('click', () => {
      const next = effective() === 'dark' ? 'light' : 'dark';
      const url = new URL(location.href);
      // No param means "match system", so drop it when the choice equals the system theme.
      if (next === (systemDark.matches ? 'dark' : 'light')) url.searchParams.delete('theme');
      else url.searchParams.set('theme', next);
      history.replaceState(null, '', url);
      apply();
    }),
  );
  systemDark.addEventListener('change', () => urlTheme() || apply());
  apply();

  const header = document.querySelector('.site-header');
  const onScroll = () => header?.classList.toggle('scrolled', scrollY > 8);
  addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();
