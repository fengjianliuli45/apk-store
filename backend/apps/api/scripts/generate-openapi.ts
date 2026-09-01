/**
 * headless 导出 OpenAPI 3.1 spec，不连 DB / Redis（preview 模式）。
 *   npm run openapi:export
 * 产出：backend/packages/contracts/openapi.json
 */
import 'dotenv/config';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { VersioningType } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from '../src/app.module';

async function main() {
  const app = await NestFactory.create(AppModule, {
    preview: true,
    logger: false,
  });
  app.setGlobalPrefix(process.env.API_PREFIX || 'api', { exclude: ['/'] });
  app.enableVersioning({ type: VersioningType.URI });

  const config = new DocumentBuilder()
    .setTitle('Stopwatch API')
    .setDescription('Stopwatch 后端 API（阶段 1-5）。给 Flutter 前端对接。')
    .setVersion('1')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  document.openapi = '3.1.0';

  const out = resolve(
    __dirname,
    '../../../packages/contracts/openapi.json',
  );
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, JSON.stringify(document, null, 2) + '\n');
  // eslint-disable-next-line no-console
  console.log(
    `openapi 3.1 -> ${out} (${Object.keys(document.paths ?? {}).length} paths)`,
  );

  await app.close();
}

void main();
