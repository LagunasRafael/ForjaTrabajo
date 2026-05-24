export interface Conversation {
  id: string;
  request_id: string;
  status: string;
  created_at: string;
  updated_at: string;
  client_name: string;
  worker_name: string;
}

export interface Message {
  id: string;
  sender_id: string;
  sender_name: string;
  content: string;
  message_type: 'text' | 'offer' | 'system' | 'image' | 'gallery' | 'video' | 'audio';
  created_at: string;
}
