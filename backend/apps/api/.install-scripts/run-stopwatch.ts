// Stopwatch: 非交互执行 boilerplate 的裁剪 —— PostgreSQL only + 去 Facebook 登录。
// 用法：npx ts-node -r tsconfig-paths/register .install-scripts/run-stopwatch.ts
import removeFacebookAuth from './scripts/remove-auth-facebook';
import removeMongoDb from './scripts/remove-mongodb';
import removeDocumentResourceGeneration from './scripts/resource-generation-scripts/remove-document';
import removeAllDbResourceGeneration from './scripts/resource-generation-scripts/remove-all-db';
import removeDocumentPropertyGeneration from './scripts/property-generation-scripts/remove-document';
import removeAllDbPropertyGeneration from './scripts/property-generation-scripts/remove-all-db';

removeMongoDb();
removeDocumentResourceGeneration();
removeDocumentPropertyGeneration();
removeAllDbResourceGeneration();
removeAllDbPropertyGeneration();
removeFacebookAuth();

// eslint-disable-next-line no-console
console.log('stopwatch trim done: pg-only, no facebook');
