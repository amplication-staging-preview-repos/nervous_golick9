import {
  forwardRef,
  MiddlewareConsumer,
  Module,
  NestModule,
} from "@nestjs/common";
import { STAuthMiddleware } from "./supertokens/auth.middleware";
import { AuthService } from "./auth.service";

import { UserModule } from "../user/user.module";

@Module({
  providers: [AuthService],
  imports: [forwardRef(() => UserModule)],
  exports: [AuthService],
})
export class AuthModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(STAuthMiddleware).forRoutes("*");
  }
}
