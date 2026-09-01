import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import { TrainingPlansService } from './training-plans.service';
import { TrainingPlan, TrainingPlanWithVersion } from './domain/training-plan';
import { PlanVersion } from '../plan-versions/domain/plan-version';
import { CursorPage } from '../common/pagination/cursor';
import { cursorPage } from '../common/pagination/cursor-page.dto';
import { SavePlanDto } from './dto/save-plan.dto';
import { ListVersionsQueryDto } from './dto/list-versions-query.dto';

@ApiTags('Plans')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({
  path: 'plans',
  version: '1',
})
export class TrainingPlansController {
  constructor(private readonly plansService: TrainingPlansService) {}

  private userId(request: RequestWithUser<JwtPayloadType>): number {
    return Number(request.user.id);
  }

  @Post()
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: TrainingPlanWithVersion })
  save(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: SavePlanDto,
  ): Promise<TrainingPlanWithVersion> {
    return this.plansService.savePlan(this.userId(request), dto);
  }

  @Get('current')
  @ApiOkResponse({ type: TrainingPlanWithVersion })
  current(
    @Request() request: RequestWithUser<JwtPayloadType>,
  ): Promise<TrainingPlanWithVersion> {
    return this.plansService.getCurrent(this.userId(request));
  }

  @Get('current/versions')
  @ApiOkResponse({ type: cursorPage(PlanVersion) })
  versions(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Query() query: ListVersionsQueryDto,
  ): Promise<CursorPage<PlanVersion>> {
    return this.plansService.listVersions(
      this.userId(request),
      query.limit ?? 20,
      query.cursor,
    );
  }

  @Get('versions/:id')
  @ApiOkResponse({ type: PlanVersion })
  version(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<PlanVersion> {
    return this.plansService.getVersion(this.userId(request), id);
  }

  @Post('current/archive')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: TrainingPlan })
  archive(
    @Request() request: RequestWithUser<JwtPayloadType>,
  ): Promise<TrainingPlan> {
    return this.plansService.archiveCurrent(this.userId(request));
  }
}
