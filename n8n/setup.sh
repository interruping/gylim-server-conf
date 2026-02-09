#!/bin/bash
set -e

source .env

echo "=== n8n + Nginx + PostgreSQL 초기 설정 ==="
echo "도메인: ${DOMAIN_NAME}"
echo "로컬 IP: ${LOCAL_IP}"
echo ""

# ─── Phase 1: 로컬 전용 HTTP 기동 ───
echo "[1/6] HTTP 모드로 서비스 시작 (LAN 전용)..."
BIND_ADDRESS=${LOCAL_IP} \
NGINX_TEMPLATE=http.conf.template \
N8N_PROTOCOL=http \
N8N_HOST=${LOCAL_IP} \
N8N_SECURE_COOKIE=false \
WEBHOOK_URL=http://${LOCAL_IP}/ \
docker compose up -d postgres n8n nginx

echo "[2/6] 서비스 기동 대기 중..."
sleep 10

echo ""
echo "=== 관리자 계정을 생성하세요 ==="
echo "같은 네트워크의 PC에서 http://${LOCAL_IP} 접속 후"
echo "관리자 계정을 생성하고 Enter 를 눌러주세요."
echo ""
read -p "[3/6] 관리자 계정 생성 완료 → Enter..."

# ─── Phase 2: SSL + 외부 접근 개방 ───
echo ""
echo "=== 외부 접근 설정 ==="
echo "계속하기 전에 아래 사항을 확인하세요:"
echo "  1. DNS: ${DOMAIN_NAME} → 공인 IP 연결"
echo "  2. 포트포워딩: 80, 443 포트 → 이 서버로 전달"
echo ""
read -p "[4/6] DNS 및 포트포워딩 준비 완료 → Enter..."

echo "[5/6] Let's Encrypt 인증서 발급 중..."
NGINX_TEMPLATE=http.conf.template docker compose up -d nginx
sleep 5

docker compose run --rm --entrypoint "certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${SSL_EMAIL} \
    --agree-tos \
    --no-eff-email \
    -d ${DOMAIN_NAME}" certbot

echo "[6/6] HTTPS 모드 전환 + 외부 접근 개방..."
docker compose up -d

echo ""
echo "=== 설정 완료! ==="
echo "https://${DOMAIN_NAME} 으로 접속 가능합니다."
