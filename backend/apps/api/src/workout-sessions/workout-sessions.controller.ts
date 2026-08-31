import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import { WorkoutSessionsService } from './workout-sessions.service';
import {
  WorkoutSession,
  WorkoutSessionWithSets,
} from './domain/workout-session';
import { WorkoutSet } from '../workout-sets/domain/workout-set';
import { CursorPage } from '../common/pagination/cursor';
import { CreateWorkoutSessionDto } from './dto/create-workout-session.dto';
import { UpdateWorkoutSessionDto } from './dto/update-workout-session.dto';
import { AddSetsDto } from './dto/add-sets.dto';
import { UpdateSetDto } from './dto/update-set.dto';
import { ListSessionsQueryDto } from './dto/list-sessions-query.dto';

@ApiTags('Workouts')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({
  path: 'workouts',
  version: '1',
})
export class WorkoutSessionsController {
  constructor(private readonly service: WorkoutSessionsService) {}

  private userId(request: RequestWithUser<JwtPayloadType>): number {
    return Number(request.user.id);
  }

  @Post('sessions')
  @HttpCode(HttpStatus.CREATED)
  @ApiOkResponse({ type: WorkoutSession })
  createSession(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: CreateWorkoutSessionDto,
  ): Promise<WorkoutSession> {
    return this.service.createSession(this.userId(request), dto);
  }

  @Get('sessions')
  @ApiOkResponse({ type: WorkoutSession, isArray: true })
  listSessions(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Query() query: ListSessionsQueryDto,
  ): Promise<CursorPage<WorkoutSession>> {
    return this.service.listSessions(
      this.userId(request),
      query.limit ?? 20,
      query.cursor,
    );
  }

  @Get('sessions/:id')
  @ApiOkResponse({ type: WorkoutSessionWithSets })
  getSession(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<WorkoutSessionWithSets> {
    return this.service.getSession(this.userId(request), id);
  }

  @Patch('sessions/:id')
  @ApiOkResponse({ type: WorkoutSession })
  updateSession(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
    @Body() dto: UpdateWorkoutSessionDto,
  ): Promise<WorkoutSession> {
    return this.service.updateSession(this.userId(request), id, dto);
  }

  @Post('sessions/:id/sets')
  @HttpCode(HttpStatus.CREATED)
  @ApiOkResponse({ type: WorkoutSet, isArray: true })
  addSets(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
    @Body() dto: AddSetsDto,
  ): Promise<WorkoutSet[]> {
    return this.service.addSets(this.userId(request), id, dto);
  }

  @Patch('sets/:setId')
  @ApiOkResponse({ type: WorkoutSet })
  updateSet(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('setId') setId: string,
    @Body() dto: UpdateSetDto,
  ): Promise<WorkoutSet> {
    return this.service.updateSet(this.userId(request), setId, dto);
  }

  @Delete('sets/:setId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeSet(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('setId') setId: string,
  ): Promise<void> {
    return this.service.removeSet(this.userId(request), setId);
  }
}
