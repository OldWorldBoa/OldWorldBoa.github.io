# info.oldworldboa.ca /client

## Build

1. ``` npm install ```
2. ``` npm run build ```

## Deploy

1. Build on the target machine
2. Create the site with ``` pm2 ./dist-server/server.mjs ```
3. Restart the site with ``` pm2 restart <app-name>```

This is being managed using [pm2](https://pm2.keymetrics.io/docs/usage/pm2-doc-single-page/)

## Test

Run ``` npm run dev ```
