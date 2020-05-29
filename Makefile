define HELPBODY
Available commands:

	make help       - this thing.

	make init       - install python dependancies
	make test       - run tests and coverage
	make pylint     - code analysis
	make build      - pylint + test
	make docs       - generate html docs using sphinx

	make dist		- build source distribution
	mage register	- register in pypi
	make upload 	- upload to pypi

	make pb_fetch   - fetch protobufs from SteamRE
	make pb_compile - compile with protoc
	make pb_clear   - removes *.proto
	make pb_update  - pb_fetch + pb_compile

endef

export HELPBODY
help:
	@echo "$$HELPBODY"

init:
	pip install -r requirements.txt

test:
	coverage erase
	PYTHONHASHSEED=0 nosetests --verbosity 1 --with-coverage --cover-package=dota2

pylint:
	pylint -r n -f colorized dota2 || true

build: pylint test docs

.FORCE:
docs: .FORCE
	$(MAKE) -C docs html

clean:
	rm -rf dist dota2.egg-info dota2/*.pyc

dist: clean
	python setup.py sdist

register:
	python setup.py register -r pypi

upload: dist register
	twine upload -r pypi dist/*

pb_fetch:
	wget -nv --backups=1 --show-progress -P ./protobufs/ -i protobuf_list.txt
	rm -f ./protobufs/*.1
	sed -i '1s/^/syntax = "proto2"\;\npackage dota\;\n/' protobufs/*.proto
	sed -i 's/\(optional\|repeated\) \.\([A-Z]\)/\1 dota.\2/' protobufs/*.proto
	sed -i 's/cc_generic_services/py_generic_services/' protobufs/*.proto
	sed -i 's/ = 6000/ = 7000/' protobufs/steammessages.proto  # extentions hack

pb_compile:
	for filepath in `ls ./protobufs/*.proto`; do \
		protoc --python_out ./dota2/protobufs/ --proto_path=./protobufs "$$filepath"; \
	done;
	sed -i '/^import sys/! s/^import /import dota2.protobufs./' dota2/protobufs/*_pb2.py

pb_clear:
	rm -f ./protobufs/*.proto ./dota2/protobufs/*_pb2.py

gen_enums:
	python gen_enum_from_protos.py > dota2/proto_enums.py

pb_update: pb_fetch pb_compile gen_enums
