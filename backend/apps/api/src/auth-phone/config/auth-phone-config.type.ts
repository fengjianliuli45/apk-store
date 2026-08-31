export type AuthPhoneConfig = {
  /** 开发环境把验证码直接回传到 send-code 响应里，省得看日志。生产必须 false。 */
  exposeCode: boolean;
};
