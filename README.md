<div align="center">
  <a href="https://trigger.beyondthecloud.dev/">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="./website/public/logo-round.png">
      <img alt="Trigger Lib logo" src="./website/public/logo-round.png" height="98">
    </picture>
  </a>
  <h1>Trigger Lib</h1>

<a href="https://beyondthecloud.dev"><img alt="Beyond The Cloud logo" src="https://img.shields.io/badge/MADE_BY_BEYOND_THE_CLOUD-555?style=for-the-badge"></a>
<a><img alt="API version" src="https://img.shields.io/badge/api-v67.0-blue?style=for-the-badge"></a>
<a href="https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-mit-green?style=for-the-badge"></a>

[![CI](https://github.com/beyond-the-cloud-dev/trigger-lib/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/beyond-the-cloud-dev/trigger-lib/actions/workflows/ci.yml)

</div>

# Getting Started

Apex trigger framework for Salesforce with record filtering, automatic parent enrichment, bypasses, and recursion control.

Trigger Lib is part of the Beyond the Cloud ecosystem, providing production-ready tools for Salesforce development.

For comprehensive documentation, visit [https://trigger.beyondthecloud.dev/](https://trigger.beyondthecloud.dev/)

## Features

- **Orchestrator & Handlers** - One orchestrator per SObject, one handler per concern, wired in Apex
- **Record Filtering** - Handlers run only against records that qualify, so logic never guards itself
- **Parent Enrichment** - Related data is pulled up front, so handlers make no SOQL queries of their own
- **Bypasses** - Disable an individual handler or a whole orchestrator when you need to
- **Recursion Control** - Depth limiting built in, defaulting to 3
- **No Required Metadata** - Works with zero custom metadata records; metadata only overrides defaults

## Quick Start

```bash
# Clone the repository
git clone https://github.com/beyond-the-cloud-dev/trigger-lib.git
cd trigger-lib

# Install dependencies
npm install

# Authenticate with Dev Hub
sf org login web -d -a DevHub

# Create scratch org
sf org create scratch -f config/project-scratch-def.json -a trigger-lib-dev -d 30

# Deploy the library
sf project deploy start -o trigger-lib-dev

# Deploy the examples (optional)
sf project deploy start -d examples -o trigger-lib-dev
```

## Deploy to Salesforce

<a href="https://githubsfdeploy.herokuapp.com?owner=beyond-the-cloud-dev&repo=trigger-lib&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Documentation

📚 **Full documentation**: [https://trigger.beyondthecloud.dev/](https://trigger.beyondthecloud.dev/)

### Documentation Sections

- **[Getting Started](https://trigger.beyondthecloud.dev/guide/getting-started)** - Set up your development environment
- **[Development Guide](https://trigger.beyondthecloud.dev/guide/development)** - Development workflow and commands
- **[Testing Guide](https://trigger.beyondthecloud.dev/guide/testing)** - Testing framework and best practices
- **[Deployment Guide](https://trigger.beyondthecloud.dev/guide/deployment)** - CI/CD and deployment process
- **[API Reference](https://trigger.beyondthecloud.dev/api/apex)** - Apex documentation
- **[Code Examples](https://trigger.beyondthecloud.dev/examples/)** - Practical code patterns

### Run Documentation Locally

```bash
# Run documentation locally
npm run docs:dev

# Build documentation
npm run docs:build

# Preview built documentation
npm run docs:preview
```

## Project Structure

```
.
├── force-app/              # The library
│   └── main/default/
│       ├── classes/        # TriggerOrchestrator, TriggerHandler
│       └── dependencies/   # Bundled dependencies (soql-lib)
├── examples/               # Reference implementation, deployed separately
│   └── main/default/
│       ├── classes/        # Example orchestrator and handlers
│       └── triggers/       # Example trigger
├── config/                 # Salesforce configurations
│   └── project-scratch-def.json
├── website/                # VitePress documentation
│   ├── .vitepress/
│   ├── guide/
│   ├── api/
│   └── examples/
├── .github/workflows/      # CI/CD workflows
│   ├── ci.yml             # Salesforce CI/CD
│   └── deploy-docs.yml    # Documentation deployment
├── package.json            # npm dependencies and scripts
└── sfdx-project.json      # SFDX project configuration
```

## Available Scripts

### Salesforce

```bash
# Create scratch org
sf org create scratch -f config/project-scratch-def.json -a dev

# Deploy source
sf project deploy start

# Run Apex tests
sf apex run test --test-level RunLocalTests
```

### Testing

```bash
npm test                    # Run all LWC Jest tests
npm run test:unit:watch     # Watch mode
npm run test:unit:debug     # Debug mode
npm run test:unit:coverage  # Generate coverage report
```

### Code Quality

```bash
npm run lint                # Lint LWC and Aura components
npm run prettier            # Format all files
npm run prettier:verify     # Check formatting
```

## CI/CD

### Salesforce CI/CD

`.github/workflows/ci.yml` runs on every push and pull request:

- Creates scratch org
- Deploys source
- Runs Apex tests
- Runs LWC Jest tests
- Uploads coverage to CodeCov

### Documentation Deployment

Documentation is built by Vercel (`vercel.json`) and published to [trigger.beyondthecloud.dev](https://trigger.beyondthecloud.dev/).

### Required Secrets

Add these secrets in GitHub repository settings:

- `SFDX_AUTH_URL_DEVHUB` - Dev Hub authentication URL
- `CODECOV_TOKEN` - CodeCov upload token (optional)

See [Deployment Guide](https://trigger.beyondthecloud.dev/guide/deployment) for detailed instructions.

## What's Included

### Tooling

- **Salesforce CLI** - Modern Salesforce development
- **LWC Jest** - Lightning Web Component testing
- **ESLint** - Code quality for LWC/Aura
- **Prettier** - Code formatting
- **Husky** - Git hooks
- **lint-staged** - Run checks on staged files
- **VitePress** - Documentation site generator

### Configuration

- Scratch org definition
- ESLint rules for LWC/Aura
- Prettier configuration
- Pre-commit hooks
- GitHub Actions workflows
- Test coverage reporting

### Documentation

- Getting Started guide
- Development workflow
- Testing guide
- Deployment guide
- API reference
- Code examples
- Best practices

## Contributors

<a href="https://github.com/beyond-the-cloud-dev/trigger-lib/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=beyond-the-cloud-dev/trigger-lib" />
</a>

## License

MIT License

Copyright © 2025 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)

See [LICENSE](LICENSE) file for details.

## License Notes

- For proper license management each repository should contain LICENSE file similar to this one.
- Each original class should contain copyright mark: © Copyright 2025, Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)

## About Beyond The Cloud

Trigger Lib is maintained by [Beyond The Cloud](https://beyondthecloud.dev) - experts in Salesforce development and DevOps.

**Connect with us:**

- Website: [beyondthecloud.dev](https://beyondthecloud.dev)
- LinkedIn: [Beyond The Cloud](https://www.linkedin.com/company/beyondtheclouddev)
- GitHub: [@beyond-the-cloud-dev](https://github.com/beyond-the-cloud-dev)

## Support

- **Documentation**: [Full documentation](https://trigger.beyondthecloud.dev/)
- **Issues**: [GitHub Issues](https://github.com/beyond-the-cloud-dev/trigger-lib/issues)
- **Discussions**: [GitHub Discussions](https://github.com/beyond-the-cloud-dev/trigger-lib/discussions)
