import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import { BatchResult, PullResult, SyncService } from './sync.service';
import { SyncBatchDto } from './dto/sync-batch.dto';
import { PullChangesQueryDto } from './dto/pull-changes-query.dto';

@ApiTags('Sync')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({
  path: 'sync',
  version: '1',
})
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  private userId(request: RequestWithUser<JwtPayloadType>): number {
    return Number(request.user.id);
  }

  @Post('batch')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: '逐条结果 + 最新 syncCursor' })
  push(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: SyncBatchDto,
  ): Promise<BatchResult> {
    return this.syncService.pushBatch(this.userId(request), dto);
  }

  @Get('changes')
  @ApiOkResponse({
    description: 'serverSeq > cursor 的变更，按 serverSeq 升序',
  })
  changes(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Query() query: PullChangesQueryDto,
  ): Promise<PullResult> {
    return this.syncService.pullChanges(
      this.userId(request),
      query.cursor ?? 0,
      query.limit ?? 200,
    );
  }
}
