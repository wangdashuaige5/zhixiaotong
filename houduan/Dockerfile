FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build
COPY pom.xml ./
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
RUN mkdir -p /app/data/files && chown -R 10001:10001 /app
COPY --from=builder /build/target/zhixiaotong-backend-1.0.0.jar /app/app.jar
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["java","-Duser.timezone=Asia/Shanghai","-XX:MaxRAMPercentage=70","-jar","/app/app.jar"]
