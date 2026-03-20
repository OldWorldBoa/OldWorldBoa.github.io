import Koa from 'koa';
import serve from 'koa-static';
import { koaBody } from 'koa-body';
import elmPagesMiddleware from './middleware.mjs';

const app = new Koa()
const port = 3000;

// Serve static files from 'dist' directory
app.use(serve('dist'));
app.use(koaBody());

// Use your custom middleware
app.use(elmPagesMiddleware);

// Start the server
app.listen(port, () => {
    console.log(`Listening on port ${port}`);
});
