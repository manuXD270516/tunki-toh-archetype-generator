package ${package}.${tipo}.${micro};

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("local")
class SipToh${Micro}ApplicationTest {

    @Test
    void contextLoads() {
    }
}
