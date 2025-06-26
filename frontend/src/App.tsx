import React, { useState, useEffect } from 'react';
import './index.css';

interface Project {
  id: string;
  name: string;
  status: 'created' | 'configured' | 'running' | 'completed' | 'failed';
  created: string;
  files: ProjectFile[];
  forcefield?: string;
  config?: SimulationConfig;
}

interface ProjectFile {
  name: string;
  type: string;
  size: number;
  uploadedAt: string;
}

interface SimulationConfig {
  temperature: number;
  pressure: number;
  timeStep: number;
  totalTime: number;
  forcefield: string;
}

interface ApiStatus {
  status: 'checking' | 'connected' | 'disconnected';
  message: string;
}

type CurrentView = 'dashboard' | 'upload' | 'configure' | 'simulation' | 'analysis';

const FORCEFIELDS = [
  { id: 'amber99sb-ildn', name: 'AMBER99SB-ILDN', description: 'Protein force field with improved dihedral parameters' },
  { id: 'charmm36-jul2022', name: 'CHARMM36', description: 'Latest CHARMM36 all-atom force field' },
  { id: 'gromos54a7', name: 'GROMOS 54A7', description: 'United-atom force field' },
  { id: 'oplsaa', name: 'OPLS-AA', description: 'All-atom optimized potentials for liquid simulations' },
];

function App() {
  const [currentView, setCurrentView] = useState<CurrentView>('dashboard');
  const [selectedProject, setSelectedProject] = useState<string | null>(null);
  const [projects, setProjects] = useState<Project[]>([
    { 
      id: '1', 
      name: 'Example Protein Study', 
      status: 'completed',
      created: '2025-06-26',
      files: [
        { name: 'protein.pdb', type: '.pdb', size: 125000, uploadedAt: '2025-06-26' },
        { name: 'topology.top', type: '.top', size: 15000, uploadedAt: '2025-06-26' }
      ],
      forcefield: 'amber99sb-ildn',
      config: {
        temperature: 300,
        pressure: 1.0,
        timeStep: 0.002,
        totalTime: 10,
        forcefield: 'amber99sb-ildn'
      }
    },
    { 
      id: '2', 
      name: 'Ligand Binding Analysis', 
      status: 'created',
      created: '2025-06-26',
      files: []
    }
  ]);

  const [apiStatus, setApiStatus] = useState<ApiStatus>({
    status: 'checking',
    message: 'Checking connection...'
  });

  // Test backend connection
  useEffect(() => {
    const checkBackend = async () => {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);
        
        const response = await fetch('http://localhost:8000/', {
          signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (response.ok) {
          setApiStatus({
            status: 'connected',
            message: 'Backend connected successfully'
          });
        } else {
          setApiStatus({
            status: 'disconnected',
            message: `Backend error: ${response.status}`
          });
        }
      } catch (error) {
        setApiStatus({
          status: 'disconnected',
          message: 'Backend not responding'
        });
      }
    };

    checkBackend();
    const interval = setInterval(checkBackend, 30000);
    return () => clearInterval(interval);
  }, []);

  const createProject = () => {
    const newProject: Project = {
      id: Date.now().toString(),
      name: `Project ${projects.length + 1}`,
      status: 'created',
      created: new Date().toISOString().split('T')[0],
      files: []
    };
    setProjects([newProject, ...projects]);
    setSelectedProject(newProject.id);
    setCurrentView('upload');
  };

  const deleteProject = (id: string) => {
    if (window.confirm('Are you sure you want to delete this project?')) {
      setProjects(projects.filter(p => p.id !== id));
      if (selectedProject === id) {
        setSelectedProject(null);
        setCurrentView('dashboard');
      }
    }
  };

  const selectProject = (id: string) => {
    setSelectedProject(id);
    const project = projects.find(p => p.id === id);
    if (project) {
      if (project.files.length === 0) {
        setCurrentView('upload');
      } else if (!project.forcefield) {
        setCurrentView('configure');
      } else {
        setCurrentView('simulation');
      }
    }
  };

  const simulateFileUpload = (projectId: string, fileName: string, fileType: string) => {
    const newFile: ProjectFile = {
      name: fileName,
      type: fileType,
      size: Math.floor(Math.random() * 100000) + 10000,
      uploadedAt: new Date().toISOString().split('T')[0]
    };

    setProjects(projects.map(p => 
      p.id === projectId 
        ? { ...p, files: [...p.files, newFile] }
        : p
    ));
  };

  const updateProjectForcefield = (projectId: string, forcefield: string) => {
    setProjects(projects.map(p => 
      p.id === projectId 
        ? { ...p, forcefield, status: 'configured' as const }
        : p
    ));
  };

  const startSimulation = (projectId: string) => {
    setProjects(projects.map(p => 
      p.id === projectId 
        ? { ...p, status: 'running' as const }
        : p
    ));
    
    // Simulate completion after 5 seconds
    setTimeout(() => {
      setProjects(prev => prev.map(p => 
        p.id === projectId 
          ? { ...p, status: 'completed' as const }
          : p
      ));
    }, 5000);
  };

  const getStatsCount = (status: string) => {
    return projects.filter(p => p.status === status).length;
  };

  const getCurrentProject = () => {
    return selectedProject ? projects.find(p => p.id === selectedProject) : null;
  };

  const renderNavigation = () => (
    <nav className="navigation">
      <div className="nav-items">
        <button 
          className={`nav-item ${currentView === 'dashboard' ? 'active' : ''}`}
          onClick={() => setCurrentView('dashboard')}
        >
          📊 Dashboard
        </button>
        {selectedProject && (
          <>
            <button 
              className={`nav-item ${currentView === 'upload' ? 'active' : ''}`}
              onClick={() => setCurrentView('upload')}
            >
              📁 File Upload
            </button>
            <button 
              className={`nav-item ${currentView === 'configure' ? 'active' : ''}`}
              onClick={() => setCurrentView('configure')}
            >
              ⚙️ Configure
            </button>
            <button 
              className={`nav-item ${currentView === 'simulation' ? 'active' : ''}`}
              onClick={() => setCurrentView('simulation')}
            >
              ▶️ Simulation
            </button>
            <button 
              className={`nav-item ${currentView === 'analysis' ? 'active' : ''}`}
              onClick={() => setCurrentView('analysis')}
            >
              📈 Analysis
            </button>
          </>
        )}
      </div>
      {selectedProject && (
        <div className="current-project">
          Current: {getCurrentProject()?.name}
        </div>
      )}
    </nav>
  );

  const renderDashboard = () => (
    <div>
      {/* Welcome Section */}
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold mb-2">
          Molecular Dynamics Simulation Platform
        </h2>
        <p className="text-lg" style={{ color: '#64748b' }}>
          A modern web interface for GROMACS simulations
        </p>
      </div>

      {/* Stats Cards */}
      <div className="card-grid">
        <div className="card text-center">
          <div className="text-2xl font-bold" style={{ color: '#3b82f6' }}>
            {projects.length}
          </div>
          <div>Total Projects</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold" style={{ color: '#10b981' }}>
            {getStatsCount('completed')}
          </div>
          <div>Completed</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold" style={{ color: '#f59e0b' }}>
            {getStatsCount('running')}
          </div>
          <div>Running</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold" style={{ color: '#6b7280' }}>
            {getStatsCount('created')}
          </div>
          <div>Ready</div>
        </div>
      </div>

      {/* Action Button */}
      <div className="text-center mb-4">
        <button onClick={createProject} className="btn btn-primary">
          ➕ Create New Project
        </button>
      </div>

      {/* Projects List */}
      <div className="card">
        <h3 className="text-lg font-bold mb-4">
          Projects ({projects.length})
        </h3>
        
        {projects.length === 0 ? (
          <div className="text-center" style={{ padding: '2rem', color: '#64748b' }}>
            No projects yet. Create your first project to get started!
          </div>
        ) : (
          <div>
            {projects.map((project) => (
              <div key={project.id} className="project-item">
                <div>
                  <div className="font-bold">{project.name}</div>
                  <div style={{ fontSize: '0.875rem', color: '#64748b' }}>
                    Created: {project.created} • Files: {project.files.length} • ID: {project.id}
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span className={`status-badge status-${project.status}`}>
                    {project.status.toUpperCase()}
                  </span>
                  <button 
                    onClick={() => selectProject(project.id)}
                    className="btn btn-sm"
                  >
                    📂 Open
                  </button>
                  <button 
                    onClick={() => deleteProject(project.id)}
                    className="btn btn-sm btn-danger"
                  >
                    🗑 Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );

  const renderFileUpload = () => {
    const project = getCurrentProject();
    if (!project) return <div>No project selected</div>;

    return (
      <div>
        <h2 className="text-2xl font-bold mb-4">📁 File Upload - {project.name}</h2>
        
        <div className="card mb-4">
          <h3 className="text-lg font-bold mb-4">Upload Files</h3>
          
          <div className="upload-area">
            <div className="upload-box">
              <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>📁</div>
              <h4>Drag & drop files here or click to browse</h4>
              <p style={{ color: '#64748b', marginTop: '0.5rem' }}>
                Supported formats: .pdb, .gro, .mol2, .sdf, .itp, .top, .mdp
              </p>
              <div style={{ marginTop: '1rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap', justifyContent: 'center' }}>
                <button 
                  onClick={() => simulateFileUpload(project.id, 'protein.pdb', '.pdb')}
                  className="btn btn-sm"
                >
                  + Add PDB File
                </button>
                <button 
                  onClick={() => simulateFileUpload(project.id, 'ligand.mol2', '.mol2')}
                  className="btn btn-sm"
                >
                  + Add Ligand
                </button>
                <button 
                  onClick={() => simulateFileUpload(project.id, 'topology.top', '.top')}
                  className="btn btn-sm"
                >
                  + Add Topology
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* File List */}
        {project.files.length > 0 && (
          <div className="card">
            <h3 className="text-lg font-bold mb-4">Uploaded Files ({project.files.length})</h3>
            <div>
              {project.files.map((file, index) => (
                <div key={index} className="file-item">
                  <div className="flex items-center gap-4">
                    <div style={{ fontSize: '1.5rem' }}>
                      {file.type === '.pdb' ? '🧬' : 
                       file.type === '.mol2' ? '💊' : 
                       file.type === '.top' ? '📋' : '📄'}
                    </div>
                    <div>
                      <div className="font-bold">{file.name}</div>
                      <div style={{ fontSize: '0.875rem', color: '#64748b' }}>
                        {file.type} • {(file.size / 1024).toFixed(1)} KB • {file.uploadedAt}
                      </div>
                    </div>
                  </div>
                  <span className={`file-type-badge file-type-${file.type.substring(1)}`}>
                    {file.type}
                  </span>
                </div>
              ))}
            </div>
            
            {project.files.length > 0 && (
              <div style={{ marginTop: '1rem', textAlign: 'center' }}>
                <button 
                  onClick={() => setCurrentView('configure')}
                  className="btn btn-primary"
                >
                  ⚙️ Configure System →
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    );
  };

  const renderConfigure = () => {
    const project = getCurrentProject();
    if (!project) return <div>No project selected</div>;

    return (
      <div>
        <h2 className="text-2xl font-bold mb-4">⚙️ System Configuration - {project.name}</h2>
        
        {/* Force Field Selection */}
        <div className="card mb-4">
          <h3 className="text-lg font-bold mb-4">Force Field Selection</h3>
          <p style={{ color: '#64748b', marginBottom: '1rem' }}>
            Choose the appropriate force field for your molecular system:
          </p>
          
          <div className="forcefield-grid">
            {FORCEFIELDS.map((ff) => (
              <div 
                key={ff.id} 
                className={`forcefield-card ${project.forcefield === ff.id ? 'selected' : ''}`}
                onClick={() => updateProjectForcefield(project.id, ff.id)}
              >
                <div className="font-bold">{ff.name}</div>
                <div style={{ fontSize: '0.875rem', color: '#64748b', marginTop: '0.5rem' }}>
                  {ff.description}
                </div>
                {project.forcefield === ff.id && (
                  <div style={{ marginTop: '0.5rem', color: '#10b981', fontSize: '0.875rem' }}>
                    ✅ Selected
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* System Parameters */}
        <div className="card mb-4">
          <h3 className="text-lg font-bold mb-4">Simulation Parameters</h3>
          
          <div className="parameter-grid">
            <div className="parameter-item">
              <label>Temperature (K)</label>
              <input type="number" defaultValue="300" className="parameter-input" />
            </div>
            <div className="parameter-item">
              <label>Pressure (bar)</label>
              <input type="number" defaultValue="1.0" step="0.1" className="parameter-input" />
            </div>
            <div className="parameter-item">
              <label>Time Step (ps)</label>
              <input type="number" defaultValue="0.002" step="0.001" className="parameter-input" />
            </div>
            <div className="parameter-item">
              <label>Total Time (ns)</label>
              <input type="number" defaultValue="10" className="parameter-input" />
            </div>
          </div>
        </div>

        {/* System Validation */}
        <div className="card">
          <h3 className="text-lg font-bold mb-4">System Validation</h3>
          
          <div className="validation-grid">
            <div className="validation-item">
              <span className="validation-icon">
                {project.files.some(f => f.type === '.pdb') ? '✅' : '❌'}
              </span>
              <span>Protein structure file</span>
            </div>
            <div className="validation-item">
              <span className="validation-icon">
                {project.forcefield ? '✅' : '❌'}
              </span>
              <span>Force field selected</span>
            </div>
            <div className="validation-item">
              <span className="validation-icon">✅</span>
              <span>Parameter validation</span>
            </div>
          </div>
          
          {project.files.length > 0 && project.forcefield && (
            <div style={{ marginTop: '1rem', textAlign: 'center' }}>
              <button 
                onClick={() => setCurrentView('simulation')}
                className="btn btn-primary"
              >
                ▶️ Start Simulation →
              </button>
            </div>
          )}
        </div>
      </div>
    );
  };

  const renderSimulation = () => {
    const project = getCurrentProject();
    if (!project) return <div>No project selected</div>;

    return (
      <div>
        <h2 className="text-2xl font-bold mb-4">▶️ Simulation Control - {project.name}</h2>
        
        {/* Simulation Status */}
        <div className="card mb-4">
          <h3 className="text-lg font-bold mb-4">Simulation Status</h3>
          
          <div className="simulation-status">
            <div className="status-icon">
              {project.status === 'running' ? '🔄' : 
               project.status === 'completed' ? '✅' : 
               project.status === 'failed' ? '❌' : '⏸️'}
            </div>
            <div>
              <div className="font-bold">
                Status: {project.status.toUpperCase()}
              </div>
              <div style={{ color: '#64748b' }}>
                {project.status === 'running' ? 'Simulation in progress...' :
                 project.status === 'completed' ? 'Simulation completed successfully' :
                 project.status === 'failed' ? 'Simulation failed - check logs' :
                 'Ready to start simulation'}
              </div>
            </div>
          </div>
          
          {project.status === 'running' && (
            <div className="progress-bar">
              <div className="progress-fill"></div>
            </div>
          )}
        </div>

        {/* Control Panel */}
        <div className="card mb-4">
          <h3 className="text-lg font-bold mb-4">Control Panel</h3>
          
          <div className="control-buttons">
            <button 
              onClick={() => startSimulation(project.id)}
              disabled={project.status === 'running'}
              className="btn btn-primary"
            >
              ▶️ Start Simulation
            </button>
            <button className="btn" disabled>
              ⏸️ Pause
            </button>
            <button className="btn btn-danger" disabled>
              ⏹️ Stop
            </button>
          </div>
        </div>

        {/* System Info */}
        <div className="card">
          <h3 className="text-lg font-bold mb-4">System Information</h3>
          
          <div className="info-grid">
            <div className="info-item">
              <strong>Force Field:</strong> {project.forcefield || 'Not selected'}
            </div>
            <div className="info-item">
              <strong>Files:</strong> {project.files.length}
            </div>
            <div className="info-item">
              <strong>Temperature:</strong> 300 K
            </div>
            <div className="info-item">
              <strong>Pressure:</strong> 1.0 bar
            </div>
          </div>
          
          {project.status === 'completed' && (
            <div style={{ marginTop: '1rem', textAlign: 'center' }}>
              <button 
                onClick={() => setCurrentView('analysis')}
                className="btn btn-primary"
              >
                📈 View Results →
              </button>
            </div>
          )}
        </div>
      </div>
    );
  };

  const renderAnalysis = () => {
    const project = getCurrentProject();
    if (!project) return <div>No project selected</div>;

    return (
      <div>
        <h2 className="text-2xl font-bold mb-4">📈 Analysis Results - {project.name}</h2>
        
        {project.status !== 'completed' ? (
          <div className="card text-center">
            <div style={{ padding: '3rem', color: '#64748b' }}>
              <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>⏳</div>
              <h3>Analysis Not Available</h3>
              <p>Complete the simulation to view analysis results.</p>
            </div>
          </div>
        ) : (
          <>
            {/* Analysis Summary */}
            <div className="card mb-4">
              <h3 className="text-lg font-bold mb-4">Analysis Summary</h3>
              
              <div className="analysis-grid">
                <div className="analysis-card">
                  <div className="analysis-value">0.18 nm</div>
                  <div className="analysis-label">Average RMSD</div>
                </div>
                <div className="analysis-card">
                  <div className="analysis-value">-1300 kJ/mol</div>
                  <div className="analysis-label">Average Energy</div>
                </div>
                <div className="analysis-card">
                  <div className="analysis-value">0.28 nm</div>
                  <div className="analysis-label">Max RMSF</div>
                </div>
                <div className="analysis-card">
                  <div className="analysis-value">5000</div>
                  <div className="analysis-label">Frames</div>
                </div>
              </div>
            </div>

            {/* Analysis Tools */}
            <div className="card">
              <h3 className="text-lg font-bold mb-4">Analysis Tools</h3>
              
              <div className="tools-grid">
                <button className="tool-card">
                  <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>📊</div>
                  <div className="font-bold">RMSD Plot</div>
                  <div style={{ fontSize: '0.875rem', color: '#64748b' }}>
                    Root mean square deviation over time
                  </div>
                </button>
                
                <button className="tool-card">
                  <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>⚡</div>
                  <div className="font-bold">Energy Analysis</div>
                  <div style={{ fontSize: '0.875rem', color: '#64748b' }}>
                    Potential and kinetic energy plots
                  </div>
                </button>
                
                <button className="tool-card">
                  <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>🌊</div>
                  <div className="font-bold">RMSF Analysis</div>
                  <div style={{ fontSize: '0.875rem', color: '#64748b' }}>
                    Root mean square fluctuation per residue
                  </div>
                </button>
                
                <button className="tool-card">
                  <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>🧬</div>
                  <div className="font-bold">3D Viewer</div>
                  <div style={{ fontSize: '0.875rem', color: '#64748b' }}>
                    Interactive molecular visualization
                  </div>
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    );
  };

  const renderCurrentView = () => {
    switch (currentView) {
      case 'dashboard':
        return renderDashboard();
      case 'upload':
        return renderFileUpload();
      case 'configure':
        return renderConfigure();
      case 'simulation':
        return renderSimulation();
      case 'analysis':
        return renderAnalysis();
      default:
        return renderDashboard();
    }
  };

  return (
    <div>
      {/* Header */}
      <header className="header">
        <div className="container">
          <div className="flex items-center justify-between">
            <h1>🧬 GROMACS GUI Platform</h1>
            <div className="flex items-center gap-4">
              <div className="flex items-center">
                <span className={`status-dot status-${apiStatus.status}`}></span>
                <span style={{ fontSize: '0.875rem' }}>
                  {apiStatus.status === 'connected' ? 'Connected' :
                   apiStatus.status === 'disconnected' ? 'Disconnected' : 'Checking...'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      {renderNavigation()}

      {/* Main Content */}
      <main className="container">
        {/* API Status Alert */}
        {apiStatus.status === 'connected' && currentView === 'dashboard' && (
          <div className="alert alert-success mb-4">
            <strong>✅ Backend Connected!</strong> API is responding at{' '}
            <a href="http://localhost:8000" target="_blank" rel="noopener noreferrer">
              http://localhost:8000
            </a>
          </div>
        )}

        {apiStatus.status === 'disconnected' && (
          <div className="alert alert-error mb-4">
            <strong>❌ Backend Disconnected</strong><br />
            {apiStatus.message}<br />
            Make sure the backend server is running on port 8000.
          </div>
        )}

        {/* Current View Content */}
        {renderCurrentView()}
      </main>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          GROMACS GUI Platform - Molecular Dynamics Made Easy
        </div>
      </footer>
    </div>
  );
}

export default App;
