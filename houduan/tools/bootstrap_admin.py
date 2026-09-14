#!/usr/bin/env python3
"""只生成首次空库的初始化SQL，不自动连接或修改任何数据库。"""
import base64
import getpass
import hashlib
import os
from pathlib import Path

def quote(value):
    return "'" + value.replace("'", "''") + "'"

def main():
    print('仅用于Flyway已建表、业务数据完全为空的新库。不会连接数据库。')
    password = getpass.getpass('设置 bootstrap_admin 密码（至少14位，含字母和数字）：')
    if len(password)<14 or not any(c.isalpha() for c in password) or not any(c.isdigit() for c in password):
        raise SystemExit('密码不满足要求。')
    if getpass.getpass('再次输入：') != password:
        raise SystemExit('两次密码不一致。')
    salt=os.urandom(16)
    digest=hashlib.pbkdf2_hmac('sha256',password.encode(),salt,600000,32)
    encoded='$pbkdf2-sha256$600000$'+base64.b64encode(salt).decode()+'$'+base64.b64encode(digest).decode()
    common='notice:read file:write device:write'
    roles={
        'STUDENT':('学生',1,'teaching:read enrollment:write leave:write life:write affairs:apply attendance:sign '+common),
        'TEACHER':('任课教师',2,'teaching:read teaching:write grade:write notice:publish attendance:write report:export '+common),
        'COUNSELOR':('辅导员',3,'affairs:write affairs:handle aid:review focus:write focus:read leave:counselor notice:publish '+common),
        'SECRETARY':('教学秘书',4,'grade:review teaching:read report:export '+common),
        'DEAN':('院系负责人',4,'leave:dean affairs:handle aid:review notice:publish '+common),
        'ADMIN':('系统管理员',5,'admin:read admin:write admin:grant audit:read report:export teaching:read teaching:write notice:publish '+common),
    }
    permissions=sorted({p for _,_,codes in roles.values() for p in codes.split()})
    roles['SECURITY_ADMIN']=('初始化安全管理员',5,' '.join(permissions))
    sql=['-- 只允许在业务空库执行；先人工确认SELECT COUNT(*) FROM user为0。','-- 整个脚本须一次执行，任何语句失败应ROLLBACK，不继续运行。','START TRANSACTION;',"INSERT INTO org_unit(org_code,org_name,org_type) VALUES ('INITIAL_SCHOOL','请修改为学校名称',1);",'SET @school_id=LAST_INSERT_ID();']
    for p in permissions:
        sql.append(f'INSERT INTO permission(permission_code,permission_name,permission_type) VALUES ({quote(p)},{quote(p)},3);')
    for code,(name,scope,codes) in roles.items():
        sql.append(f'INSERT INTO role(role_code,role_name,scope_type) VALUES ({quote(code)},{quote(name)},{scope});')
        sql.append('SET @role_id=LAST_INSERT_ID();')
        sql.append('INSERT INTO role_permission(role_id,permission_id) SELECT @role_id,id FROM permission WHERE permission_code IN ('+','.join(quote(p) for p in codes.split())+');')
    sql += [f"INSERT INTO user(user_name,password_hash,real_name,org_id) VALUES ('bootstrap_admin',{quote(encoded)},'初始化管理员',@school_id);",'SET @user_id=LAST_INSERT_ID();',"INSERT INTO user_role(user_id,role_id) SELECT @user_id,id FROM role WHERE role_code='SECURITY_ADMIN';",'COMMIT;']
    output=Path(__file__).resolve().parents[1]/'deploy/bootstrap-admin.sql'
    descriptor=os.open(output,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(descriptor,'w',encoding='utf-8') as f:f.write('\n'.join(sql)+'\n')
    print('已生成 deploy/bootstrap-admin.sql。请交由数据库负责人审核后执行；脚本含凭据哈希，请妥善保管。')

if __name__=='__main__':main()
