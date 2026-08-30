import { encodeCursor, decodeCursor, toCursorPage } from './cursor';

describe('cursor pagination', () => {
  it('should — encode/decode 往返', () => {
    const c = encodeCursor({ t: '2026-08-30T00:00:00.000Z', i: 'abc' });
    expect(decodeCursor(c)).toEqual({
      t: '2026-08-30T00:00:00.000Z',
      i: 'abc',
    });
  });

  it('should — 坏游标 → null', () => {
    expect(decodeCursor('!!!')).toBeNull();
    expect(decodeCursor(undefined)).toBeNull();
    expect(
      decodeCursor(Buffer.from('{"x":1}').toString('base64url')),
    ).toBeNull();
  });

  it('should — toCursorPage 裁剪并给下一页游标', () => {
    const rows = Array.from({ length: 6 }, (_, i) => ({
      id: `id${i}`,
      createdAt: new Date(2026, 0, 1, 0, 0, i),
    }));
    const page = toCursorPage(rows, 5, (r) => r);
    expect(page.data).toHaveLength(5);
    expect(page.nextCursor).not.toBeNull();
    const cur = decodeCursor(page.nextCursor);
    expect(cur?.i).toBe('id4');
  });

  it('should — 没有更多时 nextCursor 为 null', () => {
    const rows = [{ id: 'a', createdAt: new Date() }];
    const page = toCursorPage(rows, 5, (r) => r);
    expect(page.data).toHaveLength(1);
    expect(page.nextCursor).toBeNull();
  });
});
