package ${package}.${tipo}.${micro}.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.config.EnableMongoAuditing;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

@Configuration
@EnableMongoAuditing
@EnableMongoRepositories(basePackages = "${package}.${tipo}.${micro}.infrastructure.persistence")
public class MongoConfig {
}
