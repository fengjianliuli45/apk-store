import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import { PostView, SocialService } from './social.service';
import { SocialPost } from '../social-posts/domain/social-post';
import { PostComment } from '../post-comments/domain/post-comment';
import { Follow } from '../follows/domain/follow';
import { CursorPage } from '../common/pagination/cursor';
import { CreatePostDto } from './dto/create-post.dto';
import {
  AddCommentDto,
  CreateReportDto,
  CursorQueryDto,
} from './dto/social-misc.dto';

@ApiTags('Social')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({ path: 'social', version: '1' })
export class SocialController {
  constructor(private readonly social: SocialService) {}

  private uid(r: RequestWithUser<JwtPayloadType>): number {
    return Number(r.user.id);
  }

  // posts
  @Post('posts')
  @ApiOkResponse({ type: SocialPost })
  createPost(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Body() dto: CreatePostDto,
  ): Promise<PostView> {
    return this.social.createPost(this.uid(r), dto);
  }

  @Get('feed')
  @ApiOkResponse({ type: SocialPost, isArray: true })
  feed(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Query() q: CursorQueryDto,
  ): Promise<CursorPage<PostView>> {
    return this.social.getFeed(this.uid(r), q.limit ?? 20, q.cursor);
  }

  @Get('posts/:id')
  @ApiOkResponse({ type: SocialPost })
  getPost(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<PostView> {
    return this.social.getPost(this.uid(r), id);
  }

  @Delete('posts/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deletePost(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<void> {
    return this.social.deletePost(this.uid(r), id);
  }

  @Get('users/:userId/posts')
  @ApiOkResponse({ type: SocialPost, isArray: true })
  userPosts(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('userId', ParseIntPipe) userId: number,
    @Query() q: CursorQueryDto,
  ): Promise<CursorPage<PostView>> {
    return this.social.getUserPosts(
      this.uid(r),
      userId,
      q.limit ?? 20,
      q.cursor,
    );
  }

  // likes
  @Post('posts/:id/like')
  @HttpCode(HttpStatus.NO_CONTENT)
  like(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<void> {
    return this.social.like(this.uid(r), id);
  }

  @Delete('posts/:id/like')
  @HttpCode(HttpStatus.NO_CONTENT)
  unlike(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
  ): Promise<void> {
    return this.social.unlike(this.uid(r), id);
  }

  // comments
  @Get('posts/:id/comments')
  @ApiOkResponse({ type: PostComment, isArray: true })
  listComments(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
    @Query() q: CursorQueryDto,
  ): Promise<CursorPage<PostComment>> {
    return this.social.listComments(this.uid(r), id, q.limit ?? 20, q.cursor);
  }

  @Post('posts/:id/comments')
  @ApiOkResponse({ type: PostComment })
  addComment(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('id') id: string,
    @Body() dto: AddCommentDto,
  ): Promise<PostComment> {
    return this.social.addComment(this.uid(r), id, dto);
  }

  @Delete('comments/:commentId')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteComment(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('commentId') commentId: string,
  ): Promise<void> {
    return this.social.deleteComment(this.uid(r), commentId);
  }

  // follow
  @Post('follow/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  follow(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('userId', ParseIntPipe) userId: number,
  ): Promise<void> {
    return this.social.follow(this.uid(r), userId);
  }

  @Delete('follow/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unfollow(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('userId', ParseIntPipe) userId: number,
  ): Promise<void> {
    await this.social.unfollow(this.uid(r), userId);
  }

  @Get('users/:userId/followers')
  @ApiOkResponse({ type: Follow, isArray: true })
  followers(
    @Param('userId', ParseIntPipe) userId: number,
    @Query() q: CursorQueryDto,
  ): Promise<CursorPage<Follow>> {
    return this.social.listFollowers(userId, q.limit ?? 20, q.cursor);
  }

  @Get('users/:userId/following')
  @ApiOkResponse({ type: Follow, isArray: true })
  following(
    @Param('userId', ParseIntPipe) userId: number,
    @Query() q: CursorQueryDto,
  ): Promise<CursorPage<Follow>> {
    return this.social.listFollowing(userId, q.limit ?? 20, q.cursor);
  }

  @Get('users/:userId/stats')
  stats(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('userId', ParseIntPipe) userId: number,
  ): Promise<{ followers: number; following: number; isFollowing: boolean }> {
    return this.social.followStats(this.uid(r), userId);
  }

  // block
  @Post('block/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  block(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('userId', ParseIntPipe) userId: number,
  ): Promise<void> {
    return this.social.block(this.uid(r), userId);
  }

  @Delete('block/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unblock(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Param('userId', ParseIntPipe) userId: number,
  ): Promise<void> {
    await this.social.unblock(this.uid(r), userId);
  }

  // report
  @Post('reports')
  @HttpCode(HttpStatus.ACCEPTED)
  report(
    @Request() r: RequestWithUser<JwtPayloadType>,
    @Body() dto: CreateReportDto,
  ): Promise<void> {
    return this.social.report(this.uid(r), dto);
  }
}
