import { defineConfig } from "vite";
import adapter from "./adapters/koa/adapter.mjs";

export default {
  vite: defineConfig({}),
  adapter,
  headTagsTemplate(context) {
    return `
<link rel="favicon" type="image/ico" href="favicon.ico"  />
<link rel="stylesheet" href="/style.css" />
<script src="https://kit.fontawesome.com/a50743c03b.js" crossorigin="anonymous"></script>
<script src=" https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js "></script>
<meta name="generator" content="elm-pages v${context.cliVersion}" />
`;
  },
  preloadTagForFile(file) {
    // add preload directives for JS assets and font assets, etc., skip for CSS files
    // this function will be called with each file that is processed by Vite, including any files in your headTagsTemplate in your config
    return !file.endsWith(".css");
  },
};
