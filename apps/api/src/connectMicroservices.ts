import { INestApplication } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { grpcClientOptions } from "./grpc.client.options";
import { generateRabbitMQClientOptions } from "./rabbitmq/generateRabbitMQClientOptions";
import { MicroserviceOptions } from "@nestjs/microservices";
import { RabbitMQ } from "./rabbitmq/rabbitmq.transport";
import supertokens from "supertokens-node";
import { generateSupertokensOptions } from "./auth/supertokens/generateSupertokensOptions";
import { STAuthFilter } from "./auth/supertokens/auth.filter";

export async function connectMicroservices(app: INestApplication) {
  const configService = app.get(ConfigService);
  app.connectMicroservice<MicroserviceOptions>(grpcClientOptions);

  app.enableCors({
    origin: [generateSupertokensOptions(configService).appInfo.websiteDomain],
    allowedHeaders: ["content-type", ...supertokens.getAllCORSHeaders()],
    credentials: true
  });

  app.useGlobalFilters(new STAuthFilter());
}
