/**
 * Settings API
 */
import apiClient from './client';

export interface Settings {
  connection: {
    host: string;
    port: number;
    timeout: number;
  };
  defaults: {
    lastTID: string;
    lastAID: string;
    nextCTAG: number;
    platform: string;
  };
  logging: {
    logRoot: string;
    debugMode: boolean;
    rotationEnabled: boolean;
  };
  ui: {
    theme: string;
    autoConnect: boolean;
  };
}

export const settingsApi = {
  get: async (): Promise<Settings> => {
    const response = await apiClient.get('/settings');
    return response.data;
  },

  update: async (settings: Settings): Promise<void> => {
    await apiClient.put('/settings', settings);
  },

  incrementCTAG: async (): Promise<{ currentCTAG: number; nextCTAG: number }> => {
    const response = await apiClient.post('/settings/ctag/increment');
    return response.data;
  },
};
