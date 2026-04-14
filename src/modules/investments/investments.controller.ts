import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('Investments')
@Controller('investments')
export class InvestmentsController {}
