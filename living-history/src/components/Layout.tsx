import { NavLink, Outlet, Link, useLocation } from 'react-router-dom';
import { useEffect } from 'react';
import { Hourglass } from 'lucide-react';

const navItems = [
  { to: '/', label: 'Explore', end: true },
  { to: '/method', label: 'Method', end: false },
  { to: '/studio', label: 'Studio', end: false },
];

export default function Layout() {
  const { pathname } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  return (
    <div className="flex min-h-screen flex-col">
      <header className="sticky top-[env(safe-area-inset-top,0px)] z-20 border-b border-ink-800/10 bg-papyrus-50/90 backdrop-blur">
        <div className="container-page flex h-16 items-center justify-between gap-4">
          <Link to="/" className="flex shrink-0 items-center gap-2 text-ink-900">
            <Hourglass className="h-5 w-5 text-ochre-500" aria-hidden />
            <span className="whitespace-nowrap font-display text-lg font-bold sm:text-xl">Living History</span>
          </Link>
          <nav className="flex items-center gap-0.5 text-[13px] sm:gap-2 sm:text-sm">
            {navItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                className={({ isActive }) =>
                  `whitespace-nowrap rounded-md px-2 py-1.5 sm:px-3 ${
                    isActive ? 'bg-ink-900 text-papyrus-50' : 'text-ink-700 hover:bg-ink-800/5'
                  }`
                }
              >
                {item.label}
              </NavLink>
            ))}
          </nav>
        </div>
      </header>

      <main className="flex-1">
        <Outlet />
      </main>

      <footer className="border-t border-ink-800/10 py-8 text-sm text-ink-700">
        <div className="container-page flex flex-col gap-2 sm:flex-row sm:justify-between">
          <p>All images are AI reconstructions based on cited evidence, not photographs.</p>
          <Link to="/method" className="underline underline-offset-4 hover:text-ink-900">
            How we reconstruct the past
          </Link>
        </div>
      </footer>
    </div>
  );
}
