export GOOS := linux
export GOARCH := amd64
export CGO_ENABLED :=0

bin := multi-init
dist.name := multi-init_$(GOOS)_$(GOARCH)
dist.out := $(dist.name).tar.xz
tiny.bin := $(bin)-tiny
tiny.dist.out := $(dist.name)-tiny.tar.xz

upx.version := 3.96
upx.name := upx-$(upx.version)-$(GOARCH)_$(GOOS)
upx.url := https://github.com/upx/upx/releases/download/v3.96/$(upx.name).tar.xz

go := go
go.build := $(go) build -ldflags="-s -w"

all: multi-init

$(bin): cmd/multi-init/main.go
	$(go.build) -o $@ $^

$(tiny.bin): $(bin)
	rm -rf .tmp
	mkdir -p .tmp
	curl -L $(upx.url) | tar -C .tmp -xJf - $(upx.name)/upx
	cp $^ $@
	./.tmp/$(upx.name)/upx $@
	rm -rf .tmp;

.PHONY:
dist: $(dist.out) $(tiny.dist.out)

$(dist.out): $(bin)
	tar -cJf $@ $^

$(tiny.dist.out): $(tiny.bin)
	tar -cJf $@ $^


.PHONY:
clean:
	rm -Rf $(bin) $(tiny.bin) $(dist.out) $(tiny.dist.out) .tmp
