import api from '../../../api/client';
import type { Conversation, Message } from '../types/dispute.types';

export const getConversationsApi = async (): Promise<Conversation[]> => {
  const { data } = await api.get<Conversation[]>('/services/admin/conversations/all');
  return data;
};

export const getConversationMessagesApi = async (id: string): Promise<Message[]> => {
  const { data } = await api.get<Message[]>(`/services/admin/conversations/${id}/messages`);
  return data;
};

export const sendAdminMessageApi = async (id: string, content: string): Promise<void> => {
  await api.post(`/services/admin/chat/${id}/message`, { content });
};

export const resolveDisputeApi = async (id: string, winnerRole: 'client' | 'worker'): Promise<void> => {
  await api.post(`/services/admin/chat/${id}/resolve`, { winner_role: winnerRole });
};
