#!/usr/bin/env node
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { parse } from 'yaml';
import type { WorkspaceConfig } from './types.js';
import { provision } from './provisioner.js';
import { doctor, printReport } from './doctor.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadConfig(configPath?: string): WorkspaceConfig {
  const path = configPath ?? resolve(__dirname, '..', 'workspace.yaml');
  const raw = readFileSync(path, 'utf-8');
  const config = parse(raw) as WorkspaceConfig;

  if (config.metadata.owner === 'FILL_OWNER') {
    console.error(
      'Error: workspace.yaml has "FILL_OWNER" as the owner. Set metadata.owner to the real GitHub org or user.'
    );
    process.exit(1);
  }

  return config;
}

function printUsage(): void {
  console.log(`
ProdOps Workspace Provisioner

Usage:
  workspace provision [--config <path>]   Provision (or repair) the GitHub Workspace
  workspace doctor    [--config <path>]   Compare workspace.yaml with actual GitHub state

Options:
  --config <path>   Path to workspace.yaml (default: ./workspace.yaml)
  --help            Show this help message

Examples:
  npm run provision
  npm run doctor
  node dist/cli.js provision --config /path/to/workspace.yaml
`);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args[0];
  const configIndex = args.indexOf('--config');
  const configPath = configIndex >= 0 ? args[configIndex + 1] : undefined;

  if (!command || command === '--help' || command === 'help') {
    printUsage();
    process.exit(0);
  }

  if (command === 'provision') {
    const config = loadConfig(configPath);
    console.log(`\nProvisioning workspace: "${config.project.title}"`);
    console.log(`Owner: ${config.metadata.owner}/${config.metadata.repository}`);
    console.log(`Iteration: ${config.metadata.iteration}`);
    await provision(config);
    process.exit(0);
  }

  if (command === 'doctor') {
    const config = loadConfig(configPath);
    console.log(`\nRunning doctor: "${config.project.title}"`);
    console.log(`Owner: ${config.metadata.owner}/${config.metadata.repository}`);
    const report = await doctor(config);
    printReport(report);
    process.exit(report.ok ? 0 : 1);
  }

  console.error(`Unknown command: ${command}`);
  printUsage();
  process.exit(1);
}

main().catch((err: unknown) => {
  console.error('\nFatal error:', err instanceof Error ? err.message : err);
  process.exit(1);
});
