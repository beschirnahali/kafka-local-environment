.PHONY: cluster deploy clean test status delete restart

cluster:
	kind create cluster --name kafka --config kind.yaml

deploy:
	./scripts/deploy.sh

status:
	kubectl get pods -n kafka

test:
	./scripts/test-cdc.sh

clean:
	./scripts/cleanup.sh

delete:
	kind delete cluster --name kafka

restart: clean deploy