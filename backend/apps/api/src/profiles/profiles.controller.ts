import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Put,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import { ProfilesService } from './profiles.service';
import { Profile } from './domain/profile';
import { UpsertProfileDto } from './dto/upsert-profile.dto';

@ApiTags('Profiles')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({
  path: 'profile',
  version: '1',
})
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get('me')
  @ApiOkResponse({ type: Profile })
  me(@Request() request: RequestWithUser<JwtPayloadType>): Promise<Profile> {
    return this.profilesService.getByUserIdOrFail(Number(request.user.id));
  }

  @Put('me')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: Profile })
  upsert(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: UpsertProfileDto,
  ): Promise<Profile> {
    return this.profilesService.upsertForUser(Number(request.user.id), dto);
  }
}
