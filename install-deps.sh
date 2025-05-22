#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "ОШИБКА: Требуются права root!"
    echo "Пожалуйста, запустите скрипт с помощью sudo: sudo $0"
    exit 1
fi

echo "Обновление пакетов..."
if ! apt-get update -qq; then
    echo "Ошибка при обновлении списка пакетов"
    exit 1
fi

# Установка зависимостей
DEPS=(
	openvpn
	iptables
        dh-make
        devscripts
        build-essential
	prometheus-node-exporter
	golang
)

echo "Установка пакетов: ${DEPS[*]}"
if ! apt-get install -y "${DEPS[@]}"; then
    echo "Ошибка при установке пакетов"
    exit 1
fi

# Добавить правило IPtables

iptables-save > /etc/iptables/rules.v4.save

if ! iptables -C INPUT -p tcp --dport 9100 -j ACCEPT > /dev/null 2>&1; then
     echo "iptables -A INPUT -p tcp --dport 9100 -j ACCEPT"
     iptables -A INPUT -p tcp --dport 9100 -j ACCEPT
fi

netfilter-persistent save
systemctl restart iptables

# проверка PATH для go
if [[ ":$PATH:" != *":/usr/bin/go"* ]]; then
  NEWPATH="$(echo $PATH):/usr/bin/go"
  echo PATH='"'$NEWPATH'"' | tee /etc/environment
  source /etc/environment 
fi

echo "Все зависимости установлены успешно"
