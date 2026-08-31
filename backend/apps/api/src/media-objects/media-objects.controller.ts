import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Body,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import {
  MediaObjectsService,
  MediaWithUrl,
  UploadTicket,
} from './media-objects.service';
import { MediaObject } from './domain/media-object';
import { RequestUploadDto } from './dto/request-upload.dto';

@ApiTags('Media')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({
  path: 'media',
  version: '1',
})
export class MediaObjectsController {
  constructor(private readonly service: MediaObjectsService) {}

  private userId(request: RequestWithUser<JwtPayloadType>): number {
    return Number(request.user.id);
  }

  @Post('upload-url')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: '预签名直传 URL + mediaId' })
  requestUpload(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: RequestUploadDto,
  ): Promise<UploadTicket> {
    return this.service.requestUpload(this.userId(request), dto);
  }

  @Post(':id/complete')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: MediaObject })
  complete(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<MediaObject> {
    return this.service.completeUpload(this.userId(request), id);
  }

  @Get(':id')
  @ApiOkResponse({ description: '元数据 + 读 URL' })
  get(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<MediaWithUrl> {
    return this.service.getWithUrl(this.userId(request), id);
  }
}
