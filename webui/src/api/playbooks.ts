/**
 * Playbooks API
 */
import apiClient from './client';

export interface Playbook {
  id: string;
  name: string;
  description: string;
  steps: any[];
  wizard?: boolean;
}

export interface PlaybooksResponse {
  troubleshooting: Playbook[];
  provisioning: Playbook[];
}

export interface TroubleshootRequest {
  flowName: string;
  TID: string;
  AID: string;
}

export interface ProvisionRequest {
  flowName: string;
  stepState: Record<string, any>;
  TID: string;
}

export const playbooksApi = {
  getAll: async (): Promise<PlaybooksResponse> => {
    const response = await apiClient.get('/playbooks');
    return response.data;
  },

  getById: async (flowName: string): Promise<Playbook> => {
    const response = await apiClient.get(`/playbooks/${flowName}`);
    return response.data;
  },

  troubleshoot: async (request: TroubleshootRequest): Promise<any> => {
    const response = await apiClient.post('/playbooks/troubleshoot', request);
    return response.data;
  },

  provision: async (request: ProvisionRequest): Promise<any> => {
    const response = await apiClient.post('/playbooks/provision', request);
    return response.data;
  },
};
