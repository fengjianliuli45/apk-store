export type HeadResult = {
  size: number;
  contentType: string | null;
};

export type PresignPutInput = {
  key: string;
  contentType: string;
  maxSize: number;
  ttlSeconds: number;
};

/**
 * 对象存储抽象。生产用 S3 兼容（阿里云 OSS / 腾讯云 COS / AWS S3）；
 * 开发 / 测试用 fake。ADAPTATION_PLAN §9.13：预签名要限定
 * key 前缀 + content-type + max-size + 短 TTL。
 */
export abstract class StorageService {
  /** 生成一个受限的直传 URL（PUT）。 */
  abstract presignPut(input: PresignPutInput): Promise<string>;

  /** 生成一个读 URL（GET），或返回 CDN 地址。 */
  abstract presignGet(key: string, ttlSeconds: number): Promise<string>;

  /** HEAD 对象；不存在返回 null。complete 时用来核对实际大小 / 类型。 */
  abstract head(key: string): Promise<HeadResult | null>;

  abstract delete(key: string): Promise<void>;
}
