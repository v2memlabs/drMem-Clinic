export interface InviteRequest {
  mode?: "invite" | "provision" | "resend";
  email?: string;
  display_name?: string;
  login_username?: string;
  role?: string;
  password?: string;
  membership_id?: string;
  redirect_url?: string;
}

export interface InviteResponse {
  ok: boolean;
  error?: string;
  operation_result?: string;
  target_profile_id?: string;
  target_membership_id?: string;
  role?: string;
  status?: string;
}

export interface ResendContext {
  ok: true;
  target_profile_id: string;
  target_membership_id: string;
  auth_user_id: string;
  email: string;
  display_name: string;
  role: string;
  status: string;
}
