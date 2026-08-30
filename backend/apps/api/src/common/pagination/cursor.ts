/**
 * 游标分页（对齐 ADAPTATION_PLAN §5：禁 deep OFFSET）。
 *
 * 约定：按 (created_at DESC, id DESC) 排序，游标 = base64url(JSON{ t, i })。
 * 每个列表端点用 `decodeCursor` 拿到上一页末尾，SQL 里 `WHERE (created_at,id) < (:t,:i)`。
 */
export interface CursorPayload {
  /** 上一页最后一条的 created_at（ISO） */
  t: string;
  /** 上一页最后一条的 id */
  i: string;
}

export interface CursorPage<T> {
  data: T[];
  /** 下一页游标；null = 没有更多 */
  nextCursor: string | null;
}

const b64u = {
  encode: (s: string) => Buffer.from(s, 'utf8').toString('base64url'),
  decode: (s: string) => Buffer.from(s, 'base64url').toString('utf8'),
};

export function encodeCursor(payload: CursorPayload): string {
  return b64u.encode(JSON.stringify(payload));
}

export function decodeCursor(cursor?: string | null): CursorPayload | null {
  if (!cursor) return null;
  try {
    const obj = JSON.parse(b64u.decode(cursor)) as Partial<CursorPayload>;
    if (typeof obj.t === 'string' && typeof obj.i === 'string') {
      return { t: obj.t, i: obj.i };
    }
  } catch {
    /* 坏游标当没有 */
  }
  return null;
}

/**
 * 取 `limit + 1` 行判断是否有下一页；返回裁剪后的数据 + nextCursor。
 * `getKey` 从一行取 (created_at, id)。
 */
export function toCursorPage<T>(
  rows: T[],
  limit: number,
  getKey: (row: T) => { createdAt: Date | string; id: string },
): CursorPage<T> {
  const hasMore = rows.length > limit;
  const data = hasMore ? rows.slice(0, limit) : rows;
  let nextCursor: string | null = null;
  if (hasMore && data.length > 0) {
    const k = getKey(data[data.length - 1]);
    nextCursor = encodeCursor({
      t:
        k.createdAt instanceof Date
          ? k.createdAt.toISOString()
          : String(k.createdAt),
      i: k.id,
    });
  }
  return { data, nextCursor };
}
