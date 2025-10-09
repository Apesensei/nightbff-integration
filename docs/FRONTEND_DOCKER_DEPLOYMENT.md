# Frontend Docker Deployment Guide

This document outlines how to build and deploy the `nightbff-frontend` web application using Docker.

## 1. Build the Docker Image

Navigate to the root of the `nightbff-integration` repository.

```bash
# Build image (from integration repo root)
docker build -f Dockerfile.frontend -t nightbff-frontend:local nightbff-frontend/
```

This command uses `Dockerfile.frontend` to build a Docker image named `nightbff-frontend:local`.
The build context is set to `nightbff-frontend/`, ensuring only necessary files are included.

## 2. Run the Docker Container

You can run the built image locally using Docker:

```bash
docker run -p 8080:80 nightbff-frontend:local
```

This will start the Nginx server inside the container, exposing the frontend on `http://localhost:8080`.

## 3. Integration with Docker Compose

The `docker-compose.yaml` in the `nightbff-integration` repository is configured to build and run the frontend service using `Dockerfile.frontend`.

To start the entire stack:

```bash
docker compose up -d frontend
```

This will build the frontend image (if not already built) and start the container, accessible via the port defined in `docker-compose.yaml` (e.g., `http://localhost:8081`).

## 4. CI/CD Integration

The GitHub Actions workflow (`.github/workflows/integration-ci.yml`) is configured to:

- Build the `nightbff-frontend` Docker image using `Dockerfile.frontend`.
- Push the image to GHCR.
- Use this image in the integration test stack.

Refer to `.github/workflows/integration-ci.yml` for details on the automated build and deployment process.
