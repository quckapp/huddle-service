# Environment Configuration

This folder contains environment-specific configuration files for the Huddle Service.

## Available Environments

| File | Environment | Description |
|------|-------------|-------------|
| `dev.env` | Development | Local development with debug logging |
| `test.env` | Test | Automated testing with isolated databases |
| `staging.env` | Staging | Pre-production environment |
| `prod.env` | Production | Production environment with secrets from vault |
| `docker.env` | Docker | Docker Compose local development |

## Usage

### Local Development

```bash
cp envs/dev.env .env
mix phx.server
```

### Docker Development

```bash
docker-compose --env-file envs/docker.env up
```

## Service-Specific Variables

### Huddle Configuration

- `MAX_PARTICIPANTS_PER_HUDDLE` - Maximum participants in a huddle
- `HUDDLE_IDLE_TIMEOUT_MINUTES` - Auto-close idle huddles after this duration
- `HUDDLE_MAX_DURATION_MINUTES` - Maximum huddle duration
