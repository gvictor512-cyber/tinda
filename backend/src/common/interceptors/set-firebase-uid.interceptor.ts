import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';

/**
 * Inyecta `app.firebase_uid` en la sesión de PostgreSQL antes de cada request.
 * Necesario para que las políticas de Row Level Security (RLS) basadas en
 * `current_setting('app.firebase_uid', true)` se apliquen correctamente.
 *
 * NOTA: funciona siempre y cuando el pool de conexiones de TypeORM use la misma
 * conexión a lo largo del request. Si una request dispara varias consultas en
 * conexiones diferentes, esas consultas no verán la variable. En ese caso se
 * recomienda envolver el request en una transacción con queryRunner o aplicar
 * el filtro a nivel de servicio en lugar de RLS.
 */
@Injectable()
export class SetFirebaseUidInterceptor implements NestInterceptor {
  constructor(private readonly dataSource: DataSource) {}

  async intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<Observable<unknown>> {
    const request = context.switchToHttp().getRequest();
    const firebaseUid = request.user?.uid as string | undefined;

    if (firebaseUid) {
      await this.dataSource.query('SET app.firebase_uid = $1', [firebaseUid]);
    }

    return next.handle().pipe(
      finalize(async () => {
        if (firebaseUid) {
          try {
            await this.dataSource.query('RESET app.firebase_uid');
          } catch {
            // Si falla el reset, no bloqueamos la respuesta
          }
        }
      }),
    );
  }
}
