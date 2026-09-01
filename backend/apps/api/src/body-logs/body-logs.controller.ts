import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Put,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import { BodyLogsService } from './body-logs.service';
import { BodyLog } from './domain/body-log';
import {
  cursorPage,
  CursorPageDto,
} from '../common/pagination/cursor-page.dto';
import { ListBodyLogsQueryDto, UpsertBodyLogDto } from './dto/body-log.dto';

class BodyLogPageDto extends CursorPageDto<BodyLog> {}

@ApiTags('BodyLogs')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({ path: 'body-logs', version: '1' })
export class BodyLogsController {
  constructor(private readonly service: BodyLogsService) {}

  private uid(r: RequestWithUser<JwtPayloadType>): number {
    return Number(r.user.id);
  }

  @Put()
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: BodyLog })
  upsert(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Body() dto: UpsertBodyLogDto,
  ): Promise<BodyLog> {
    return this.service.upsert(this.uid(r), dto);
  }

  @Get()
  @ApiOkResponse({ type: cursorPage(BodyLog) })
  list(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Query() query: ListBodyLogsQueryDto,
  ): Promise<BodyLogPageDto> {
    return this.service.list(this.uid(r), query);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<void> {
    return this.service.remove(this.uid(r), id);
  }
}
