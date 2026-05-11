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
