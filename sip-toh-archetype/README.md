# sip-toh-archetype

Módulo Maven **archetype** dentro de **sip-toh-platform**. Genera microservicios Tunki TOH v3.4 con arquitectura hexagonal (Spring Boot, MongoDB, Redis, clientes Core).

- **Coordenadas:** `pe.oh.sip:sip-toh-archetype:1.0.0`
- **Packaging:** `maven-archetype`

## Build

Este módulo declara parent `pe.oh.sip:sip-toh-platform:1.0.0`. Para compilarlo e instalarlo en el repositorio local Maven:

1. Desde el repositorio **sip-toh-platform** completo (recomendado):

   ```bash
   cd sip-toh-platform
   mvn clean install
   ```

2. O instala primero el POM agregador `sip-toh-platform` y luego este módulo, según tu layout interno.

## Uso

Tras `mvn install` del archetype:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=pe.oh.sip \
  -DarchetypeArtifactId=sip-toh-archetype \
  -DarchetypeVersion=1.0.0 \
  -DgroupId=pe.oh.sip \
  -DartifactId=mi-ms \
  -Dversion=1.0.0-SNAPSHOT \
  -Dtipo=pd \
  -Dmicro=home \
  -DMicro=Home
```

Propiedades principales: `tipo` (`pd` | `bs` | `jn`), `micro`, `Micro`, `javaVersion`, `msName`, `dbName` (ver `META-INF/maven/archetype-metadata.xml`).

## Contenido

- `src/main/resources/META-INF/maven/archetype-metadata.xml` — descriptor y propiedades.
- `src/main/resources/archetype-resources/` — plantilla del microservicio generado.
