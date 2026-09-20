# NixOS config

Конфиг для домашнего/серверного NixOS-хоста (`fell`).

## Файлы

- `configuration.nix` — основной конфиг: загрузчик, сеть, локаль, пользователи,
  пакеты, fish-шелл, сервисы, файрвол.
- `neovim.nix` — отдельно вынесенный конфиг Neovim (чтобы не раздувать
  `configuration.nix`), подключается через `imports`.
- `hardware-configuration.nix` — автосгенерированный конфиг железа/дисков.
- `flake.nix` / `flake.lock` — флейк и залоченные версии зависимостей.

## Что стоит на системе

- **Шелл**: fish, с алиасами (`dcu`, `dcd`, `dca`, `dcr`, `upd`, `updd`, `cfg`,
  `ncfg` и т.д.) и функцией `dc`, которая печатает шпаргалку по этим алиасам.
- **Редактор**: Neovim как дефолтный редактор, плагины через lazy.nvim
  (гружены из Nix store — офлайн, без интернета при сборке), тема gruvbox,
  telescope, LSP (docker/yaml), автодополнение, gitsigns, which-key и т.д.
- **Docker**: `virtualisation.docker.enable`, плюс `docker-compose`.
- **Сеть**: NetworkManager, OpenSSH, ZeroTier (join к рабочей сети),
  Syncthing (веб-морда на `:8384`).
- **Прочее**: btop, mc, keepassxc/kpcli, fastfetch, git, kitty, starship, nh.

## Как применить

```bash
sudo nixos-rebuild switch
# или
nh os switch
```

Если что-то новое добавил в репозиторий (например, новый `.nix`-файл) — не
забудь `git add`, иначе Nix его не увидит (флейк смотрит только на
отслеженные git файлы):

```bash
git add .
git commit -m "..."
```

## Порты

TCP: `53, 8384 (syncthing), 22000 (syncthing), 51821 (wireguard), 8088`
UDP: `53, 22000 (syncthing), 21027 (syncthing discovery), 51820 (wireguard)`
