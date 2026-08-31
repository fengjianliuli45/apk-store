import { newId, isUuid } from './uuid';

describe('uuid v7', () => {
  it('should — 生成合法 UUID', () => {
    const id = newId();
    expect(isUuid(id)).toBe(true);
    expect(id[14]).toBe('7'); // version nibble
    expect(['8', '9', 'a', 'b']).toContain(id[19].toLowerCase()); // variant
  });

  it('should — 时间有序：后生成的字符串序 >= 先生成的', async () => {
    const a = newId();
    await new Promise((r) => setTimeout(r, 3));
    const b = newId();
    expect(b > a).toBe(true);
  });

  it('should — 唯一', () => {
    const set = new Set(Array.from({ length: 5000 }, () => newId()));
    expect(set.size).toBe(5000);
  });

  it('should — isUuid 拒绝垃圾', () => {
    expect(isUuid('nope')).toBe(false);
    expect(isUuid(123)).toBe(false);
  });
});
