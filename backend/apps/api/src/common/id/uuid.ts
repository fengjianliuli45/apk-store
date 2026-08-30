import { randomBytes } from 'node:crypto';

/**
 * UUID v7（RFC 9562）——时间有序，所有实体主键统一用它。
 * 前 48 bit = Unix 毫秒时间戳，其余随机；version=7, variant=10。
 * 自己实现，不引第三方依赖（对齐 ADAPTATION_PLAN §9.9）。
 */
export function newId(): string {
  const ts = Date.now();
  const buf = randomBytes(16);

  // 48-bit big-endian 毫秒时间戳
  buf[0] = (ts / 2 ** 40) & 0xff;
  buf[1] = (ts / 2 ** 32) & 0xff;
  buf[2] = (ts / 2 ** 24) & 0xff;
  buf[3] = (ts / 2 ** 16) & 0xff;
  buf[4] = (ts / 2 ** 8) & 0xff;
  buf[5] = ts & 0xff;

  buf[6] = (buf[6] & 0x0f) | 0x70; // version 7
  buf[8] = (buf[8] & 0x3f) | 0x80; // variant 10

  const hex = buf.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(
    16,
    20,
  )}-${hex.slice(20)}`;
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(value: unknown): value is string {
  return typeof value === 'string' && UUID_RE.test(value);
}
