import { Injectable } from "@nestjs/common";
import { SupertokensService } from "./supertokens/supertokens.service";
import { ConfigService } from "@nestjs/config";

import { UserService } from "../user/user.service";

@Injectable()
export class AuthService extends SupertokensService {
  constructor(
    protected readonly configService: ConfigService,
    protected readonly userService: UserService
  ) {
    super(configService, userService);
  }
}
