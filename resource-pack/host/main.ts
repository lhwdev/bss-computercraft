import { resolve } from "https://deno.land/std@0.209.0/path/mod.ts";
import { encodeHex } from "https://deno.land/std@0.209.0/encoding/hex.ts";

const path = resolve(Deno.args[0]);
const resourcePackFile = resolve("resource-pack.zip");

await new Deno.Command("/usr/bin/zip", {
  args: ["-r", resourcePackFile, "."],
  cwd: path,
}).output();
const sha1Buffer = await crypto.subtle.digest(
  "SHA-1",
  await Deno.readFile(resourcePackFile),
);
const sha1 = encodeHex(sha1Buffer);
await Deno.writeTextFile("resource-pack-sha1.txt", sha1);

Deno.serve({ port: 80 }, async (req) => {
  const url = new URL(req.url);
  const path = decodeURIComponent(url.pathname);
  console.log(`${req.method} ${path}`);

  switch (path) {
    case "/":
      return new Response("Welcome to temporary hosting!");

    case "/resource-pack.zip": {
      const file = await Deno.open(resourcePackFile, { read: true });
      return new Response(file.readable);
    }

    default:
      return new Response("Error", { status: 404 });
  }
});
