import { PrismaService } from '../prisma/prisma.service';

/**
 * Classe abstraite de base pour implementer le pattern Repository
 * Prisma v7 compatible - Clean Architecture
 *
 * @template T - Type de l'entité domin
 * @template C - Type du create DTO
 * @template U - Type du update DTO
 */
export abstract class BaseRepository<T, C = never, U = never> {
  protected constructor(protected readonly prisma: PrismaService) {}

  /**
   * Génère une liste sûre des colonnes pour éviter d'exposer les champs sensibles
   */
  protected abstract getSelectFields():
    | Record<string, boolean>
    | { [key: string]: any };

  /**
   * Exceptions métier (à implémenter côté applicatif)
   */
  protected handlePrismaError(error: any): never {
    console.error('❌ Prisma Error:', error.message);
    throw new Error(`Data layer error: ${error.code || error.message}`);
  }
}
