import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'crypto';

const DEFAULT_KEY = 'babyland-ai-default-dev-key-change-in-prod';

function getKeyMaterial(): Buffer {
  const source = process.env.AI_DB_ENCRYPTION_KEY ?? DEFAULT_KEY;
  return createHash('sha256').update(source).digest();
}

export function encryptField(plainText: string): string {
  const key = getKeyMaterial();
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(plainText, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${tag.toString('hex')}:${encrypted.toString('hex')}`;
}

export function decryptField(payload: string): string {
  const [ivHex, tagHex, encryptedHex] = payload.split(':');
  if (!ivHex || !tagHex || !encryptedHex) return payload;
  const key = getKeyMaterial();
  const decipher = createDecipheriv('aes-256-gcm', key, Buffer.from(ivHex, 'hex'));
  decipher.setAuthTag(Buffer.from(tagHex, 'hex'));
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(encryptedHex, 'hex')),
    decipher.final(),
  ]);
  return decrypted.toString('utf8');
}
