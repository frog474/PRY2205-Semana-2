
-- =====================================================
-- PRY2205 - SEMANA 2
-- CONSULTA DE BASES DE DATOS
-- Usuario: PRY2205_S2
-- =====================================================


-- =====================================================
-- CONSULTA 1: INFORMACION DE FACTURAS
-- Muestra las facturas del año anterior al actual
-- =====================================================

SELECT
    ROW_NUMBER() OVER (
        ORDER BY FECHA DESC, NETO DESC
    ) AS "Nº",
    NUMFACTURA AS "Nº Factura",
    LOWER(
        TO_CHAR(
            FECHA,
            'DD "de" FMMonth "de" YYYY',
            'NLS_DATE_LANGUAGE=SPANISH'
        )
    ) AS "Fecha Emisión",
    LPAD(RUTCLIENTE, 10, '0') AS "RUT Cliente",
    '$' || TO_CHAR(
        NETO,
        'FM999G999G999',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS "Monto Neto",
    '$' || TO_CHAR(
        IVA,
        'FM999G999G999',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS "Monto IVA",
    '$' || TO_CHAR(
        TOTAL,
        'FM999G999G999',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS "Total Factura",
    CASE
        WHEN TOTAL <= 50000 THEN 'Bajo'
        WHEN TOTAL <= 100000 THEN 'Medio'
        ELSE 'Alto'
    END AS "Categoría Monto",
    CASE CODPAGO
        WHEN 1 THEN 'EFECTIVO'
        WHEN 2 THEN 'TARJETA DEBITO'
        WHEN 3 THEN 'TARJETA CREDITO'
        ELSE 'CHEQUE'
    END AS "Forma de pago"
FROM FACTURA
WHERE FECHA >= ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -12)
  AND FECHA < TRUNC(SYSDATE, 'YYYY')
ORDER BY FECHA DESC, NETO DESC;


-- =====================================================
-- CONSULTA 2: CLASIFICACION DE CLIENTES
-- =====================================================

SELECT
    LPAD(RUTCLIENTE, 12, '*') AS "RUT Cliente",
    NOMBRE AS "Nombre Cliente",
    NVL(TO_CHAR(TELEFONO), 'Sin teléfono') AS "Teléfono",
    NVL(TO_CHAR(CODCOMUNA), 'Sin comuna') AS "Comuna",
    ESTADO AS "Estado",
    CASE
        WHEN NVL(SALDO, 0) / CREDITO < 0.5 THEN
            'Bueno ($' ||
            TO_CHAR(
                CREDITO - NVL(SALDO, 0),
                'FM999G999G999',
                'NLS_NUMERIC_CHARACTERS='',.'''
            ) || ')'
        WHEN NVL(SALDO, 0) / CREDITO <= 0.8 THEN
            'Regular ($' ||
            TO_CHAR(
                NVL(SALDO, 0),
                'FM999G999G999',
                'NLS_NUMERIC_CHARACTERS='',.'''
            ) || ')'
        ELSE
            'Crítico'
    END AS "Clasificación Crédito",
    CASE
        WHEN MAIL IS NULL THEN 'Correo no registrado'
        ELSE UPPER(SUBSTR(MAIL, INSTR(MAIL, '@') + 1))
    END AS "Dominio Correo"
FROM CLIENTE
WHERE ESTADO = 'A'
  AND CREDITO > 0
ORDER BY NOMBRE ASC;


-- =====================================================
-- CONSULTA 3: STOCK DE PRODUCTOS
-- =====================================================

SELECT
    CODPRODUCTO AS "ID Producto",
    DESCRIPCION AS "Descripción",
    NVL(
        TO_CHAR(
            VALORCOMPRADOLAR,
            'FM999G999G999D00',
            'NLS_NUMERIC_CHARACTERS='',.'''
        ),
        'Sin registro'
    ) AS "Valor Compra USD",
    CASE
        WHEN VALORCOMPRADOLAR IS NULL THEN 'Sin registro'
        ELSE '$' || TO_CHAR(
            VALORCOMPRADOLAR * &TIPOCAMBIO_DOLAR,
            'FM999G999G999',
            'NLS_NUMERIC_CHARACTERS='',.'''
        )
    END AS "Valor Compra CLP",
    '$' || TO_CHAR(
        VUNITARIO,
        'FM999G999G999',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS "Valor Unitario",
    '$' || TO_CHAR(
        CASE
            WHEN TOTALSTOCK > 80 THEN VUNITARIO * 0.90
            ELSE VUNITARIO
        END,
        'FM999G999G999',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS "Precio con Descuento",
    CASE
        WHEN TOTALSTOCK IS NULL THEN 'Sin datos'
        WHEN TOTALSTOCK < &UMBRAL_BAJO
            THEN '¡ALERTA stock muy bajo!'
        WHEN TOTALSTOCK <= &UMBRAL_ALTO
            THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END AS "Alerta Stock",
    TOTALSTOCK AS "Stock Total"
FROM PRODUCTO
WHERE LOWER(DESCRIPCION) LIKE '%zapato%'
  AND UPPER(PROCEDENCIA) = 'I'
ORDER BY CODPRODUCTO DESC;
