# 智校通后端｜小组后端代码-1

依据《智校通-需求说明书》《智校通-详细设计说明书》，以“小组后端代码.rar”的 Controller → Service → ServiceImpl → Mapper → Mapper.xml → PO 分层写法为参考完成。本项目是 **Spring Boot 后端**，可以直接在 VS Code、IDEA 或 Eclipse 中打开；不包含 ArkTS 鸿蒙客户端或 Vue 页面。

## 1. 先运行演示版

推荐安装并启动 Docker Desktop，在本文件夹中打开终端：

```sh
docker compose -f compose.demo.yml up -d --build
docker compose -f compose.demo.yml logs -f app
```

首次会下载镜像、构建程序、创建 MySQL 数据库及演示账号。看到应用启动成功后打开：

- 接口调试页：http://localhost:8080/swagger-ui.html
- 健康检查：http://localhost:8080/actuator/health
- OpenAPI：http://localhost:8080/v3/api-docs

macOS 也可双击 `启动演示.command`；Windows 可双击 `启动演示.bat`。启动失败请检查 Docker 是否运行、网络能否下载镜像，以及8080/13306端口是否被占用。停止使用 `docker compose -f compose.demo.yml stop`，保留数据库和上传文件。不要随意删除 Docker 数据卷。

**仅供本机演示。** 默认接口绑定127.0.0.1；手机联调可在受控局域网调整端口绑定，并设置自己的密钥。切勿把演示账号、公开的模拟支付密钥直接用于公网。

### 演示账号

所有演示账号密码均为 `Demo@123456`，只在首次空库自动生成。数据库中保存随机盐 PBKDF2 哈希，不保存明文密码。

|账号|身份|主要用途|
|---|---|---|
|student_demo|学生|选课、请假、作业、成绩、校园卡与图书|
|student_two|同班学生|测试容量、同班事务|
|student_other|其他班级学生|测试班级数据隔离|
|teacher_demo|任课教师|资料、作业、成绩、签到|
|counselor_demo|辅导员|软件一班请假、学生事务和重点关注|
|secretary_demo|教学秘书|信息工程学院成绩审核|
|dean_demo|院系负责人|超过3天请假和离校第二步|
|admin_demo|管理员|基础数据、排课、授权、报表、审计|

初始有3门课、1个开放补退选批次、1笔模拟借阅、1个资助批次。日期按首次运行时间生成；以后不会重置，过期后需管理端新建批次。演示数据不要求每表凑满5条，避免虚构业务完成状态；以前的“每表5条”SQL已原样单独保留供对照，**不能导入应用现有库**。

演示管理员显式持有除重点关注以外的权限，便于分配学生、教师及院系角色。不能把本人没有的重点关注权限委派给他人；新辅导员的敏感授权需由有权的安全管理员配置。全校范围管理角色不自动充当审批人，自动审批路由选择当前有效的所辖/自定义范围审批人。

## 2. 在 VS Code 中写代码

1. 安装 Java 17、Maven 3.9，以及 VS Code 的 Java Extension Pack。
2. 选择“打开文件夹”，打开整个“小组后端代码-1”，等待 Maven 依赖加载。
3. 启动 MySQL 8.0.16以上版本（建议8.0维护版本）。也可只启动本项目的数据库：

```sh
docker compose -f compose.demo.yml up -d db
```

4. 在终端配置数据库连接，运行源码：

```sh
export DB_URL='jdbc:mysql://127.0.0.1:13306/zhixiaotong?useUnicode=true&characterEncoding=utf8&connectionTimeZone=Asia/Shanghai&forceConnectionTimeZoneToSession=true'
export DB_USER=zhixiaotong
export DB_PASSWORD=campus_demo_2026
mvn spring-boot:run -Dspring-boot.run.profiles=demo
```

Windows PowerShell 的环境变量写法为 `$env:DB_URL='...'`，其余变量同理。若使用已有 MySQL，先建立空库 `zhixiaotong` 并创建自己的数据库账号，替换连接和密码即可。**不需要手动执行建表SQL**，Flyway启动时自动创建57张业务表及迁移记录表。

运行测试与打包：

```sh
mvn test
mvn clean package
java -Duser.timezone=Asia/Shanghai -jar target/zhixiaotong-backend-1.0.0.jar --spring.profiles.active=demo
```

测试使用隔离的 H2 内存数据库，不读取或删除本机 MySQL 数据。打包后的程序仍使用 MySQL。交付目录 `dist/` 中的已编译JAR可直接配合 Java17 与 MySQL 运行；修改源码后应重新打包。

## 3. 怎么联调

打开 `api.http`，先调用登录，复制返回的 `access_token` 填入对应变量。也可在 Swagger 的 Authorize 中填访问令牌。详细设计82个接口均有对应路由，并补充了批次查询、审批待办、用户创建、授权、异步确认等接口。

重要区别：course.id是“课程”，teaching_class.id是“教学班”，batch_course.id是“批次开放课程”。请不要将三个ID混用。所有业务身份由服务端从登录账号取得，不能在请求中替别人指定student_id。

- 字段名全部使用下画线；每表均有自增主键id。
- ID、金额和成绩小数输出为字符串，防止前端精度丢失。
- JSON内容为对象/数组；日期时间使用北京时间，输出带+08:00。
- 先上传附件取得id，再随业务提交file_ids；下载仍重新检查原业务权限。
- 批量导入为UTF-8 CSV，先校验后确认，最多200行；模板在 `examples/`。
- 高风险管理、导入确认必须提交 `confirmed: true`。

详见 `docs/接口说明.md`、`docs/全部接口清单.md`、`docs/实现与边界.md`、`docs/测试报告.md`。

## 4. 目录

```text
src/main/java/com/zhixiaotong/
  controller/       HTTP接口入口
  service/          选课、教学、成绩、请假、学生事务、生活、消息等业务
    impl/           用户与选课服务实现，延续示例接口/实现分层
  mapper/           57个实体Mapper及参数化复杂查询Mapper
  po/               与设计一致的57个实体
  security/         登录身份、权限范围、JWT、会话、限流、加密
  integration/      对象存储和文件扫描实现
  config/           环境、序列化、消息队列和演示初始化
  common/ dto/      公共校验、结果结构、分页、异常处理
src/main/resources/
  mapper/           Mapper XML
  db/migration/     Flyway建表迁移
src/test/           业务规则和集成测试
sql/                57表结构和历史示例SQL
docs/               接口、实现说明和测试记录
deploy/             网关配置、正式联调部署资料
参考代码-原样保留/    用户提供的原始6个示例文件，不参与编译
```

原示例中的医疗业务字段、明文密码及旧版javax.servlet代码没有直接搬入新系统。新代码使用Spring Boot3的jakarta体系；复杂跨表操作由业务服务组织事务，并通过SqlMapper绑定参数，不接受客户端SQL或任意表名。

## 5. 外部系统与正式部署

演示模式中的充值、余额和图书数据是**本地模拟**，没有真实扣款；正式模式默认关闭外部写操作。短信改手机号、真实校园卡/支付/图书同步、HarmonyOS原生推送与设备系统能力，以及正式证明模板/签章，需要学校接口、SDK或客户端配合。它们没有被伪装为已接入。

`compose.prod.yml` 提供 MySQL、Redis、RabbitMQ、MinIO、ClamAV 和 HTTPS Nginx 的正式联调配置，但上线前仍须配置证书、独立密钥、首个管理员、学校接口并完成验收。请先阅读 `deploy/正式部署说明.md`。本机集成测试不能证明500在线用户、真实MySQL并发性能、99.5%可用性或灾难恢复能力已达标。
