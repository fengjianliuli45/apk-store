import { ApiProperty } from '@nestjs/swagger';
import type { Type } from '@nestjs/common';

/**
 * 游标分页响应的统一形状：`{ data, nextCursor }`。
 * 列表端点用 `@ApiOkResponse({ type: cursorPage(Model) })` 让 OpenAPI 正确描述。
 */
export abstract class CursorPageDto<T> {
  @ApiProperty({ isArray: true })
  data: T[];

  @ApiProperty({
    type: String,
    nullable: true,
    description: '下一页游标；null = 没有更多',
  })
  nextCursor: string | null;
}

const cache = new WeakMap<object, Type<unknown>>();

export function cursorPage<T>(model: Type<T>): Type<CursorPageDto<T>> {
  const hit = cache.get(model);
  if (hit) {
    return hit as Type<CursorPageDto<T>>;
  }

  class Page extends CursorPageDto<T> {
    @ApiProperty({ type: () => model, isArray: true })
    declare data: T[];
  }
  Object.defineProperty(Page, 'name', { value: `${model.name}CursorPage` });
  cache.set(model, Page);
  return Page;
}
