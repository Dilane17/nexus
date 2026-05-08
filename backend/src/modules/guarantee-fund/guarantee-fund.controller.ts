import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
} from '@nestjs/swagger';
import { GuaranteeFundService } from './guarantee-fund.service';
import { JwtAuthGuard } from '@modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@shared/guards/roles.guard';
import { Roles } from '@shared/decorators/roles.decorator';

@ApiTags('Guarantee Fund')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('guarantee-fund')
export class GuaranteeFundController {
  constructor(private readonly guaranteeFundService: GuaranteeFundService) {}

  // ── État du fonds ────────────────────────────────────────────────────────────

  @Get('status')
  @ApiOperation({
    summary: 'État actuel du fonds de garantie (ratio, suspension, capital)',
  })
  async getStatus() {
    const data = await this.guaranteeFundService.getFundStatus();
    return {
      success: true,
      data,
      message: 'État du fonds de garantie récupéré',
    };
  }

  // ── Investissements couverts ─────────────────────────────────────────────────

  @Get('investments')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({
    summary: '[Admin] Liste des investissements couverts par le fonds',
  })
  async getInvestments() {
    const data = await this.guaranteeFundService.getGuaranteedInvestments();
    return {
      success: true,
      data,
      message: 'Investissements couverts récupérés',
    };
  }

  // ── Activer garantie ─────────────────────────────────────────────────────────

  @Post('activate/:investmentId')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({
    summary: '[Admin] Activer la couverture du fonds pour un investissement',
  })
  @ApiParam({ name: 'investmentId', description: "UUID de l'investissement" })
  async activate(@Param('investmentId', ParseUUIDPipe) investmentId: string) {
    const data =
      await this.guaranteeFundService.activateGuarantee(investmentId);
    return {
      success: true,
      data,
      message: "Garantie activée pour l'investissement",
    };
  }
}
