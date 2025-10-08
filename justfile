start: 
	process-compose up

install: 
	pnpm install

build *FLAGS:
	pnpm build {{FLAGS}}

lint:
	yes | pnpx elm-review --fix-all
