package application;

import application.ibmcloud.ServiceMappings;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SBApplication {

    @Autowired
    ServiceMappings serviceMappings;

    public static void main(String[] args) {
        SpringApplication.run(SBApplication.class, args);
    }
}
