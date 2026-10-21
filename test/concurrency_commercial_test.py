#!/usr/bin/env python3
"""
Test de Concurrencia Real para el Ciclo Comercial de Negociaciones
PostgreSQL Local: postgresql://postgres:postgres@127.0.0.1:54322/postgres

Escenarios concurrentes:
1. Dos compradores intentan reservar cantidades que, sumadas, superan el stock disponible.
2. Dos solicitudes intentan cancelar la misma negociación simultáneamente.
3. Dos solicitudes intentan aceptar simultáneamente la misma negociación.
4. Una cancelación coincide con una operación que intenta completar la misma negociación.
"""

import subprocess
import time
import json
import threading
import sys

DB_URL = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"

def run_sql(query):
    result = subprocess.run(
        ["psql", DB_URL, "-t", "-A", "-c", query],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        raise Exception(f"SQL Error: {result.stderr.strip()}")
    lines = [l.strip() for l in result.stdout.strip().splitlines() if l.strip() and l.strip() not in ('SET', 'BEGIN', 'COMMIT')]
    return lines[-1] if lines else ""

def exec_as_user(user_id, sql_command):
    cmd = f"""
    SET ROLE authenticated;
    SET request.jwt.claims = '{{"sub": "{user_id}", "role": "authenticated"}}';
    {sql_command}
    """
    result = subprocess.run(
        ["psql", DB_URL, "-v", "ON_ERROR_STOP=1", "-c", cmd],
        capture_output=True,
        text=True
    )
    return result.returncode, result.stdout.strip(), result.stderr.strip()

def setup_base_data():
    setup_sql = """
    DELETE FROM public.inventory_movements WHERE crop_id IN ('e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002');
    DELETE FROM public.negotiation_offers WHERE sender_id IN ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003');
    DELETE FROM public.negotiations WHERE crop_id IN ('e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002');
    DELETE FROM public.crops WHERE id IN ('e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002');
    DELETE FROM public.profiles WHERE id IN ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003');
    DELETE FROM auth.users WHERE id IN ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003');

    INSERT INTO auth.users (id, email) VALUES
        ('f0000000-0000-0000-0000-000000000001', 'conc_farmer@test.com'),
        ('f0000000-0000-0000-0000-000000000002', 'conc_buyer1@test.com'),
        ('f0000000-0000-0000-0000-000000000003', 'conc_buyer2@test.com');

    INSERT INTO public.profiles (id, phone, role, verification_status, full_name) VALUES
        ('f0000000-0000-0000-0000-000000000001', '3200000001', 'agricultor', 'aprobado', 'Farmer Concurrency'),
        ('f0000000-0000-0000-0000-000000000002', '3200000002', 'comprador', 'aprobado', 'Buyer 1 Concurrency'),
        ('f0000000-0000-0000-0000-000000000003', '3200000003', 'comprador', 'aprobado', 'Buyer 2 Concurrency');

    INSERT INTO public.crops (id, farmer_id, title, description, crop_type, price_per_kg, stock_total, stock_committed, stock_sold, min_order_kg, department, municipality, status)
    VALUES ('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'Maiz Amarillo', 'Grano seco', 'Maiz', 1500, 1000, 0, 0, 50, 'Tolima', 'Espinal', 'activa');
    """
    run_sql(setup_sql)

def test_c1_concurrent_overbooking():
    print("\n--- Test C1: Dos compradores intentan reservar cantidades que superan el stock disponible ---")
    setup_base_data()
    buyer1_id = 'f0000000-0000-0000-0000-000000000002'
    buyer2_id = 'f0000000-0000-0000-0000-000000000003'
    crop_id = 'e0000000-0000-0000-0000-000000000001'

    # Ambas propuestas de 600 kg compiten por 1000 kg y reservan al crearse.
    results = [None, None]
    barrier = threading.Barrier(2)

    def worker(idx, buyer_id, delivery, message):
        barrier.wait()
        results[idx] = exec_as_user(
            buyer_id,
            f"SELECT public.create_negotiation_with_offer('{crop_id}', 600, 1500, '{delivery}', '{message}')->>'id';"
        )

    t1 = threading.Thread(target=worker, args=(0, buyer1_id, 'en_finca', 'B1 600kg'))
    t2 = threading.Thread(target=worker, args=(1, buyer2_id, 'transportadora', 'B2 600kg'))
    t1.start()
    t2.start()
    t1.join()
    t2.join()

    successes = sum(1 for r in results if r[0] == 0)
    failures = sum(1 for r in results if r[0] != 0)

    # Validar inventario en base de datos
    committed = float(run_sql(f"SELECT stock_committed FROM public.crops WHERE id = '{crop_id}';"))
    reservations = int(run_sql(f"SELECT count(*) FROM public.inventory_movements WHERE crop_id = '{crop_id}' AND movement_type = 'reserva';"))
    negotiations = int(run_sql(f"SELECT count(*) FROM public.negotiations WHERE crop_id = '{crop_id}';"))

    print(f"Resultados concurrentes: {successes} exitosos, {failures} rechazados")
    print(f"Stock comprometido en DB: {committed} kg (esperado: 600.0 kg)")
    print(f"Movimientos de reserva: {reservations} (esperado: 1)")
    print(f"Negociaciones creadas: {negotiations} (esperado: 1)")

    if successes == 1 and failures == 1 and committed == 600.0 and reservations == 1 and negotiations == 1:
        print("VEREDICTO C1: APROBADO (Prevención estricta de sobreventa por bloqueo FOR UPDATE)")
        return True
    else:
        print("VEREDICTO C1: FALLIDO")
        return False

def test_c2_concurrent_cancellation():
    print("\n--- Test C2: Dos solicitudes intentan cancelar la misma negociación simultáneamente ---")
    setup_base_data()
    farmer_id = 'f0000000-0000-0000-0000-000000000001'
    buyer1_id = 'f0000000-0000-0000-0000-000000000002'
    crop_id = 'e0000000-0000-0000-0000-000000000001'

    # Crear y acordar negociación de 400 kg
    neg_id = run_sql(f"""
        SET ROLE authenticated;
        SET request.jwt.claims = '{{"sub": "{buyer1_id}", "role": "authenticated"}}';
        SELECT public.create_negotiation_with_offer('{crop_id}', 400, 1500, 'en_finca', 'B1 400kg')->>'id';
    """)

    run_sql(f"""
        SET ROLE authenticated;
        SET request.jwt.claims = '{{"sub": "{farmer_id}", "role": "authenticated"}}';
        SELECT public.accept_negotiation('{neg_id}');
    """)

    results = [None, None]
    barrier = threading.Barrier(2)

    def worker(idx):
        barrier.wait()
        results[idx] = exec_as_user(buyer1_id, f"SELECT public.cancel_negotiation('{neg_id}', 'Cancelacion concurrente {idx}');")

    t1 = threading.Thread(target=worker, args=(0,))
    t2 = threading.Thread(target=worker, args=(1,))
    t1.start()
    t2.start()
    t1.join()
    t2.join()

    successes = sum(1 for r in results if r[0] == 0)
    failures = sum(1 for r in results if r[0] != 0)

    committed = float(run_sql(f"SELECT stock_committed FROM public.crops WHERE id = '{crop_id}';"))
    liberations = int(run_sql(f"SELECT count(*) FROM public.inventory_movements WHERE negotiation_id = '{neg_id}' AND movement_type = 'liberacion_reserva';"))

    print(f"Resultados concurrentes: {successes} exitosos, {failures} rechazados")
    print(f"Stock comprometido final: {committed} kg (esperado: 0.0 kg)")
    print(f"Movimientos de liberación de reserva: {liberations} (esperado: 1)")

    if successes == 1 and failures == 1 and committed == 0.0 and liberations == 1:
        print("VEREDICTO C2: APROBADO (Liberación exactamente una vez, bloqueo de doble cancelación)")
        return True
    else:
        print("VEREDICTO C2: FALLIDO")
        return False

def test_c3_concurrent_double_acceptance():
    print("\n--- Test C3: Dos solicitudes intentan aceptar simultáneamente la misma negociación ---")
    setup_base_data()
    farmer_id = 'f0000000-0000-0000-0000-000000000001'
    buyer1_id = 'f0000000-0000-0000-0000-000000000002'
    crop_id = 'e0000000-0000-0000-0000-000000000001'

    neg_id = run_sql(f"""
        SET ROLE authenticated;
        SET request.jwt.claims = '{{"sub": "{buyer1_id}", "role": "authenticated"}}';
        SELECT public.create_negotiation_with_offer('{crop_id}', 300, 1500, 'en_finca', 'Propuesta 300kg')->>'id';
    """)

    results = [None, None]
    barrier = threading.Barrier(2)

    def worker(idx):
        barrier.wait()
        results[idx] = exec_as_user(farmer_id, f"SELECT public.accept_negotiation('{neg_id}');")

    t1 = threading.Thread(target=worker, args=(0,))
    t2 = threading.Thread(target=worker, args=(1,))
    t1.start()
    t2.start()
    t1.join()
    t2.join()

    successes = sum(1 for r in results if r[0] == 0)
    failures = sum(1 for r in results if r[0] != 0)

    committed = float(run_sql(f"SELECT stock_committed FROM public.crops WHERE id = '{crop_id}';"))
    reservations = int(run_sql(f"SELECT count(*) FROM public.inventory_movements WHERE negotiation_id = '{neg_id}' AND movement_type = 'reserva';"))

    print(f"Resultados concurrentes: {successes} exitosos, {failures} rechazados")
    print(f"Stock comprometido: {committed} kg (esperado: 300.0 kg)")
    print(f"Movimientos de reserva: {reservations} (esperado: 1)")

    if successes == 1 and failures == 1 and committed == 300.0 and reservations == 1:
        print("VEREDICTO C3: APROBADO (Aceptación serializada, rechazo de re-aceptación con 22000)")
        return True
    else:
        print("VEREDICTO C3: FALLIDO")
        return False

def test_c4_concurrent_complete_vs_cancel():
    print("\n--- Test C4: Una cancelación coincide con una completitud simultánea del mismo trato ---")
    setup_base_data()
    farmer_id = 'f0000000-0000-0000-0000-000000000001'
    buyer1_id = 'f0000000-0000-0000-0000-000000000002'
    crop_id = 'e0000000-0000-0000-0000-000000000001'

    neg_id = run_sql(f"""
        SET ROLE authenticated;
        SET request.jwt.claims = '{{"sub": "{buyer1_id}", "role": "authenticated"}}';
        SELECT public.create_negotiation_with_offer('{crop_id}', 250, 1500, 'en_finca', 'Propuesta 250kg')->>'id';
    """)

    run_sql(f"""
        SET ROLE authenticated;
        SET request.jwt.claims = '{{"sub": "{farmer_id}", "role": "authenticated"}}';
        SELECT public.accept_negotiation('{neg_id}');
    """)

    results = [None, None]
    barrier = threading.Barrier(2)

    def worker_complete():
        barrier.wait()
        results[0] = exec_as_user(farmer_id, f"SELECT public.complete_negotiation('{neg_id}');")

    def worker_cancel():
        barrier.wait()
        results[1] = exec_as_user(buyer1_id, f"SELECT public.cancel_negotiation('{neg_id}', 'Cancelo simultaneo');")

    t1 = threading.Thread(target=worker_complete)
    t2 = threading.Thread(target=worker_cancel)
    t1.start()
    t2.start()
    t1.join()
    t2.join()

    successes = sum(1 for r in results if r[0] == 0)
    failures = sum(1 for r in results if r[0] != 0)

    status = run_sql(f"SELECT status FROM public.negotiations WHERE id = '{neg_id}';")
    committed = float(run_sql(f"SELECT stock_committed FROM public.crops WHERE id = '{crop_id}';"))
    sold = float(run_sql(f"SELECT stock_sold FROM public.crops WHERE id = '{crop_id}';"))

    print(f"Resultados concurrentes: {successes} exitoso, {failures} rechazado")
    print(f"Estado final de la negociación: '{status}'")
    print(f"Stock comprometido: {committed} kg, Vendido: {sold} kg")

    consistent = (
        (status == 'completada' and sold == 250.0 and committed == 0.0) or
        (status == 'cancelada' and sold == 0.0 and committed == 0.0)
    )

    if successes == 1 and failures == 1 and consistent:
        print("VEREDICTO C4: APROBADO (Atomicidad estricta entre completitud y cancelación)")
        return True
    else:
        print("VEREDICTO C4: FALLIDO")
        return False

def cleanup():
    clean_sql = """
    DELETE FROM public.inventory_movements WHERE crop_id IN ('e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002');
    DELETE FROM public.negotiation_offers WHERE sender_id IN ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003');
    DELETE FROM public.negotiations WHERE crop_id IN ('e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002');
    DELETE FROM public.crops WHERE id IN ('e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002');
    DELETE FROM public.profiles WHERE id IN ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003');
    DELETE FROM auth.users WHERE id IN ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003');
    """
    run_sql(clean_sql)

if __name__ == '__main__':
    print("=================================================================")
    print("INICIANDO PRUEBAS DE CONCURRENCIA REAL EN POSTGRESQL LOCAL")
    print("=================================================================")
    all_passed = True
    try:
        if not test_c1_concurrent_overbooking(): all_passed = False
        if not test_c2_concurrent_cancellation(): all_passed = False
        if not test_c3_concurrent_double_acceptance(): all_passed = False
        if not test_c4_concurrent_complete_vs_cancel(): all_passed = False
    finally:
        cleanup()

    print("\n=================================================================")
    if all_passed:
        print("TODAS LAS PRUEBAS CONCURRENTES FINALIZARON EXITOSAMENTE: APROBADO")
        sys.exit(0)
    else:
        print("ALGUNA PRUEBA CONCURRENTE FALLÓ: FALLIDO")
        sys.exit(1)
