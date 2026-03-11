import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  FolderKanban,
  DollarSign,
  Users,
  Clock,
  Contact,
  CalendarDays,
  FileText,
  Send,
  MessageSquare,
  Target,
  Settings,
  Search,
  UserCheck,
  MessageCircle,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { cn } from '@/utils/cn';
import { useUIStore } from '@/stores/ui.store';

const navItems = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/projects', label: 'Projects', icon: FolderKanban },
  { to: '/finance', label: 'Finance', icon: DollarSign },
  { to: '/hr', label: 'HR', icon: Users },
  { to: '/timesheet', label: 'Timesheet', icon: Clock },
  { to: '/contacts', label: 'Contacts', icon: Contact },
  { to: '/scheduling', label: 'Scheduling', icon: CalendarDays },
  { to: '/files', label: 'Files', icon: FileText },
  { to: '/transmittals', label: 'Transmittals', icon: Send },
  { to: '/feedback', label: 'Feedback', icon: MessageCircle },
  { to: '/messages', label: 'Messages', icon: MessageSquare },
  { to: '/targets', label: 'Targets', icon: Target },
  { to: '/allocation', label: 'Allocation', icon: UserCheck },
  { to: '/reports', label: 'Reports', icon: FileText },
  { to: '/search', label: 'Search', icon: Search },
  { to: '/admin', label: 'Admin', icon: Settings },
];

export function Sidebar() {
  const { sidebarCollapsed, toggleCollapsed } = useUIStore();

  return (
    <aside
      className={cn(
        'fixed left-0 top-0 z-40 h-screen text-white transition-all duration-300',
        sidebarCollapsed ? 'w-16' : 'w-60',
      )}
      style={{ backgroundColor: 'var(--color-sidebar-bg)' }}
    >
      {/* Logo */}
      <div
        className="flex h-16 items-center justify-between border-b px-3"
        style={{ borderColor: 'rgba(255,255,255,0.1)' }}
      >
        {sidebarCollapsed ? (
          <span className="text-sm font-bold text-white">S4</span>
        ) : (
          <img src="/s4-logo-white.png" alt="S4Carlisle" className="h-10" />
        )}
        <button
          onClick={toggleCollapsed}
          className="s4c-sidebar-btn rounded p-1 text-blue-200 hover:text-white"
        >
          {sidebarCollapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
        </button>
      </div>

      {/* Navigation */}
      <nav className="mt-2 flex flex-col gap-0.5 overflow-y-auto px-2" style={{ maxHeight: 'calc(100vh - 64px)' }}>
        {navItems.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                isActive ? 's4c-nav-active' : 's4c-nav-item',
                sidebarCollapsed && 'justify-center px-2',
              )
            }
            title={sidebarCollapsed ? label : undefined}
          >
            <Icon size={18} />
            {!sidebarCollapsed && <span>{label}</span>}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
