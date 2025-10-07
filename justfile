start: 
	process-compose up

install: 
	pnpm install

build *FLAGS:
	pnpm build {{FLAGS}}
