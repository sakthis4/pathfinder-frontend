import { PageHeader } from './PageHeader';
import { Construction } from 'lucide-react';

interface PlaceholderPageProps {
  title: string;
  module: string;
}

export function PlaceholderPage({ title, module }: PlaceholderPageProps) {
  return (
    <div>
      <PageHeader title={title} description={`${module} module — coming soon`} />
      <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-white p-12 text-center">
        <Construction className="mb-4 h-12 w-12" style={{ color: 'var(--color-accent)' }} />
        <h2 className="text-lg font-medium" style={{ color: 'var(--color-s4c-blue)' }}>
          Under Construction
        </h2>
        <p className="mt-1 text-sm text-gray-400">
          This page will be implemented in the {module} module phase.
        </p>
      </div>
    </div>
  );
}
