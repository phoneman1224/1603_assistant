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
import './Wizard.css';

interface WizardProps {
  className?: string;
}

export const Wizard: React.FC<WizardProps> = ({ className = '' }) => {
  const {
    selectedPlatform,
    selectedCategory,
    selectedCommand,
    tid,
    aid,
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
    <div className={`wizard ${className}`}>
      {/* Step Progress Indicator */}
      <div className="wizard-steps">
        <div className="step-header">
          <h2>TL1 Command Wizard</h2>
          <p>Build and send TL1 commands step by step</p>
        </div>
        
        <div className="step-progress">
          {steps.map((step) => (
            <div
              key={step.id}
              className={`step ${
                step.id === currentStep ? 'active' : 
                step.id < currentStep ? 'completed' : 'pending'
              }`}
            >
              <div className="step-number">{step.id}</div>
              <div className="step-content">
                <h4>{step.name}</h4>
                <p>{step.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Step Content */}
      <div className="wizard-content">
        <div className="wizard-panels">
          {/* Left Panel - Navigation */}
          <div className={`wizard-panel selection-panel ${currentStep <= 3 ? 'active' : ''}`}>
            <div className="panel-section">
              <h3>1. System Platform</h3>
              <SystemSelector />
              {selectedPlatform && (
                <div className="selection-status">
                  ✓ Selected: {selectedPlatform}
                </div>
              )}
            </div>

            {selectedPlatform && (
              <div className="panel-section">
                <h3>2. Command Category</h3>
                <CategoryList />
                {selectedCategory && (
                  <div className="selection-status">
                    ✓ Selected: {selectedCategory}
                  </div>
                )}
              </div>
            )}

            {selectedCategory && (
              <div className="panel-section">
                <h3>3. TL1 Command</h3>
                <CommandList />
                {selectedCommand && (
                  <div className="selection-status">
                    ✓ Selected: {selectedCommand.id}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Right Panel - Form and Preview */}
          <div className={`wizard-panel form-panel ${currentStep >= 4 ? 'active' : ''}`}>
            {selectedCommand && (
              <>
                <div className="panel-section">
                  <h3>4. Command Parameters</h3>
                  <div className="command-info">
                    <h4>{selectedCommand.id}</h4>
                    <p>{selectedCommand.description}</p>
                    
                    {selectedCommand.service_affecting && (
                      <div className="warning-banner">
                        ⚠️ WARNING: This command is service-affecting!
                      </div>
                    )}
                    
                    {selectedCommand.safety_level !== 'safe' && (
                      <div className={`safety-banner safety-${selectedCommand.safety_level}`}>
                        🛡️ Safety Level: {selectedCommand.safety_level.toUpperCase()}
                      </div>
                    )}
                  </div>
                  
                  <DynamicForm />
                </div>

                {ctag && (
                  <div className="panel-section">
                    <h3>5. Command Preview</h3>
                    <Preview />
                    
                    {preview && (
                      <div className="preview-actions">
                        <div className="preview-status">
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
        <div className="wizard-help">
          <h4>💡 Tips</h4>
          <ul>
            <li><strong>TID:</strong> Target identifier (optional for most commands)</li>
            <li><strong>AID:</strong> Access identifier (depends on command)</li>
            <li><strong>CTAG:</strong> Correlation tag (required, auto-increments)</li>
            <li><strong>Safety:</strong> Review warnings before sending service-affecting commands</li>
          </ul>
        </div>
      </div>

      <style jsx>{`
        .wizard {
          display: flex;
          flex-direction: column;
          height: 100%;
          background: #f8f9fa;
        }

        .wizard-steps {
          background: white;
          border-bottom: 1px solid #e9ecef;
          padding: 1rem;
        }

        .step-header {
          text-align: center;
          margin-bottom: 1rem;
        }

        .step-header h2 {
          margin: 0;
          color: #2c3e50;
        }

        .step-header p {
          margin: 0.25rem 0 0 0;
          color: #6c757d;
        }

        .step-progress {
          display: flex;
          justify-content: center;
          gap: 1rem;
          flex-wrap: wrap;
        }

        .step {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          padding: 0.5rem;
          border-radius: 0.5rem;
          transition: all 0.2s;
        }

        .step.active {
          background: #007bff;
          color: white;
        }

        .step.completed {
          background: #28a745;
          color: white;
        }

        .step.pending {
          background: #e9ecef;
          color: #6c757d;
        }

        .step-number {
          width: 2rem;
          height: 2rem;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          font-size: 0.875rem;
          background: rgba(255, 255, 255, 0.2);
        }

        .step-content h4 {
          margin: 0;
          font-size: 0.875rem;
        }

        .step-content p {
          margin: 0;
          font-size: 0.75rem;
          opacity: 0.8;
        }

        .wizard-content {
          flex: 1;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        .wizard-panels {
          display: flex;
          flex: 1;
          gap: 1rem;
          padding: 1rem;
          overflow: hidden;
        }

        .wizard-panel {
          background: white;
          border-radius: 0.5rem;
          padding: 1rem;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          overflow-y: auto;
        }

        .selection-panel {
          flex: 1;
          min-width: 300px;
        }

        .form-panel {
          flex: 1.5;
          min-width: 400px;
        }

        .panel-section {
          margin-bottom: 1.5rem;
        }

        .panel-section h3 {
          margin: 0 0 0.5rem 0;
          color: #2c3e50;
          font-size: 1.1rem;
        }

        .selection-status {
          margin-top: 0.5rem;
          padding: 0.5rem;
          background: #d4edda;
          color: #155724;
          border-radius: 0.25rem;
          font-size: 0.875rem;
        }

        .command-info {
          margin-bottom: 1rem;
          padding: 1rem;
          background: #f8f9fa;
          border-radius: 0.25rem;
        }

        .command-info h4 {
          margin: 0 0 0.25rem 0;
          color: #2c3e50;
        }

        .command-info p {
          margin: 0;
          color: #6c757d;
        }

        .warning-banner {
          margin-top: 0.5rem;
          padding: 0.5rem;
          background: #fff3cd;
          color: #856404;
          border: 1px solid #ffeeba;
          border-radius: 0.25rem;
          font-weight: bold;
        }

        .safety-banner {
          margin-top: 0.5rem;
          padding: 0.5rem;
          border-radius: 0.25rem;
          font-weight: bold;
        }

        .safety-caution {
          background: #fff3cd;
          color: #856404;
          border: 1px solid #ffeeba;
        }

        .safety-dangerous {
          background: #f8d7da;
          color: #721c24;
          border: 1px solid #f1b0b7;
        }

        .preview-actions {
          margin-top: 1rem;
        }

        .preview-status {
          padding: 0.5rem;
          background: #d4edda;
          color: #155724;
          border-radius: 0.25rem;
          font-weight: bold;
        }

        .wizard-help {
          background: white;
          border-top: 1px solid #e9ecef;
          padding: 1rem;
          margin: 1rem;
          margin-bottom: 0;
          border-radius: 0.5rem;
        }

        .wizard-help h4 {
          margin: 0 0 0.5rem 0;
          color: #2c3e50;
        }

        .wizard-help ul {
          margin: 0;
          padding-left: 1.5rem;
        }

        .wizard-help li {
          margin-bottom: 0.25rem;
          color: #6c757d;
        }

        .wizard-help strong {
          color: #2c3e50;
        }

        @media (max-width: 768px) {
          .wizard-panels {
            flex-direction: column;
          }
          
          .step-progress {
            flex-direction: column;
            align-items: center;
          }
        }
      `}</style>
    </div>
  );
};

export default Wizard;