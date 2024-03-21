
install:
	mkdir -p ${HOME}/helpers
	cp *.bash ${HOME}/helpers
	for file in ${HOME}/helpers/*.bash; do \
		grep -q "source $$file" ${HOME}/.bashrc || \
		echo "source $$file" >> ${HOME}/.bashrc; \
	done;
