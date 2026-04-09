# sip-toh-platform

Monorepo Maven **Tunki TOH v3.4**: parent POM, librerías compartidas SIP y arquetipo para generar microservicios con arquitectura hexagonal.

## Módulos

| Módulo | Artefacto | Descripción |
|--------|-----------|-------------|
| `sip-toh-parent` | `pe.oh.sip:sip-toh-parent` | Parent Spring Boot 3.4.x, Java 21, gestión de dependencias |
| `sip-exception-handler` | `sip-exception-handler` | Manejo estandarizado de errores |
| `sip-core-client` | `sip-core-client` | Cliente HTTP hacia servicios Core |
| `sip-endpoint-timeout` | `sip-endpoint-timeout` | Soporte `@EndpointTimeout` por endpoint |
| `sip-toh-archetype` | `sip-toh-archetype` | Maven archetype para nuevos MS |

## Build

```bash
cd sip-toh-platform
mvn clean install
```

Orden del reactor: parent → librerías → archetype.

## Publicación

`distributionManagement` apunta al feed Maven de Azure Artifacts (`BackendArtifactsInDigitalpePro@Local`). Requiere credenciales configuradas en `settings.xml` para `deploy`.

## Arquetipo

Ver `sip-toh-archetype/README.md` para generar un microservicio con `mvn archetype:generate`.
