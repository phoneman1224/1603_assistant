/**
 * Commands API
 */
import apiClient from './client';

export interface Command {
  id: string;
  name: string;
  verb: string;
  object: string;
  modifier: string;
  category: string;
  platform: string[];
  description: string;
  required: string[];
  optional: string[];
  paramSchema: Record<string, any>;
  examples: string[];
  safety_level: string;
  service_affecting: boolean;
  response_format: string;
}

export interface Category {
  name: string;
  description: string;
  icon: string;
  count: number;
}

export interface PreviewRequest {
  id: string;
  TID: string;
  AID: string;
  CTAG: string;
  optional: Record<string, any>;
}

export interface PreviewResponse {
  command: string;
  warnings: string[];
}

export const commandsApi = {
  getAll: async (platform?: string): Promise<Command[]> => {
    const params = platform ? { platform } : {};
    const response = await apiClient.get('/commands', { params });
    return response.data;
  },

  getCategories: async (platform?: string): Promise<Category[]> => {
    const params = platform ? { platform } : {};
    const response = await apiClient.get('/commands/categories', { params });
    return response.data;
  },

  getById: async (id: string): Promise<Command> => {
    const response = await apiClient.get(`/commands/${id}`);
    return response.data;
  },

  preview: async (request: PreviewRequest): Promise<PreviewResponse> => {
    const response = await apiClient.post('/commands/preview', request);
    return response.data;
  },

  reload: async (): Promise<void> => {
    await apiClient.post('/commands/reload');
  },
};
