
--1 Даты регистрации
--Вывести количество контрактов, зарегистрированных в системе за каждый день за последние 5 дней 
BEGIN
  SELECT 
    DT_REG, COUNT(DT_REG)
  FROM  CONTRACTS
    WHERE DT_REG >= (TO_DATE(CURRENT_DATE)-5) AND DT_REG <= TO_DATE(CURRENT_DATE)
    GROUP BY TRUNC(DT_REG,'DD')
    ORDER BY DT_REG desc;
END;

--2 Отчёт по статусам
--Вывести количество контрактов для каждого значения статуса контракта из списка: A - активен, B - заблокирован, C - расторгнут. 
--Результат: статус, «словесное» наименование статуса, количество контрактов.
BEGIN
  SELECT 
    V_STATUS,
    CASE V_STATUS
      WHEN 'A' THEN 'активен'
      WHEN 'B' THEN 'заблокирован'
      WHEN 'C' THEN 'расторгнут'
    END as V_STATUS_NAME
    ,COUNT(V_STATUS)
    FROM CONTRACTS
    GROUP BY V_STATUS;
END;


--3 «Пустые» филиалы
--Вывести наименования филиалов, в которых нет ни одного активного контракта.
BEGIN
  SELECT V_NAME
  FROM DEPARTMENTS
 WHERE NOT EXISTS (SELECT *
                     FROM CONTRACTS
                    WHERE 
                        ID_DEPARTMENT.DEPARTMENTS = ID.DEPARTMENT.CONTRACTS 
                        AND  V_STATUS = 'A');
END;

                        
--4 Счет
--По контракту (v_ext_ident = ‘XXX’) после каждого события (оказанная услуга, платеж) выставляют счет,
--в котором в поле f_sum отображается сумма всех неоплаченных услуг на тот момент. 
--Требуется вывести задолженность абонента на произвольную дату

DECLARE
  name VARCHAR(20);
  start_date   DATE;
  end_data DATE;
BEGIN
    SELECT SUM(F_SUM)
    FROM CONTRACTS c
    LEFT JOIN BILLS b
       ON b.ID_CONTRACT_INST = c.ID_CONTRACT_INST
    WHERE V_EXT_IDENT = name 
        AND DT_EVENT BETWEEN start_date AND end_data ;
END;

--5 Услуги
--Напишите процедуру для извлечения данных из таблицы SERVICE, так, чтобы на вход она могла принимать ID услуги
--(переменная pID). Обратить внимание на то, что она может быть null – в этом случае нужно выводить все записи.
--На выход процедура должна возвращать курсор (переменная dwr) в виде полей ID_SERVICE, V_NAME, CNT 
--(количестов таких услуг у абонентов) с сортировкой по V_NAME.

CREATE OR REPLACE Procedure getService
   ( pID IN varchar2 , dwr OUT SYS_REFCURSOR )
 IS
 
   cursor dwr is
   SELECT ID_SERVICE, V_NAME, count(ID_SERVICE) as CNT
    FROM "SERVICE"
    WHERE ID_SERVICE = pID;
    ORDER BY V_NAME;
 
BEGIN
 
   open dwr for (SELECT ID_SERVICE, V_NAME, count(ID_SERVICE) as CNT
    FROM "SERVICE"
    WHERE ID_SERVICE = pID
    ORDER BY V_NAME);

END;


--6 Курсор
--Напишите курсор CUR, который для выборки строк из SERVICES по условиям ID_SERVICE  не равно 1234 и ID_TARIFF_PLAN равно 567,
--будет производить изменение поля DT_STOP в начало текущего дня.
DECLARE
  CURSOR CUR
    IS
  SELECT DT_STOP 
  FROM SERVICES
  WHERE ID_SERVICE != 1234 
    AND ID_TARIFF_PLAN = 567
  FOR UPDATE OF DT_STOP;
BEGIN
  FOR i IN CURSOR LOOP
    UPDATE SERVICES
        SET DT_STOP = CURRENT_DATA
        WHERE CURRENT OF c1;
      COMMIT;
  END LOOP;
END;




--7 Уникальные услуги
--Вывести наименования услуг, которые являются уникальными в рамках филиалов, т.е. таких услуг, которые есть только 
--в конкретном филиале и ни в каком другом.



BEGIN
    SELECT  V_NAME
    FROM 
        (SELECT  ID_SERVICE , ser.V_NAME as V_NAME, count(ID_DEPARTMENT)
        FROM SERVICES s
        LEFT JOIN CONTRACTS c
            ON c.ID_CONTRACT_INST = s.ID_CONTRACT_INST
        INNER JOIN "SERVICE" ser
            ON ser.ID_SERVICE = s.ID_SERVICE
        GROUP BY ID_SERVICE
        HAVING count(ID_DEPARTMENT)= 1);
END;


--8 Популярные услуги
--Вывести наименования тарифных планов для 5 самых популярных услуг

BEGIN
   SELECT V_NAME
    FROM( SELECT ID_SERVICE, V_NAME,COUNT(ID_SERVICE)as COUNT
          FROM SERVICES s
          INNER JOIN TARIFF_PLAN t
            ON t.ID_TARIFF_PLAN = s.ID_TARIFF_PLAN
          GROUP BY ID_SERVICE
          ORDER BY COUNT DESC)
    WHERE ROWNUM <=5;
END;

