/**
 * TL1 Assistant - Main App Component
 */
import React, { useEffect, useState } from 'react';
import './App.css';
import { useAppStore } from './state/store';
import { commandsApi } from './api/commands';
import { settingsApi } from './api/settings';
import { sendApi } from './api/send';
import { SystemSelector } from './components/SystemSelector';
import { CategoryList } from './components/CategoryList';
import { CommandList } from './components/CommandList';
import { DynamicForm } from './components/DynamicForm';
import { Preview } from './components/Preview';
import { Console } from './components/Console';

const App: React.FC = () => {
  const {
    selectedPlatform,
    setCommands,
    setCategories,
    settings,
    setSettings,
    preview,
    addConsoleLine,
    setSelectedCommand,
  } = useAppStore();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [host, setHost] = useState('localhost');
  const [port, setPort] = useState(10201);
  const [sending, setSending] = useState(false);

  // Load initial data
  useEffect(() => {
    const loadInitialData = async () => {
      try {
        setLoading(true);
        
        // Load settings
        const settingsData = await settingsApi.get();
        setSettings(settingsData);
        setHost(settingsData.connection.host);
        setPort(settingsData.connection.port);

        // Load commands and categories
        await loadCommandsAndCategories();

        addConsoleLine('[INFO] TL1 Assistant Web UI started');
        setLoading(false);
      } catch (err) {
        console.error('Failed to load initial data:', err);
        setError('Failed to load initial data. Please check the API server.');
        setLoading(false);
      }
    };

    loadInitialData();
  }, []);

  // Reload commands when platform changes
  useEffect(() => {
    if (!loading) {
      loadCommandsAndCategories();
    }
  }, [selectedPlatform]);

  const loadCommandsAndCategories = async () => {
    try {
      const [commandsData, categoriesData] = await Promise.all([
        commandsApi.getAll(selectedPlatform),
        commandsApi.getCategories(selectedPlatform),
      ]);
      
      setCommands(commandsData);
      setCategories(categoriesData);
      setSelectedCommand(null);
      
      addConsoleLine(`[INFO] Loaded ${commandsData.length} commands for ${selectedPlatform}`);
    } catch (err) {
      console.error('Failed to load commands:', err);
      addConsoleLine(`[ERROR] Failed to load commands: ${err}`);
    }
  };

  const handleSend = async () => {
    if (!preview) {
      addConsoleLine('[WARN] No command to send');
      return;
    }

    try {
      setSending(true);
      addConsoleLine('[INFO] Sending command...');
      addConsoleLine(`[SEND] ${preview}`);

      const response = await sendApi.send({
        command: preview,
        host,
        port,
      });

      // Poll for job completion
      let attempts = 0;
      const maxAttempts = 30;
      const pollInterval = 1000;

      const poll = async () => {
        try {
          const jobStatus = await sendApi.getJobStatus(response.job_id);
          
          // Add new output lines
          jobStatus.output.forEach(line => {
            if (!line) return;
            addConsoleLine(line);
          });

          if (jobStatus.completed) {
            addConsoleLine(`[INFO] Command completed with status: ${jobStatus.status}`);
            setSending(false);
            
            // Increment CTAG
            try {
              const ctagData = await settingsApi.incrementCTAG();
              addConsoleLine(`[INFO] CTAG incremented: ${ctagData.nextCTAG}`);
            } catch (e) {
              console.error('Failed to increment CTAG:', e);
            }
          } else if (attempts < maxAttempts) {
            attempts++;
            setTimeout(poll, pollInterval);
          } else {
            addConsoleLine('[WARN] Job polling timeout');
            setSending(false);
          }
        } catch (err) {
          addConsoleLine(`[ERROR] Failed to get job status: ${err}`);
          setSending(false);
        }
      };

      setTimeout(poll, pollInterval);
    } catch (err) {
      console.error('Send failed:', err);
      addConsoleLine(`[ERROR] Send failed: ${err}`);
      setSending(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading TL1 Assistant...</div>;
  }

  if (error) {
    return <div className="error">{error}</div>;
  }

  return (
    <div className="app">
      <header className="header">
        <h1>TL1 Assistant - Web GUI</h1>
        <div className="header-controls">
          <input
            type="text"
            value={host}
            onChange={(e) => setHost(e.target.value)}
            placeholder="Host"
            style={{ width: '150px' }}
          />
          <input
            type="number"
            value={port}
            onChange={(e) => setPort(Number(e.target.value))}
            placeholder="Port"
            style={{ width: '80px' }}
          />
          <button onClick={handleSend} disabled={!preview || sending}>
            {sending ? 'Sending...' : 'Send'}
          </button>
        </div>
      </header>

      <div className="main-container">
        <aside className="sidebar">
          <SystemSelector />
          <CategoryList />
          <CommandList />
        </aside>

        <main className="content">
          <DynamicForm />
          <Preview />
          <Console />
        </main>
      </div>
    </div>
  );
};

export default App;
