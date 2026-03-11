import { Menu, Bell, LogOut, User } from 'lucide-react';
import { useAuthStore } from '@/stores/auth.store';
import { useUIStore } from '@/stores/ui.store';

export function Header() {
  const { user, logout } = useAuthStore();
  const { toggleCollapsed } = useUIStore();

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-gray-200 bg-white px-4 shadow-sm">
      <div className="flex items-center gap-3">
        <button
          onClick={toggleCollapsed}
          className="rounded-md p-1.5 text-gray-500 hover:bg-gray-100 hover:text-gray-700 lg:hidden"
        >
          <Menu size={20} />
        </button>
        <h1 className="text-sm font-semibold" style={{ color: 'var(--color-s4c-blue)' }}>
          Pathfinder
        </h1>
      </div>

      <div className="flex items-center gap-3">
        <button className="relative rounded-md p-1.5 text-gray-500 hover:bg-gray-100 hover:text-gray-700">
          <Bell size={18} />
        </button>

        <div className="flex items-center gap-2 border-l border-gray-200 pl-3">
          <div
            className="flex h-8 w-8 items-center justify-center rounded-full"
            style={{ backgroundColor: 'var(--color-primary-50)', color: 'var(--color-s4c-blue)' }}
          >
            <User size={16} />
          </div>
          <span className="hidden text-sm font-medium text-gray-700 md:block">
            {user?.name ?? 'User'}
          </span>
          <button
            onClick={logout}
            className="rounded-md p-1.5 text-gray-400 hover:bg-gray-100 hover:text-red-500"
            title="Logout"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </header>
  );
}
