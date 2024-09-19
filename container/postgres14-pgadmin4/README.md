# Docker Setup for PostgreSQL and pgAdmin4

This folder contains a Docker setup for PostgreSQL and pgAdmin4.

## Installation and Usage

1. **Build the containers**:
   ```bash
   docker-compose build
   ```

2. **Start the containers in the background**:
   ```bash
   docker-compose up -d
   ```

3. **Check the status of the containers**:
   ```bash
   docker-compose ps
   ```

## Accessing the Services

- **pgAdmin4**: 
  - URL: [http://localhost:80](http://localhost:80)
  - **Default Email**: `admin@admin.com`
  - **Default Password**: `admin`
  
- **PostgreSQL**:
  - **Hostname/Address**: `postgres`
  - **Port**: `5432`
  - **Maintenance database**: `postgres`
  - **Username**: `postgres`
  - **Password**: `password`


### Accessing the PostgreSQL Shell

You can access the PostgreSQL database via the shell with:
```bash
docker exec -it postgres psql -U postgres -d postgres
```

### Viewing Logs

To view the logs for the PostgreSQL container, use:
```bash
docker logs postgres
```
