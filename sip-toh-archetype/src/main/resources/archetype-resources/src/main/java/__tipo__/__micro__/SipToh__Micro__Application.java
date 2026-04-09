#set( $symbol_pound = '#' )
#set( $symbol_dollar = '$' )
package ${package}.${tipo}.${micro};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SipToh${Micro}Application {

    public static void main(String[] args) {
        SpringApplication.run(SipToh${Micro}Application.class, args);
    }
}
