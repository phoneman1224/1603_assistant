/**
 * Global State Management with Zustand
 */
import { create } from 'zustand';
import { Command, Category } from '../api/commands';
import { Settings } from '../api/settings';

interface AppState {
  // System selection
  selectedPlatform: string;
  setSelectedPlatform: (platform: string) => void;

  // Commands
  commands: Command[];
  categories: Category[];
  selectedCategory: string | null;
  selectedCommand: Command | null;
  setCommands: (commands: Command[]) => void;
  setCategories: (categories: Category[]) => void;
  setSelectedCategory: (category: string | null) => void;
  setSelectedCommand: (command: Command | null) => void;

  // Command builder
  tid: string;
  aid: string;
  ctag: string;
  optionalParams: Record<string, any>;
  preview: string;
  warnings: string[];
  setTID: (tid: string) => void;
  setAID: (aid: string) => void;
  setCTAG: (ctag: string) => void;
  setOptionalParams: (params: Record<string, any>) => void;
  setPreview: (preview: string, warnings: string[]) => void;

  // Console
  consoleLines: string[];
  addConsoleLine: (line: string) => void;
  clearConsole: () => void;

  // Settings
  settings: Settings | null;
  setSettings: (settings: Settings) => void;

  // Connection
  isConnected: boolean;
  setIsConnected: (connected: boolean) => void;
}

export const useAppStore = create<AppState>((set) => ({
  // System selection
  selectedPlatform: '1603 SM',
  setSelectedPlatform: (platform) => set({ selectedPlatform: platform }),

  // Commands
  commands: [],
  categories: [],
  selectedCategory: null,
  selectedCommand: null,
  setCommands: (commands) => set({ commands }),
  setCategories: (categories) => set({ categories }),
  setSelectedCategory: (category) => set({ selectedCategory: category }),
  setSelectedCommand: (command) => set({ selectedCommand: command }),

  // Command builder
  tid: '',
  aid: '',
  ctag: '1',
  optionalParams: {},
  preview: '',
  warnings: [],
  setTID: (tid) => set({ tid }),
  setAID: (aid) => set({ aid }),
  setCTAG: (ctag) => set({ ctag }),
  setOptionalParams: (params) => set({ optionalParams: params }),
  setPreview: (preview, warnings) => set({ preview, warnings }),

  // Console
  consoleLines: [],
  addConsoleLine: (line) =>
    set((state) => ({
      consoleLines: [...state.consoleLines, line].slice(-1000), // Keep last 1000 lines
    })),
  clearConsole: () => set({ consoleLines: [] }),

  // Settings
  settings: null,
  setSettings: (settings) => set({ settings }),

  // Connection
  isConnected: false,
  setIsConnected: (connected) => set({ isConnected: connected }),
}));
