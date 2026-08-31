import { normalizePhone } from './phone.util';

describe('normalizePhone', () => {
  it('should prefix +86 for an 11-digit mainland number', () => {
    expect(normalizePhone('13800000000')).toBe('+8613800000000');
    expect(normalizePhone('138 0000 0000')).toBe('+8613800000000');
    expect(normalizePhone('138-0000-0000')).toBe('+8613800000000');
  });

  it('should keep a valid E.164 number', () => {
    expect(normalizePhone('+8613800000000')).toBe('+8613800000000');
    expect(normalizePhone('+14155552671')).toBe('+14155552671');
  });

  it('should reject malformed input', () => {
    expect(normalizePhone('')).toBeNull();
    expect(normalizePhone('12345')).toBeNull();
    expect(normalizePhone('10000000000')).toBeNull(); // second digit must be 3-9
    expect(normalizePhone('+0123456789')).toBeNull(); // E.164 can't start with 0
    expect(normalizePhone('abcdefghijk')).toBeNull();
  });
});
