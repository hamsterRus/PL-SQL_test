
--1 ���� �����������
--������� ���������� ����������, ������������������ � ������� �� ������ ���� �� ��������� 5 ���� 
BEGIN
  SELECT 
    DT_REG, COUNT(DT_REG)
  FROM  CONTRACTS
    WHERE DT_REG >= (TO_DATE(CURRENT_DATE)-5) AND DT_REG <= TO_DATE(CURRENT_DATE)
    GROUP BY TRUNC(DT_REG,'DD')
    ORDER BY DT_REG desc;
END;

--2 ����� �� ��������
--������� ���������� ���������� ��� ������� �������� ������� ��������� �� ������: A - �������, B - ������������, C - ����������. 
--���������: ������, ���������� ������������ �������, ���������� ����������.
BEGIN
  SELECT 
    V_STATUS,
    CASE V_STATUS
      WHEN 'A' THEN '�������'
      WHEN 'B' THEN '������������'
      WHEN 'C' THEN '����������'
    END as V_STATUS_NAME
    ,COUNT(V_STATUS)
    FROM CONTRACTS
    GROUP BY V_STATUS;
END;


--3 ������� �������
--������� ������������ ��������, � ������� ��� �� ������ ��������� ���������.
BEGIN
  SELECT V_NAME
  FROM DEPARTMENTS
 WHERE NOT EXISTS (SELECT *
                     FROM CONTRACTS
                    WHERE 
                        ID_DEPARTMENT.DEPARTMENTS = ID.DEPARTMENT.CONTRACTS 
                        AND  V_STATUS = 'A');
END;

                        
--4 ����
--�� ��������� (v_ext_ident = �XXX�) ����� ������� ������� (��������� ������, ������) ���������� ����,
--� ������� � ���� f_sum ������������ ����� ���� ������������ ����� �� ��� ������. 
--��������� ������� ������������� �������� �� ������������ ����

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

--5 ������
--�������� ��������� ��� ���������� ������ �� ������� SERVICE, ���, ����� �� ���� ��� ����� ��������� ID ������
--(���������� pID). �������� �������� �� ��, ��� ��� ����� ���� null � � ���� ������ ����� �������� ��� ������.
--�� ����� ��������� ������ ���������� ������ (���������� dwr) � ���� ����� ID_SERVICE, V_NAME, CNT 
--(���������� ����� ����� � ���������) � ����������� �� V_NAME.

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


--6 ������
--�������� ������ CUR, ������� ��� ������� ����� �� SERVICES �� �������� ID_SERVICE  �� ����� 1234 � ID_TARIFF_PLAN ����� 567,
--����� ����������� ��������� ���� DT_STOP � ������ �������� ���.
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




--7 ���������� ������
--������� ������������ �����, ������� �������� ����������� � ������ ��������, �.�. ����� �����, ������� ���� ������ 
--� ���������� ������� � �� � ����� ������.



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


--8 ���������� ������
--������� ������������ �������� ������ ��� 5 ����� ���������� �����

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

