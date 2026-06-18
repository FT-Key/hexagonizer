#!/bin/bash
# generator/project/06-create-server.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../common/logging.sh"
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

main() {
  write_file_with_confirm "src/config/server.js" \
'import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class Server {
  constructor({ routes = [], middlewares = [] } = {}) {
    this.app = express();
    this.routes = routes;
    this.middlewares = middlewares;
  }

  setupMiddlewares() {
    this.app.use(express.json());
    this.app.use(express.static(path.resolve(__dirname, "../public")));
    this.middlewares.forEach((mw) => this.app.use(mw));
  }

  setupRoutes() {
    this.routes.forEach(({ path: routePath, handler }) => {
      this.app.use(routePath, handler);
    });
    this.app.get("/", (req, res) => {
      res.sendFile(path.resolve(__dirname, "../public/index.html"));
    });
  }

  start(port = 3000) {
    this.setupMiddlewares();
    this.setupRoutes();
    this.app.listen(port, () => {
      console.log("Servidor iniciado en http://localhost:" + port);
    });
  }

  getApp() {
    return this.app;
  }
}
'
  log "SUCCESS" "Servidor Express creado (src/config/server.js)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_SERVER:-}" || $# -gt 0) ]]; then
  main "$@"
fi
