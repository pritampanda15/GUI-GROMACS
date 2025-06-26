FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    wget \
    cmake \
    gcc \
    g++ \
    libfftw3-dev \
    libopenmpi-dev \
    openmpi-bin \
    && rm -rf /var/lib/apt/lists/*

# Install GROMACS (latest version)
RUN wget http://ftp.gromacs.org/gromacs/gromacs-2023.3.tar.gz \
    && tar xfz gromacs-2023.3.tar.gz \
    && cd gromacs-2023.3 \
    && mkdir build \
    && cd build \
    && cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON \
    && make -j$(nproc) \
    && make install \
    && cd ../../ \
    && rm -rf gromacs-2023.3*

# Add GROMACS to PATH
ENV PATH="/usr/local/gromacs/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/gromacs/lib:${LD_LIBRARY_PATH}"

# Source GROMACS environment
RUN echo 'source /usr/local/gromacs/bin/GMXRC' >> ~/.bashrc

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p uploads projects logs

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
