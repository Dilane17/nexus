import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('Loans')
@Controller('loans')
export class LoansController {}
