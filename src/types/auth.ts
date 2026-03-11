export interface User {
  id: number;
  email: string;
  name: string;
  role: string;
  employeeCode: string;
  department: string | null;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface LoginResponse {
  user: User;
  accessToken: string;
  refreshToken: string;
  forcePasswordChange: boolean;
}
