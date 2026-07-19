import { randomUUID } from 'crypto';

import { AiDataStore } from '../shared/data_store';
import { PromptVersion } from '../shared/types';

export class PromptVersionManager {
  constructor(private readonly dataStore: AiDataStore) {}

  async createVersion(params: {
    prompt: string;
    source: 'manual' | 'optimizer';
    status?: PromptVersion['status'];
    metadata?: Record<string, unknown>;
  }): Promise<PromptVersion> {
    const currentVersions = await this.dataStore.listPromptVersions();
    const nextVersion =
      currentVersions.length === 0
        ? 1
        : Math.max(...currentVersions.map((p) => p.version)) + 1;
    const version: PromptVersion = {
      id: randomUUID(),
      version: nextVersion,
      prompt: params.prompt,
      source: params.source,
      status: params.status ?? 'draft',
      metadata: params.metadata,
      created_at: new Date().toISOString(),
    };
    await this.dataStore.insertPromptVersion(version);
    return version;
  }

  async listVersions(): Promise<PromptVersion[]> {
    return this.dataStore.listPromptVersions();
  }
}
