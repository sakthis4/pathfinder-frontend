import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/auth.store';
import api from '@/services/api';
import type { ApiResponse } from '@/types/api';
import type { LoginResponse } from '@/types/auth';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { setUser } = useAuthStore();

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const { data: res } = await api.post<ApiResponse<LoginResponse>>('/auth/login', {
        email,
        password,
      });

      if (res.success) {
        setUser(res.data.user, res.data.accessToken, res.data.refreshToken);
        navigate('/');
      }
    } catch (err: unknown) {
      const axiosErr = err as {
        response?: {
          data?: {
            error?: {
              message?: string;
              details?: Array<{ field: string; message: string }>;
            };
          };
        };
      };
      const apiError = axiosErr.response?.data?.error;
      if (apiError?.details?.length) {
        setError(apiError.details.map((d) => d.message).join('. '));
      } else {
        setError(apiError?.message ?? 'Login failed');
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="s4c-login-bg flex min-h-screen items-center justify-center">
      <div className="w-full max-w-sm rounded-lg bg-white p-8 shadow-xl">
        <div className="mb-6 text-center">
          <img src="/s4-logo.png" alt="S4Carlisle" className="mx-auto mb-3 h-10" />
          <h1 className="text-2xl font-bold" style={{ color: 'var(--color-s4c-blue)' }}>
            Pathfinder
          </h1>
          <p className="mt-1 text-sm text-gray-500">Sign in to your account</p>
        </div>

        <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
          {error && (
            <div className="rounded-md bg-red-50 p-3 text-sm text-red-600">{error}</div>
          )}

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="s4c-input mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm"
              placeholder="you@example.com"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700">
              Password
            </label>
            <input
              id="password"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="s4c-input mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="s4c-btn-primary w-full rounded-md px-4 py-2.5 text-sm font-semibold text-white shadow-sm disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
