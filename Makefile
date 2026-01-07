COMPOSE = docker compose
STACK_DIR = srv/compose/arr

bootstrap: 
	./scripts/bootstrap.sh
	
up:
	cd $(STACK_DIR) && $(COMPOSE) up -d

down:
	cd $(STACK_DIR) && $(COMPOSE) down

restart:
	cd $(STACK_DIR) && $(COMPOSE) down && $(COMPOSE) up -d

logs:
	cd $(STACK_DIR) && $(COMPOSE) logs -f --tail=200

ps:
	cd $(STACK_DIR) && $(COMPOSE) ps

update:
	cd $(STACK_DIR) && $(COMPOSE) pull
	cd $(STACK_DIR) && $(COMPOSE) up -d --remove-orphans

health:
	./scripts/healthcheck.sh
