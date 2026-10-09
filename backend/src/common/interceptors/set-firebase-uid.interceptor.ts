import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
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
  private readonly logger = new Logger(SetFirebaseUidInterceptor.name);

  constructor(private readonly dataSource: DataSource) {}

  async intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<Observable<unknown>> {
    const request = context.switchToHttp().getRequest();
    const firebaseUid = request.user?.uid as string | undefined;

    // NOTE: `SET app.firebase_uid = $1` is invalid — PostgreSQL does not
    // allow bound parameters in SET. set_config() accepts parameters and is
    // equivalent here (is_local=false → session scope).
    // Always clear first: the pool can hand us a connection that still has
    // a previous user's uid set.
    //
    // Best-effort: if this query throws (pool exhausted, replica read-only,
    // permission issue…) the request must still proceed — the alternative is
    // an unexplained 500 on EVERY authenticated endpoint (as happened in
    // production). We log the real error so it stays diagnosable.
    try {
      await this.dataSource.query(
        `SELECT set_config('app.firebase_uid', $1, false)`,
        [firebaseUid ?? ''],
      );
    } catch (e) {
      this.logger.error(
        `set_config('app.firebase_uid') failed — RLS uid not applied for this request: ${
          e instanceof Error ? e.message : String(e)
        }`,
      );
    }

    return next.handle().pipe(
      finalize(async () => {
        try {
          await this.dataSource.query(
            `SELECT set_config('app.firebase_uid', '', false)`,
          );
        } catch {
          // Si falla el reset, no bloqueamos la respuesta
        }
      }),
    );
  }
}
