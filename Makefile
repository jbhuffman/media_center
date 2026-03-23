COMPOSE = docker compose
STACK_DIR = srv/compose/arr
INFRA_HOMARR_DIR = srv/compose/infra/dashboard/homarr
INFRA_PORTAINER_DIR = srv/compose/infra/dashboard/portainer
INFRA_PIHOLE_DIR = srv/compose/infra/dns/pihole
INFRA_DOZZLE_DIR = srv/compose/infra/monitoring/dozzle
INFRA_NETDATA_DIR = srv/compose/infra/monitoring/netdata
INFRA_UPTIME_KUMA_DIR = srv/compose/infra/monitoring/uptime-kuma
INFRA_CADDY_DIR = srv/compose/infra/proxy/caddy
INFRA_BITMAGNET_DIR = srv/compose/infra/search/bitmagnet
INFRA_VAULTWARDEN_DIR = srv/compose/infra/security/vaultwarden
INFRA_STACK_DIRS = \
	$(INFRA_HOMARR_DIR) \
	$(INFRA_PORTAINER_DIR) \
	$(INFRA_PIHOLE_DIR) \
	$(INFRA_DOZZLE_DIR) \
	$(INFRA_NETDATA_DIR) \
	$(INFRA_UPTIME_KUMA_DIR) \
	$(INFRA_CADDY_DIR) \
	$(INFRA_BITMAGNET_DIR) \
	$(INFRA_VAULTWARDEN_DIR)

.PHONY: bootstrap up down restart logs ps update health smoke-test backup recyclarr \
	infra-up infra-down infra-restart infra-ps infra-update \
	infra-homarr-up infra-homarr-down infra-homarr-restart infra-homarr-logs infra-homarr-ps infra-homarr-update \
	infra-portainer-up infra-portainer-down infra-portainer-restart infra-portainer-logs infra-portainer-ps infra-portainer-update \
	infra-pihole-up infra-pihole-down infra-pihole-restart infra-pihole-logs infra-pihole-ps infra-pihole-update \
	infra-dozzle-up infra-dozzle-down infra-dozzle-restart infra-dozzle-logs infra-dozzle-ps infra-dozzle-update \
	infra-netdata-up infra-netdata-down infra-netdata-restart infra-netdata-logs infra-netdata-ps infra-netdata-update \
	infra-uptime-kuma-up infra-uptime-kuma-down infra-uptime-kuma-restart infra-uptime-kuma-logs infra-uptime-kuma-ps infra-uptime-kuma-update \
	infra-caddy-up infra-caddy-down infra-caddy-restart infra-caddy-logs infra-caddy-ps infra-caddy-update \
	infra-bitmagnet-up infra-bitmagnet-down infra-bitmagnet-restart infra-bitmagnet-logs infra-bitmagnet-ps infra-bitmagnet-update \
	infra-vaultwarden-up infra-vaultwarden-down infra-vaultwarden-restart infra-vaultwarden-logs infra-vaultwarden-ps infra-vaultwarden-update

define compose_run
	cd $(1) && $(COMPOSE) $(2)
endef

define compose_loop
	@for dir in $(1); do \
		echo "==> $$dir"; \
		cd "$(CURDIR)/$$dir" && $(COMPOSE) $(2); \
	done
endef

define infra_stack_targets
infra-$(1)-up:
	$(call compose_run,$(2),up -d)

infra-$(1)-down:
	$(call compose_run,$(2),down)

infra-$(1)-restart:
	$(call compose_run,$(2),down)
	$(call compose_run,$(2),up -d)

infra-$(1)-logs:
	$(call compose_run,$(2),logs -f --tail=200)

infra-$(1)-ps:
	$(call compose_run,$(2),ps)

infra-$(1)-update:
	$(call compose_run,$(2),pull)
	$(call compose_run,$(2),up -d --remove-orphans)
endef

bootstrap: 
	./scripts/bootstrap.sh
	./scripts/bootstrap-verify.sh
	
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

smoke-test:
	./scripts/smoke-test.sh

backup:
	./scripts/backup-appdata.sh

recyclarr:
	cd $(STACK_DIR) && $(COMPOSE) run --rm recyclarr sync

infra-up:
	$(call compose_loop,$(INFRA_STACK_DIRS),up -d)

infra-down:
	$(call compose_loop,$(INFRA_STACK_DIRS),down)

infra-restart:
	$(call compose_loop,$(INFRA_STACK_DIRS),down)
	$(call compose_loop,$(INFRA_STACK_DIRS),up -d)

infra-ps:
	$(call compose_loop,$(INFRA_STACK_DIRS),ps)

infra-update:
	$(call compose_loop,$(INFRA_STACK_DIRS),pull)
	$(call compose_loop,$(INFRA_STACK_DIRS),up -d --remove-orphans)

$(eval $(call infra_stack_targets,homarr,$(INFRA_HOMARR_DIR)))
$(eval $(call infra_stack_targets,portainer,$(INFRA_PORTAINER_DIR)))
$(eval $(call infra_stack_targets,pihole,$(INFRA_PIHOLE_DIR)))
$(eval $(call infra_stack_targets,dozzle,$(INFRA_DOZZLE_DIR)))
$(eval $(call infra_stack_targets,netdata,$(INFRA_NETDATA_DIR)))
$(eval $(call infra_stack_targets,uptime-kuma,$(INFRA_UPTIME_KUMA_DIR)))
$(eval $(call infra_stack_targets,caddy,$(INFRA_CADDY_DIR)))
$(eval $(call infra_stack_targets,bitmagnet,$(INFRA_BITMAGNET_DIR)))
$(eval $(call infra_stack_targets,vaultwarden,$(INFRA_VAULTWARDEN_DIR)))
