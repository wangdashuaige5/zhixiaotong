#!/usr/bin/env python3
"""本机演示签名回调工具。不能用于正式支付。"""
import argparse
import hashlib
import hmac
import json
import os
import time
import urllib.request
import urllib.error
from decimal import Decimal

parser=argparse.ArgumentParser(description='仅向本机演示服务发送模拟支付回调，无真实扣款。')
parser.add_argument('order_no',help='创建模拟充值后返回的order_no')
parser.add_argument('amount',help='与订单完全一致的金额，如20.00')
parser.add_argument('--port',type=int,default=8080)
parser.add_argument('--trade-no',help='重试必须沿用同一交易号')
args=parser.parse_args()
if not args.order_no.startswith('MOCK-'):
    raise SystemExit('只接受MOCK-开头的演示订单。')
amount=Decimal(args.amount)
if amount<=0 or amount>10000:
    raise SystemExit('金额范围错误。')
trade=args.trade_no or 'MOCK-TRADE-'+hashlib.sha256(args.order_no.encode()).hexdigest()[:24]
body=json.dumps({'order_no':args.order_no,'amount':str(amount),'pay_channel':'MOCK_PAY','pay_trade_no':trade},separators=(',',':')).encode()
stamp=str(int(time.time()))
secret=os.environ.get('PAYMENT_SECRET','demo-only-payment-callback-secret')
signature=hmac.new(secret.encode(),stamp.encode()+b'\n'+body,hashlib.sha256).hexdigest()
request=urllib.request.Request(f'http://127.0.0.1:{args.port}/api/integrations/payments/callback',data=body,headers={'Content-Type':'application/json','X-Payment-Timestamp':stamp,'X-Payment-Signature':signature})
try:
    with urllib.request.urlopen(request,timeout=15) as response:
        print(response.read().decode())
except urllib.error.HTTPError as error:
    print(error.read().decode());raise SystemExit(1)
