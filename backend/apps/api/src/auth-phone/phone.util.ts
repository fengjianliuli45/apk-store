/**
 * 手机号归一化到 E.164。
 * - `+` 开头：去掉空格 / 连字符后按 E.164 校验
 * - 11 位、以 1 开头的纯数字：视为中国大陆号，补 `+86`
 * 其它一律返回 null（调用方抛 422）。
 */
export function normalizePhone(input: string): string | null {
  if (!input) return null;
  const trimmed = input.replace(/[\s-]/g, '');

  if (trimmed.startsWith('+')) {
    return /^\+[1-9]\d{6,14}$/.test(trimmed) ? trimmed : null;
  }

  if (/^1[3-9]\d{9}$/.test(trimmed)) {
    return `+86${trimmed}`;
  }

  return null;
}
