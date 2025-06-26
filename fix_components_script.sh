#!/bin/bash

# Script to create missing component files for GROMACS GUI Frontend

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Creating missing component files...${NC}"

# Navigate to frontend directory
cd frontend/src

# Create directories if they don't exist
mkdir -p components/common
mkdir -p components/file
mkdir -p components/forms
mkdir -p components/layout
mkdir -p components/simulation
mkdir -p components/analysis
mkdir -p contexts
mkdir -p hooks
mkdir -p services
mkdir -p types
mkdir -p utils
mkdir -p tests

echo -e "${GREEN}✓ Created directories${NC}"

# Create Button component
cat > components/common/Button.tsx << 'EOF'
import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
}

const Button: React.FC<ButtonProps> = ({ 
  children, 
  variant = 'primary', 
  size = 'md', 
  className = '', 
  ...props 
}) => {
  const baseClasses = 'font-medium rounded-lg transition-colors focus:outline-none focus:ring-2';
  const variantClasses = {
    primary: 'bg-blue-600 hover:bg-blue-700 text-white focus:ring-blue-500',
    secondary: 'bg-gray-600 hover:bg-gray-700 text-white focus:ring-gray-500',
    danger: 'bg-red-600 hover:bg-red-700 text-white focus:ring-red-500'
  };
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-sm',
    lg: 'px-6 py-3 text-base'
  };

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};

export default Button;
EOF

# Create Modal component
cat > components/common/Modal.tsx << 'EOF'
import React from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
}

const Modal: React.FC<ModalProps> = ({ isOpen, onClose, title, children }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md mx-4">
        <div className="flex items-center justify-between mb-4">
          {title && (
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              {title}
            </h3>
          )}
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <XMarkIcon className="w-5 h-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
};

export default Modal;
EOF

# Create LoadingSpinner component
cat > components/common/LoadingSpinner.tsx << 'EOF'
import React from 'react';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ size = 'md', className = '' }) => {
  const sizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-8 h-8',
    lg: 'w-12 h-12'
  };

  return (
    <div className={`animate-spin rounded-full border-b-2 border-blue-600 ${sizeClasses[size]} ${className}`} />
  );
};

export default LoadingSpinner;
EOF

# Create common index
cat > components/common/index.ts << 'EOF'
export { default as Button } from './Button';
export { default as Modal } from './Modal';
export { default as LoadingSpinner } from './LoadingSpinner';
EOF

# Create Settings page
cat > pages/Settings.tsx << 'EOF'
import React from 'react';

const Settings: React.FC = () => {
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Settings</h1>
      <p className="text-gray-600 dark:text-gray-300">Application settings will be available here.</p>
    </div>
  );
};

export default Settings;
EOF

# Create Help page
cat > pages/Help.tsx << 'EOF'
import React from 'react';

const Help: React.FC = () => {
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Help & Documentation</h1>
      <p className="text-gray-600 dark:text-gray-300">Help documentation will be available here.</p>
    </div>
  );
};

export default Help;
EOF

echo -e "${GREEN}✓ Created essential components${NC}"

# Create placeholder files with minimal exports
files=(
  "components/common/Card.tsx"
  "components/common/Input.tsx"
  "components/common/ErrorBoundary.tsx"
  "components/file/FileList.tsx"
  "components/file/FileViewer.tsx"
  "components/file/FileProgress.tsx"
  "components/forms/ProjectForm.tsx"
  "components/forms/SimulationForm.tsx"
  "components/forms/ForceFieldSelector.tsx"
  "components/forms/ParameterForm.tsx"
  "components/layout/Header.tsx"
  "components/layout/Footer.tsx"
  "components/layout/Layout.tsx"
  "components/simulation/ConfigForm.tsx"
  "components/simulation/StatusPanel.tsx"
  "components/simulation/LogViewer.tsx"
  "components/simulation/ProgressBar.tsx"
  "components/simulation/ParameterEditor.tsx"
  "components/analysis/PlotViewer.tsx"
  "components/analysis/MoleculeViewer.tsx"
  "components/analysis/DataTable.tsx"
  "components/analysis/ExportOptions.tsx"
  "contexts/AuthContext.tsx"
  "contexts/SimulationContext.tsx"
  "contexts/WebSocketContext.tsx"
  "hooks/useAPI.ts"
  "hooks/useFileUpload.ts"
  "hooks/useLocalStorage.ts"
  "hooks/useSimulation.ts"
  "hooks/useWebSocket.ts"
  "services/api.ts"
  "services/projectService.ts"
  "services/fileService.ts"
  "services/simulationService.ts"
  "services/analysisService.ts"
  "services/websocketService.ts"
  "types/project.ts"
  "types/file.ts"
  "types/simulation.ts"
  "types/analysis.ts"
  "types/api.ts"
  "types/common.ts"
  "utils/constants.ts"
  "utils/formatters.ts"
  "utils/validators.ts"
  "utils/helpers.ts"
  "utils/storage.ts"
  "tests/setup.ts"
)

for file in "${files[@]}"; do
  echo "export {};" > "$file"
done

echo -e "${GREEN}✓ Created placeholder files${NC}"

# Add export to index.tsx if it doesn't have one
if ! grep -q "export" index.tsx; then
  echo "" >> index.tsx
  echo "export {};" >> index.tsx
fi

echo -e "${GREEN}✓ Fixed index.tsx${NC}"

cd ../..

echo -e "${GREEN}🎉 All missing files created successfully!${NC}"
echo -e "${BLUE}You can now restart the frontend server${NC}"