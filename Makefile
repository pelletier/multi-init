export GOOS:=linux
export GOARCH:=amd64

bin := multi-init
dist.out := multi-init_$(GOOS)_$(GOARCH).tar.xz
tiny := false

upx.version := 3.96
upx.name := upx-$(upx.version)-$(GOARCH)_$(GOOS)
upx.url := https://github.com/upx/upx/releases/download/v3.96/$(upx.name).tar.xz

all: multi-init

$(bin): cmd/multi-init/main.go
	go build -o $@ -ldflags="-s -w" $^
	if [ $(tiny) = "true" ]; then \
		rm -rf .tmp && mkdir -p .tmp \
		&& curl -L $(upx.url) \
		| tar -C .tmp -xJf - $(upx.name)/upx && ./.tmp/$(upx.name)/upx $@ \
		&& rm -rf .tmp; \
	fi

.PHONY:
dist: $(dist.out)

$(dist.out): $(bin)
	tar -cJf $@ $^

.PHONY:
clean:
	rm -Rf $(bin) $(dist.out) .tmp
