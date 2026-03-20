import * as elmPages from "./elm-pages.mjs";

export default async (ctx, next) => {
    try {
        const { headers, statusCode, body, kind } = await elmPages.render(reqToElmPagesJson(ctx.request))
        ctx.response.status = statusCode
        for (const key in headers) {
            ctx.set(key, headers[key]);
        }
        if (kind === "bytes") {
            ctx.response.body = Buffer.from(body)
        } else {
            ctx.response.body = body
        }
    } catch (error) {
        console.log("Encountered error serving request", ctx.request, error)
        ctx.response.status = 500
        // this can be styled, or taken out of a nice .html error file
        ctx.response.body = "<body><h1>Error</h1><pre>Unexpected Error</pre></body>"
    } finally {
        next()
    }
}

const reqToElmPagesJson = (req) => {
    const { body, headers, method } = req;
    const rawUrl = `${req.protocol}://${req.host}${req.originalUrl}`;
    
    return {
        requestTime: Math.round(new Date().getTime()),
        method,
        headers,
        rawUrl,
        body:  body && isFormData(headers) ? toFormData(body) : body && JSON.stringify(body) || null,
        multiPartFormData: null,
    };
};

const isFormData = (headers) => headers['content-type'] === 'application/x-www-form-urlencoded';

const toFormData = (body) => typeof body === 'string'
    ? body
    : Object.entries(body).reduce((formData, [key, value]) => {
        formData.append(key, value);
        return formData;
    }, new URLSearchParams()).toString() || null;
