# Guia de Uso del Arquetipo SIP TOH v3.4

> **Version:** 1.1 | **Fecha:** 2026-04-08 | **Arquetipo:** `sip-toh-archetype:1.0.0`

> **Repositorio:** Este archivo vive en la **raiz** del proyecto **sip-toh-platform**. La raiz del repo es la carpeta que contiene el `pom.xml` agregador y los modulos `sip-toh-parent/`, `sip-toh-archetype/`, etc. Los microservicios generados suelen ubicarse en un directorio **hermano** del clon (por ejemplo `../` o tu workspace) o donde elijas ejecutar `mvn archetype:generate`.

---

## 1. Prerequisitos

### 1.1 Software Requerido

| Herramienta | Version | Verificacion |
|-------------|---------|-------------|
| JDK | 21+ | `java -version` |
| Maven | 3.9+ | `mvn -version` |
| Docker Desktop | 4.x+ | `docker --version` |
| Git | 2.40+ | `git --version` |
| IntelliJ IDEA | 2024.x+ | Ultimate o Community |

### 1.2 Estructura del Platform

```
sip-toh-platform/              # Raiz de este repositorio Git
├── sip-toh-parent/            # Parent POM (Spring Boot 3.4.3, Java 21)
├── sip-toh-archetype/         # Maven archetype para generar MS
├── sip-core-client/           # Cliente HTTP para core services
├── sip-exception-handler/     # Manejo estandarizado de errores
├── sip-endpoint-timeout/      # @EndpointTimeout por endpoint
├── pom.xml                    # POM agregador
└── archetype-usage-guide.md   # Esta guia

# Ejemplos de MS generados (tipicamente fuera de este repo):
../pd-sip-toh-home/            # (generado) Producto - Home
../bs-sip-toh-card-config/     # (generado) Negocio - Card Config
```

### 1.3 Instalacion Local de Artefactos

Antes de generar cualquier MS, instalar todas las dependencias en el repositorio local Maven.

#### Opcion A — Instalacion automatica (recomendada)

`pom.xml` en la raiz es un **POM agregador** que declara los 5 modulos. Un solo comando instala todo:

```powershell
# Desde la raiz del repositorio sip-toh-platform (donde esta el pom.xml agregador)
cd <raiz-del-clon-sip-toh-platform>
mvn clean install
```

Maven resuelve automaticamente el orden de compilacion (reactor build order):

```
[INFO] Reactor Build Order:
[INFO]   sip-toh-parent          (pom)
[INFO]   sip-exception-handler   (jar)
[INFO]   sip-core-client         (jar)
[INFO]   sip-endpoint-timeout    (jar)
[INFO]   sip-toh-archetype       (maven-archetype)
```

> **Nota:** Solo se necesita ejecutar una vez (o al actualizar el archetype/parent).

#### Opcion B — Instalacion manual (modulo por modulo)

Util si necesitas reinstalar o debuggear un modulo especifico:

```powershell
# 1. Parent POM (siempre primero)
cd <raiz-del-clon-sip-toh-platform>\sip-toh-parent
mvn clean install

# 2. Librerias compartidas (en cualquier orden)
cd ..\sip-exception-handler
mvn clean install

cd ..\sip-core-client
mvn clean install

cd ..\sip-endpoint-timeout
mvn clean install

# 3. Archetype (siempre al final)
cd ..\sip-toh-archetype
mvn clean install
```

> **Importante:** El parent POM debe instalarse primero ya que las 3 librerias heredan de el. El archetype va al final porque empaqueta las referencias a las librerias.

---

## 2. Generacion de un Microservicio

### 2.1 Parametros del Arquetipo

| Parametro | Requerido | Descripcion | Ejemplo |
|-----------|-----------|-------------|---------|
| `tipo` | Si | Capa: `jn` (Journey), `pd` (Producto), `bs` (Negocio) | `bs` |
| `micro` | Si | Nombre del MS en minusculas | `card-config` |
| `Micro` | Si | Nombre capitalizado para clases Java | `CardConfig` |
| `javaVersion` | No | Version de Java (default: 21) | `21` |
| `msName` | Auto | Nombre completo: `{tipo}-sip-toh-{micro}` | `bs-sip-toh-card-config` |
| `dbName` | Auto | Base de datos MongoDB: `sip_{micro}` | `sip_card-config` |

### 2.2 Tabla de Parametros por Microservicio

| MS | tipo | micro | Micro | dbName |
|----|------|-------|-------|--------|
| jn-sip-toh-dispatcher | `jn` | `dispatcher` | `Dispatcher` | `sip_dispatcher` |
| pd-sip-toh-home | `pd` | `home` | `Home` | `sip_home` |
| pd-sip-toh-eecc | `pd` | `eecc` | `Eecc` | `sip_eecc` |
| pd-sip-toh-campaigns | `pd` | `campaigns` | `Campaigns` | `sip_campaigns` |
| pd-sip-toh-installments | `pd` | `installments` | `Installments` | `sip_installments` |
| pd-sip-toh-cash-credit | `pd` | `cashcredit` | `CashCredit` | `sip_cashcredit` |
| pd-sip-toh-cash-advance | `pd` | `cashadvance` | `CashAdvance` | `sip_cashadvance` |
| pd-sip-toh-defer | `pd` | `defer` | `Defer` | `sip_defer` |
| pd-sip-toh-credit-line | `pd` | `creditline` | `CreditLine` | `sip_creditline` |
| bs-sip-toh-payments | `bs` | `payments` | `Payments` | `sip_payments` |
| bs-sip-toh-product-requests | `bs` | `productrequests` | `ProductRequests` | `sip_productrequests` |
| bs-sip-toh-activation | `bs` | `activation` | `Activation` | `sip_activation` |
| bs-sip-toh-card-change-pin | `bs` | `cardchangepin` | `CardChangePin` | `sip_cardchangepin` |
| bs-sip-toh-card-config | `bs` | `cardconfig` | `CardConfig` | `sip_cardconfig` |
| bs-sip-toh-card-cvv-data | `bs` | `cardcvvdata` | `CardCvvData` | `sip_cardcvvdata` |

> **Importante:** El parametro `micro` no puede contener guiones en el nombre del package Java. Usar nombres concatenados (e.g., `cardconfig` no `card-config`).

### 2.3 Comando de Generacion

```powershell
# Posicionarse en el directorio donde se generara el MS (ej. carpeta hermana del clon)
cd <carpeta-destino-del-nuevo-ms>

# Generar el microservicio
mvn archetype:generate `
  -DarchetypeCatalog=local `
  -DarchetypeGroupId=pe.oh.sip `
  -DarchetypeArtifactId=sip-toh-archetype `
  -DarchetypeVersion=1.0.0 `
  -DgroupId=pe.oh.sip `
  -DartifactId=bs-sip-toh-card-config `
  -Dversion=1.0.0-SNAPSHOT `
  -Dtipo=bs `
  -Dmicro=cardconfig `
  -DMicro=CardConfig `
  -DinteractiveMode=false
```

> **Nota PowerShell:** Usar backtick `` ` `` para continuacion de linea (no `\`).

### 2.4 Ejemplo Completo: Generar pd-sip-toh-campaigns

```powershell
cd <carpeta-destino-del-nuevo-ms>

mvn archetype:generate `
  -DarchetypeCatalog=local `
  -DarchetypeGroupId=pe.oh.sip `
  -DarchetypeArtifactId=sip-toh-archetype `
  -DarchetypeVersion=1.0.0 `
  -DgroupId=pe.oh.sip `
  -DartifactId=pd-sip-toh-campaigns `
  -Dversion=1.0.0-SNAPSHOT `
  -Dtipo=pd `
  -Dmicro=campaigns `
  -DMicro=Campaigns `
  -DinteractiveMode=false
```

---

## 3. Estructura Generada

El arquetipo genera un proyecto completo con arquitectura hexagonal:

```
{tipo}-sip-toh-{micro}/
├── pom.xml                           # Hereda de sip-toh-parent:1.0.0
├── Dockerfile                        # Eclipse Temurin JDK 21 Alpine + ZGC
├── docker-compose.yml                # MongoDB 7.0 + Redis 7.4 (dev local)
├── .azure-pipelines.yml              # CI/CD pipeline template
├── .gitignore
├── helm/
│   ├── Chart.yaml                    # Helm chart para GKE
│   └── values.yaml                   # Valores configurables
└── src/
    ├── main/
    │   ├── java/pe/oh/sip/{tipo}/{micro}/
    │   │   ├── SipToh{Micro}Application.java     # Entry point
    │   │   ├── api/
    │   │   │   ├── HealthCheckController.java     # GET /v1/ping
    │   │   │   └── dto/
    │   │   │       ├── request/                   # Request DTOs
    │   │   │       └── response/                  # Response DTOs
    │   │   ├── config/
    │   │   │   ├── CoreClientConfig.java          # RestClient beans
    │   │   │   ├── MongoConfig.java               # MongoDB + auditing
    │   │   │   ├── RedisConfig.java               # Redis standalone
    │   │   │   └── WebConfig.java                 # TraceId filter + MDC
    │   │   ├── domain/
    │   │   │   ├── model/                         # @Document records
    │   │   │   ├── port/
    │   │   │   │   ├── in/                        # Input ports (use cases)
    │   │   │   │   └── out/                       # Output ports (repos, adapters)
    │   │   │   └── service/                       # Domain service implementations
    │   │   └── infrastructure/
    │   │       ├── adapter/                       # Core service adapters
    │   │       ├── cache/                         # Cache adapters (pd-* only)
    │   │       └── persistence/                   # MongoRepository implementations
    │   └── resources/
    │       ├── application.yml                    # Config base
    │       ├── application-local.yml              # Docker Compose / dev
    │       └── application-prod.yml               # Env vars / produccion
    └── test/java/pe/oh/sip/{tipo}/{micro}/
        ├── SipToh{Micro}ApplicationTest.java      # Context load (integration)
        └── api/
            └── HealthCheckControllerTest.java     # Unit test
```

---

## 4. Post-Generacion: Ajustes Necesarios

### 4.1 Recortar `application.yml` (Core Services)

El archetype genera TODOS los core services. Cada MS solo necesita los que usa:

| Microservicio | Core Services Requeridos |
|---------------|-------------------------|
| pd-sip-toh-home | customer, cache |
| pd-sip-toh-eecc | customer, account, cache |
| pd-sip-toh-campaigns | customer, cache |
| pd-sip-toh-installments | customer, account, cache |
| pd-sip-toh-cash-credit | customer, account, cache |
| pd-sip-toh-cash-advance | customer, account, cache |
| pd-sip-toh-defer | customer, account, cache |
| pd-sip-toh-credit-line | customer, account, cache |
| bs-sip-toh-payments | account, user, operation, notification |
| bs-sip-toh-product-requests | customer, account, notification |
| bs-sip-toh-activation | customer, account, notification |
| bs-sip-toh-card-change-pin | user, cache |
| bs-sip-toh-card-config | customer, cache |
| bs-sip-toh-card-cvv-data | user, customer, account |

**Accion:** Eliminar del `application.yml` y `CoreClientConfig.java` los core services no utilizados. Actualizar las instancias de Resilience4j acorde.

### 4.2 Recortar `CoreClientConfig.java`

Eliminar los beans `@Bean RestClient` que no se usen. Ejemplo para `bs-sip-toh-card-config` (solo customer + cache):

```java
@Configuration
public class CoreClientConfig {

    @Bean
    public RestClient coreCustomerClient(RestClient.Builder builder,
            @Value("${core.services.customer.url}") String baseUrl) {
        return CoreClientFactory.create(builder, baseUrl);
    }

    @Bean
    public RestClient coreCacheClient(RestClient.Builder builder,
            @Value("${core.services.cache.url}") String baseUrl) {
        return CoreClientFactory.create(builder, baseUrl);
    }
}
```

### 4.3 Agregar `CacheConfig.java` (solo capa Producto)

Los MS de capa `pd-*` necesitan multi-level cache. Copiar el patron de `pd-sip-toh-home`:

```java
@Configuration
@EnableCaching
public class CacheConfig {
    // L1: Caffeine (local, per-pod)
    // L2: Redis (distribuido, compartido)
    // Ver pd-sip-toh-home/config/CacheConfig.java como referencia
}
```

> **Capa `bs-*`:** NO necesita CacheConfig. Redis se usa solo para distributed locks.

### 4.4 Limpiar package-info.java

Los archivos `package-info.java` en domain/ e infrastructure/ contienen documentacion guia. Reemplazar con las clases reales del MS.

---

## 5. Desarrollo Local

### 5.1 Levantar Infraestructura

```powershell
cd <ruta-a-la-carpeta-del-ms-generado>
docker compose up -d
```

Esto levanta:
- **MongoDB 7.0** en `localhost:27017` (base: `sip_{micro}`)
- **Redis 7.4** en `localhost:6379` (standalone, 128MB)

### 5.2 Configurar IntelliJ IDEA

1. **Abrir proyecto:** File > Open > seleccionar la carpeta del MS
2. **JDK:** Asegurar JDK 21 configurado en Project Structure
3. **Profile Maven:** Activar profile `local` si existe
4. **Run Configuration:**
   - Main class: `pe.oh.sip.{tipo}.{micro}.SipToh{Micro}Application`
   - Active profiles: `local`
   - VM Options:
     ```
     -Djava.io.tmpdir=C:/tmp -Djdk.net.unixdomain.tmpdir=C:/tmp
     ```

> **Windows con espacios en username:** Los flags `-Djava.io.tmpdir` y `-Djdk.net.unixdomain.tmpdir` son obligatorios si tu path de usuario contiene espacios (ej: `C:\Users\Manuel Saavedra`). JDK 21 usa Unix Domain Sockets para el loopback que falla con paths con espacios.

### 5.3 Verificar Health

```powershell
# Health check de Spring Actuator
curl http://localhost:8080/{ms-name}/actuator/health

# Ping del MS
curl http://localhost:8080/{ms-name}/v1/ping
```

Respuesta esperada del `/v1/ping`:
```json
{
  "service": "{ms-name}",
  "status": "UP",
  "timestamp": "2026-04-07T08:00:00.000Z"
}
```

### 5.4 Compilar y Testear

```powershell
# Compilar
cd <ruta-a-la-carpeta-del-ms-generado>
mvn compile

# Ejecutar tests unitarios
mvn test

# Ejecutar tests de integracion (requiere Docker)
mvn test -DintegrationTests=true
```

---

## 6. Patrones de Implementacion

### 6.1 Flujo Hexagonal

```
Request HTTP
    |
    v
[PermissionController]  ----  @EndpointTimeout(TIER_1|TIER_2)
    |
    v
[PermissionUseCase]  --------  Input Port (interface)
    |
    v
[PermissionService]  ---------  Domain Service (implements UseCase)
    |            |
    v            v
[CoreCustomerPort]   [ConfigChangeLogRepository]  --  Output Ports
    |                         |
    v                         v
[CoreCustomerAdapter]  [MongoConfigChangeLogRepository]  --  Infrastructure
    |
    v
us-core-customer (HTTP)
```

### 6.2 Timeout Tiers

| Tier | Timeout | Uso |
|------|---------|-----|
| TIER_1 | 3s | GETs cache-backed, lecturas rapidas |
| TIER_2 | 5s | GETs directos a core, escrituras simples |
| TIER_3 | 10s | Operaciones multi-step, transacciones |
| TIER_4 | 15s | Procesos batch, PDF generation |

### 6.3 Checklist Post-Generacion

- [ ] `mvn archetype:generate` ejecutado exitosamente
- [ ] `application.yml` recortado (solo core services necesarios)
- [ ] `CoreClientConfig.java` recortado (solo beans necesarios)
- [ ] `Resilience4j` instances alineadas con core services
- [ ] `docker compose up -d` levanta MongoDB + Redis
- [ ] `mvn compile` compila sin errores
- [ ] Crear domain models en `domain/model/`
- [ ] Crear input ports en `domain/port/in/`
- [ ] Crear output ports en `domain/port/out/`
- [ ] Implementar services en `domain/service/`
- [ ] Implementar adapters en `infrastructure/adapter/`
- [ ] Implementar repositories en `infrastructure/persistence/`
- [ ] Crear controllers en `api/`
- [ ] Crear DTOs en `api/dto/request/` y `api/dto/response/`
- [ ] Crear unit tests
- [ ] `mvn test` pasa todos los tests

---

## 7. Problemas Conocidos y Soluciones

| Problema | Causa | Solucion |
|----------|-------|----------|
| `Unable to establish loopback connection` | JDK 21 Unix Domain Sockets + path con espacios | `-Djava.io.tmpdir=C:/tmp -Djdk.net.unixdomain.tmpdir=C:/tmp` |
| `@MockBean` no resuelve | Spring Boot 3.4 cambio de package | Usar `@MockitoBean` de `org.springframework.test.context.bean.override.mockito` |
| `jakarta.validation does not exist` | Falta dependencia en sip-exception-handler | Agregar `jakarta.validation-api:3.1.0` con scope `provided` |
| Redis cluster error en local | Base yml tenia `cluster.nodes` | Usar `host`/`port` en base, cluster solo en `application-prod.yml` |
| `Port 8080 already in use` | Proceso Java en background | `netstat -ano | findstr :8080` y `taskkill /PID {pid} /F` |
| Tests 404 en `@WebMvcTest` | `server.servlet.context-path` no aplica en MockMvc | Usar paths sin prefijo de context (ej: `/v1/ping` no `/{ms}/v1/ping`) |
| `spring.http.client.factory` error | JDK HttpClient default falla en Windows | Agregar `spring.http.client.factory: simple` en `application-local.yml` |
| `NoClassDefFoundError: Pointcut` | `@SpringBootTest` carga Resilience4j AOP sin AspectJ | Usar `@WebMvcTest` para unit tests; `@SpringBootTest` solo con integration flag |
