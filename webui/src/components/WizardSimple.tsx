/**
 * TL1 Command Wizard Component
 * Orchestrates the System → Category → Command → Form → Preview flow
 */
import React from 'react';
import { useAppStore } from '../state/store';
import { SystemSelector } from './SystemSelector';
import { CategoryList } from './CategoryList';
import { CommandList } from './CommandList';
import { DynamicForm } from './DynamicForm';
import { Preview } from './Preview';

interface WizardProps {
  className?: string;
}

export const Wizard: React.FC<WizardProps> = ({ className = '' }) => {
  const {
    selectedPlatform,
    selectedCategory,
    selectedCommand,
    ctag,
    preview
  } = useAppStore();

  // Determine current step based on selections
  const getCurrentStep = () => {
    if (!selectedPlatform) return 1;
    if (!selectedCategory) return 2;
    if (!selectedCommand) return 3;
    if (!ctag) return 4;
    return 5;
  };

  const currentStep = getCurrentStep();

  const steps = [
    { id: 1, name: 'System', description: 'Select 1603 SM or SMX platform' },
    { id: 2, name: 'Category', description: 'Choose command category' },
    { id: 3, name: 'Command', description: 'Pick specific TL1 command' },
    { id: 4, name: 'Parameters', description: 'Enter TID, AID, CTAG, and options' },
    { id: 5, name: 'Preview', description: 'Review and send command' },
  ];

  return (
    <div className={`wizard ${className}`} style={{ display: 'flex', flexDirection: 'column', height: '100%', background: '#f8f9fa' }}>
      {/* Step Progress Indicator */}
      <div style={{ background: 'white', borderBottom: '1px solid #e9ecef', padding: '1rem' }}>
        <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
          <h2 style={{ margin: 0, color: '#2c3e50' }}>TL1 Command Wizard</h2>
          <p style={{ margin: '0.25rem 0 0 0', color: '#6c757d' }}>Build and send TL1 commands step by step</p>
        </div>
        
        <div style={{ display: 'flex', justifyContent: 'center', gap: '1rem', flexWrap: 'wrap' }}>
          {steps.map((step) => (
            <div
              key={step.id}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                padding: '0.5rem',
                borderRadius: '0.5rem',
                background: step.id === currentStep ? '#007bff' : step.id < currentStep ? '#28a745' : '#e9ecef',
                color: step.id <= currentStep ? 'white' : '#6c757d'
              }}
            >
              <div style={{
                width: '2rem',
                height: '2rem',
                borderRadius: '50%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 'bold',
                fontSize: '0.875rem',
                background: 'rgba(255, 255, 255, 0.2)'
              }}>
                {step.id}
              </div>
              <div>
                <h4 style={{ margin: 0, fontSize: '0.875rem' }}>{step.name}</h4>
                <p style={{ margin: 0, fontSize: '0.75rem', opacity: 0.8 }}>{step.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Step Content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <div style={{ display: 'flex', flex: 1, gap: '1rem', padding: '1rem', overflow: 'hidden' }}>
          {/* Left Panel - Navigation */}
          <div style={{
            flex: 1,
            minWidth: '300px',
            background: 'white',
            borderRadius: '0.5rem',
            padding: '1rem',
            boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
            overflowY: 'auto'
          }}>
            <div style={{ marginBottom: '1.5rem' }}>
              <h3 style={{ margin: '0 0 0.5rem 0', color: '#2c3e50', fontSize: '1.1rem' }}>1. System Platform</h3>
              <SystemSelector />
              {selectedPlatform && (
                <div style={{
                  marginTop: '0.5rem',
                  padding: '0.5rem',
                  background: '#d4edda',
                  color: '#155724',
                  borderRadius: '0.25rem',
                  fontSize: '0.875rem'
                }}>
                  ✓ Selected: {selectedPlatform}
                </div>
              )}
            </div>

            {selectedPlatform && (
              <div style={{ marginBottom: '1.5rem' }}>
                <h3 style={{ margin: '0 0 0.5rem 0', color: '#2c3e50', fontSize: '1.1rem' }}>2. Command Category</h3>
                <CategoryList />
                {selectedCategory && (
                  <div style={{
                    marginTop: '0.5rem',
                    padding: '0.5rem',
                    background: '#d4edda',
                    color: '#155724',
                    borderRadius: '0.25rem',
                    fontSize: '0.875rem'
                  }}>
                    ✓ Selected: {selectedCategory}
                  </div>
                )}
              </div>
            )}

            {selectedCategory && (
              <div style={{ marginBottom: '1.5rem' }}>
                <h3 style={{ margin: '0 0 0.5rem 0', color: '#2c3e50', fontSize: '1.1rem' }}>3. TL1 Command</h3>
                <CommandList />
                {selectedCommand && (
                  <div style={{
                    marginTop: '0.5rem',
                    padding: '0.5rem',
                    background: '#d4edda',
                    color: '#155724',
                    borderRadius: '0.25rem',
                    fontSize: '0.875rem'
                  }}>
                    ✓ Selected: {selectedCommand.id}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Right Panel - Form and Preview */}
          <div style={{
            flex: 1.5,
            minWidth: '400px',
            background: 'white',
            borderRadius: '0.5rem',
            padding: '1rem',
            boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
            overflowY: 'auto'
          }}>
            {selectedCommand && (
              <>
                <div style={{ marginBottom: '1.5rem' }}>
                  <h3 style={{ margin: '0 0 0.5rem 0', color: '#2c3e50', fontSize: '1.1rem' }}>4. Command Parameters</h3>
                  <div style={{
                    marginBottom: '1rem',
                    padding: '1rem',
                    background: '#f8f9fa',
                    borderRadius: '0.25rem'
                  }}>
                    <h4 style={{ margin: '0 0 0.25rem 0', color: '#2c3e50' }}>{selectedCommand.id}</h4>
                    <p style={{ margin: 0, color: '#6c757d' }}>{selectedCommand.description}</p>
                    
                    {selectedCommand.service_affecting && (
                      <div style={{
                        marginTop: '0.5rem',
                        padding: '0.5rem',
                        background: '#fff3cd',
                        color: '#856404',
                        border: '1px solid #ffeeba',
                        borderRadius: '0.25rem',
                        fontWeight: 'bold'
                      }}>
                        ⚠️ WARNING: This command is service-affecting!
                      </div>
                    )}
                    
                    {selectedCommand.safety_level !== 'safe' && (
                      <div style={{
                        marginTop: '0.5rem',
                        padding: '0.5rem',
                        background: selectedCommand.safety_level === 'dangerous' ? '#f8d7da' : '#fff3cd',
                        color: selectedCommand.safety_level === 'dangerous' ? '#721c24' : '#856404',
                        border: selectedCommand.safety_level === 'dangerous' ? '1px solid #f1b0b7' : '1px solid #ffeeba',
                        borderRadius: '0.25rem',
                        fontWeight: 'bold'
                      }}>
                        🛡️ Safety Level: {selectedCommand.safety_level.toUpperCase()}
                      </div>
                    )}
                  </div>
                  
                  <DynamicForm />
                </div>

                {ctag && (
                  <div style={{ marginBottom: '1.5rem' }}>
                    <h3 style={{ margin: '0 0 0.5rem 0', color: '#2c3e50', fontSize: '1.1rem' }}>5. Command Preview</h3>
                    <Preview />
                    
                    {preview && (
                      <div style={{ marginTop: '1rem' }}>
                        <div style={{
                          padding: '0.5rem',
                          background: '#d4edda',
                          color: '#155724',
                          borderRadius: '0.25rem',
                          fontWeight: 'bold'
                        }}>
                          ✓ Command ready to send
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </>
            )}
          </div>
        </div>

        {/* Help Section */}
        <div style={{
          background: 'white',
          borderTop: '1px solid #e9ecef',
          padding: '1rem',
          margin: '1rem',
          marginBottom: 0,
          borderRadius: '0.5rem'
        }}>
          <h4 style={{ margin: '0 0 0.5rem 0', color: '#2c3e50' }}>💡 Tips</h4>
          <ul style={{ margin: 0, paddingLeft: '1.5rem' }}>
            <li style={{ marginBottom: '0.25rem', color: '#6c757d' }}>
              <strong style={{ color: '#2c3e50' }}>TID:</strong> Target identifier (optional for most commands)
            </li>
            <li style={{ marginBottom: '0.25rem', color: '#6c757d' }}>
              <strong style={{ color: '#2c3e50' }}>AID:</strong> Access identifier (depends on command)
            </li>
            <li style={{ marginBottom: '0.25rem', color: '#6c757d' }}>
              <strong style={{ color: '#2c3e50' }}>CTAG:</strong> Correlation tag (required, auto-increments)
            </li>
            <li style={{ marginBottom: '0.25rem', color: '#6c757d' }}>
              <strong style={{ color: '#2c3e50' }}>Safety:</strong> Review warnings before sending service-affecting commands
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default Wizard;