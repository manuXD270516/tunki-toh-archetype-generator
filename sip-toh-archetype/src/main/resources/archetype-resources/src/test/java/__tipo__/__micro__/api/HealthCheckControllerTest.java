package ${package}.${tipo}.${micro}.api;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(HealthCheckController.class)
class HealthCheckControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void ping_shouldReturn200WithServiceName() throws Exception {
        mockMvc.perform(get("/${msName}/v1/ping"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.service").value("${msName}"))
            .andExpect(jsonPath("$.status").value("UP"));
    }
}
