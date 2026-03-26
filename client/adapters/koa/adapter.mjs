import * as fs from "fs";

export default async function run({
    renderFunctionFilePath,
    // routePatterns,
    // apiRoutePatterns,
}) {
    console.log("Running elm pages koa adapter");
    ensureDirSync("dist-server");
    fs.copyFileSync(renderFunctionFilePath, "./dist-server/elm-pages.mjs");
    fs.copyFileSync("./adapters/koa/server.mjs", "./dist-server/server.mjs");
    fs.copyFileSync(
        "./adapters/koa/middleware.mjs",
        "./dist-server/middleware.mjs"
    );
}

function ensureDirSync(dirpath) {
    try {
        fs.mkdirSync(dirpath, { recursive: true });
    } catch (err) {
        if (err.code !== "EEXIST") throw err;
    }
}
