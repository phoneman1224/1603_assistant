/**
 * Send API
 */
import apiClient from './client';

export interface SendRequest {
  command: string;
  host: string;
  port: number;
}

export interface SendResponse {
  job_id: string;
  status: string;
  message: string;
}

export interface JobStatus {
  id: string;
  status: string;
  output: string[];
  completed: boolean;
}

export const sendApi = {
  send: async (request: SendRequest): Promise<SendResponse> => {
    const response = await apiClient.post('/send', request);
    return response.data;
  },

  getJobStatus: async (jobId: string): Promise<JobStatus> => {
    const response = await apiClient.get(`/send/jobs/${jobId}`);
    return response.data;
  },

  deleteJob: async (jobId: string): Promise<void> => {
    await apiClient.delete(`/send/jobs/${jobId}`);
  },
};
