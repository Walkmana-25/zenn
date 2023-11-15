FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:18
LABEL org.opencontainers.image.authors bells17
LABEL org.opencontainers.image.title zenn
LABEL org.opencontainers.image.url https://github.com/bells17/zenn-template/pkgs/container/zenn
LABEL org.opencontainers.image.source https://github.com/bells17/zenn-template
WORKDIR /zenn
EXPOSE 8000
RUN npm install -g zenn-cli@latest
RUN adduser zenn
USER zenn
CMD ["zenn", "preview"]
