USE [Regla_DM]
GO

DROP PROCEDURE IF EXISTS USPU_REKENINGGROUPING_SLIK
/****** Object:  StoredProcedure [dbo].[USPU_REKENINGGROUPING_SLIK]    Script Date: 9/2/2026 8:38:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

          
CREATE PROCEDURE [dbo].[USPU_REKENINGGROUPING_SLIK] @YMD DATETIME                                  
AS                                  
                                  
--sp_rename 'USPU_REKENINGGROUPING_SLIK','USPU_REKENINGGROUPING_SLIK_20260824'                                  
                 
DECLARE @download_date2 DATETIME          
SET @download_date2 = @ymd          
              
DECLARE @PREV_MONTH02 VARCHAR(6)                                                                     
SELECT @PREV_MONTH02 = LEFT(CONVERT(VARCHAR, DATEADD(MONTH, -1, @YMD), 112), 6)                                             
          
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 1, getdate()          
                                             
UPDATE A                                                                                                                    
SET A.KETERANGAN=isnull(B.KETERANGAN,''),
a.TableSource=b.TABLE_SOURCE     --ojkfinding, untuk penentuan PLDT                                                                                                              
--SELECT A.REKENINGFASILITAS,A.KETERANGAN,B.TABLE_SOURCE,C.VALUE3                                                                                                                     
FROM DM_F01 A                                                                                                                    
--LEFT JOIN    [IDWVDPANT01\ANT1_SQL01,10501].[REGLA_STAGING].[DBO].[TBL_LC_SLIK_LOAN_DAILY] B ON A.YMD=B.DOWNLOAD_DATE AND A.REKENINGFASILITAS=B.REKENING_FASILITAS                                    
LEFT JOIN    [REGLA_STAGING].[DBO].[TBL_LC_SLIK_LOAN_DAILY] B ON A.YMD=B.DOWNLOAD_DATE AND A.REKENINGFASILITAS=B.REKENING_FASILITAS                                           
--LEFT JOIN    [192.168.0.79\SCBMSSQL2014].[REGLA_STAGING].[DBO].[TBL_LC_SLIK_LOAN_DAILY] B ON A.YMD=B.DOWNLOAD_DATE AND A.REKENINGFASILITAS=B.REKENING_FASILITAS                                              
--LEFT JOIN REGLA_COMMON..TBLM_COMMONCODEDETAIL C ON ISNULL(B.TABLE_SOURCE,'')=C.VALUE1 AND PARENTCOMMONCODE='SLIK421'                                  
WHERE A.YMD=@YMD    AND A.DATASOURCE='LC' --AND ISNULL(REKENINGGROUPING,'')=''--AND KODEKONDISI<> '02'                                                                                                                    
AND A.CIF LIKE '%I%'                                                                                                                
                                                                                                                    
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 2, getdate()          
                                                                                                        
--** + KOMBINASI TANGGAL MULAI + CIF + KODE JENIS PENGGUNAAN **--                                                                                                        
                                                                                        
                                                                                                                                     
UPDATE A                                                         
SET A.REKENINGGROUPING=CASE WHEN D.Value3='PAY LATER' THEN                                                                                                              
   A.CIF+ISNULL(A.KODEJENISPENGGUNAAN,'')+'PL'+'0'+CAST(ISNULL(B.SEQ_GROUP,1) AS VARCHAR)                                                                                                                 
     ELSE                                                                    
     A.CIF+A.KODEJENISPENGGUNAAN+'DT'+'0'+CAST(ISNULL(B.SEQ_GROUP,1) AS VARCHAR)                                                              
     END                                           
                                   
 ,SEQ_GROUP=ISNULL(B.SEQ_GROUP,1)         
                                                                     
--SELECT A.REKENINGGROUPING, CASE WHEN A.KETERANGAN='PAY LATER' THEN          
--   A.CIF+ISNULL(A.KODEJENISPENGGUNAAN,'')+'PL'+'0'+CAST(ISNULL(B.SEQ_GROUP,1) AS VARCHAR)                                                                                                                 
--     ELSE                                                                    
--     A.CIF+A.KODEJENISPENGGUNAAN+'DT'+'0'+CAST(ISNULL(B.SEQ_GROUP,1) AS VARCHAR)                
--     END                                                           
--      ,A.KODEKONDISI, A.SOURCEPROCESS                            
FROM DM_F01 A                                             
LEFT JOIN  DM_F01 B ON A.REKENINGFASILITAS=B.REKENINGFASILITAS AND CONVERT(VARCHAR(6), B.YMD, 112) = @PREV_MONTH02                       
LEFT JOIN    [REGLA_STAGING].[DBO].[TBL_LC_SLIK_LOAN_DAILY] C ON A.YMD=C.DOWNLOAD_DATE AND A.REKENINGFASILITAS=C.REKENING_FASILITAS                     
LEFT JOIN REGLA_COMMON..TBLM_COMMONCODEDETAIL D ON ISNULL(C.TABLE_SOURCE,'')=D.VALUE1 AND PARENTCOMMONCODE='SLIK421'                     
--INNER JOIN #TMP_MIN_OPENDT B ON A.CIF=B.CIF                                                                                  
WHERE A.YMD=@YMD AND A.DATASOURCE='LC'  --AND KODEKONDISI<> '02'                                             
AND A.CIF LIKE '%I%' AND  a.SourceProcess NOT IN('STG_F01.DTSX','DATA BULAN LALU') --ISNULL(A.REKENINGGROUPING,'')='' -- SEMENTARA KARENA DATA UAT BERANTAKAN           
AND A.KODEKONDISI NOT in('03','04','09') --- OJK FINDING          
                                          
                                          
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 3, getdate()          
                                  
--** + KOMBINASI SEQUENCE UNTUK NEW ACCOUNT + **--                                                                   
                                                         
                                                   
IF OBJECT_ID('TEMPDB..#NOW') IS NOT NULL                                                                                                                  
DROP TABLE #NOW                                                                                                                      
                                                                                                                        
SELECT LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2) REKENINGGROUPING,MAX(ISNULL(SEQ_GROUP,0)) MAX_SEQ_GROUP                                           
INTO  #NOW                                                     
FROM DM_F01  A                                                                                                                      
WHERE YMD=@YMD AND DATASOURCE='LC' AND KODEKONDISI='00'  --AND CIF='01I11199943'                                                                                                               
GROUP BY LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2)                                                                   
                                                    
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 4, getdate()          
                                                           
UPDATE A                                                                                                                      
--SELECT                                                                                                                       
SET                                                                                                                       
A.REKENINGGROUPING=LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-1)+CAST(ISNULL(MAX_SEQ_GROUP,0) AS VARCHAR)                                                                                                                
, A.SEQ_GROUP=ISNULL(MAX_SEQ_GROUP,0)                                                                             
--SELECT A.REKENINGGROUPING,LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-1)+CAST(ISNULL(MAX_SEQ_GROUP,0) AS VARCHAR)                                                                                                        
                                                            
FROM DM_F01 A                                                                           
INNER JOIN #NOW B ON LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2)=B.REKENINGGROUPING                                                        
WHERE A.YMD=@YMD AND A.DATASOURCE='LC'   --AND A.KODEKONDISI='00'                      
AND A.SEQ_GROUP=1 AND MAX_SEQ_GROUP>1                                                                                                               
AND A.CIF LIKE '%I%'  --AND A.CIF='01I11199943'                                                                       
AND A.SourceProcess NOT IN('STG_F01.DTSX','DATA BULAN LALU')--ISNULL(A.REKENINGGROUPING,'')=''           
AND A.KodeKondisi NOT IN('03','04','09')--- OJK FINDING          
                      
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 5, getdate()               
    
--BULAN LALU WO BULAN INI W0    
UPDATE A SET A.REKENINGGROUPING=B.REKENINGGROUPING    
FROM DM_F01 A    
INNER JOIN    
TEMP_F01_PREV B    
ON A.REKENINGFASILITAS=B.RekeningFasilitas AND A.KODEKONDISI=B.KODEKONDISI    
WHERE A.DATASOURCE='LC' AND A.KODEKONDISI='03'    
AND A.YMD=@YMD    
                                          
--** + KOMBINASI KODE KONDISI **--                                                                                            
          
DROP TABLE IF EXISTS CIFBULANLALUMIX         
SELECT CIF, LEFT(REKENINGGROUPING,16) REKENINGGROUPING,MAX(KODEKONDISI) MAXKODEKONDISI, MIN(KODEKONDISI) MINKODEKONDISI           
INTO CIFBULANLALUMIX FROM TEMP_F01_PREV A       
WHERE  A.DataSource='LC'      
GROUP BY CIF, LEFT(REKENINGGROUPING,16)          
HAVING MAX(KODEKONDISI)='03' AND MIN(KODEKONDISI)='00'       
      
          
           
 DROP TABLE IF EXISTS PLDTHBBULANLALUBYCIF          
SELECT DISTINCT CIF,REKENINGGROUPING,CASE WHEN SUBSTRING(REKENINGGROUPING,15,2)='PL' THEN 'PAY LATER' ELSE 'DANA TUNAI' END PLDT           
INTO PLDTHBBULANLALUBYCIF FROM TEMP_F01_PREV A          
WHERE KODEKONDISI='03'          
          
          
----SELECT  A.CIF,A.REKENINGFASILITAS,A.KodeKondisi,C.KodeKondisi,A.REKENINGGROUPING,C.REKENINGGROUPING,E.Value3,D.REKENINGGROUPING           
UPDATE A  SET A.REKENINGGROUPING=D.REKENINGGROUPING          
FROM DM_F01 A          
INNER JOIN          
CIFBULANLALUMIX B          
ON A.CIF=B.CIF AND A.KodeKondisi=B.MAXKODEKONDISI          
INNER JOIN          
TEMP_F01_PREV C          
ON A.RekeningFasilitas=C.RekeningFasilitas AND B.MINKODEKONDISI=C.KodeKondisi          
INNER JOIN          
PLDTHBBULANLALUBYCIF D          
ON A.CIF=D.CIF          
INNER JOIN          
REGLA_COMMON..TBLM_COMMONCODEDETAIL E ON           
ISNULL(A.TableSource,'')=E.VALUE1 AND PARENTCOMMONCODE='SLIK421'          
AND D.PLDT=E.Value3          
WHERE A.YMD=@YMD           
AND A.REKENINGGROUPING IS NULL      
AND A.DataSource='LC'      
--AND E.VALUE3 IS NOT NULL          
          
          
          
---BULAN LALU AKTIF SEMUA, BULAN LAPORAN WO SEBAGIAN OJK FINDING                   
DROP TABLE IF EXISTS AKTIFSEMUAPREV          
SELECT COUNT(1) JUMLAH_REK,CIF,CASE WHEN SUBSTRING(REKENINGGROUPING,15,2)='PL' THEN 'PAY LATER' ELSE 'DANA TUNAI' END PLDT,max(kodekondisi) maxkodekondisi,min(kodekondisi) minkodekondisi           
INTO AKTIFSEMUAPREV FROM TEMP_F01_PREV          
WHERE  DataSource='LC'      
GROUP BY CASE WHEN SUBSTRING(REKENINGGROUPING,15,2)='PL' THEN 'PAY LATER' ELSE 'DANA TUNAI' END,CIF          
--HAVING COUNT(1)>1          
--and    
HAVING max(KodeKondisi)='00' and min(kodekondisi)='00'        
      
DROP TABLE IF EXISTS HBSEMUACURR          
SELECT COUNT(1) JUMLAH_REK,CIF,D.VALUE3,max(kodekondisi) maxkodekondisi,min(kodekondisi) minkodekondisi           
INTO HBSEMUACURR FROM DM_F01 A      
LEFT JOIN      
REGLA_COMMON..TBLM_COMMONCODEDETAIL D ON ISNULL(A.TableSource,'')=D.VALUE1 AND PARENTCOMMONCODE='SLIK421'                     
WHERE       
YMD=@YMD      
AND  A.DataSource='LC'         
GROUP BY D.Value3,CIF          
--HAVING COUNT(1)>1          
--and     
HAVING max(KodeKondisi)='03' and min(kodekondisi)='03'        
      
--BULANLALU AKTIF SEMUA, BULAN INI HB SEMUA      
--UPDATE A SET A.REKENINGGROUPING=B.REKENINGGROUPING      
--FROM DM_F01 A      
--INNER JOIN      
--TEMP_F01_PREV B      
--ON A.RekeningFasilitas=B.RekeningFasilitas      
--INNER JOIN      
--AKTIFSEMUAPREV C      
--ON A.CIF=C.CIF      
--INNER JOIN      
--HBSEMUACURR D      
--ON A.CIF=D.CIF   
--inner join
--REGLA_COMMON..TBLM_COMMONCODEDETAIL E ON           
--ISNULL(A.TableSource,'')=E.VALUE1 AND PARENTCOMMONCODE='SLIK421'          
--AND D.Value3=E.Value3  and c.PLDT=e.Value3  
--WHERE A.YMD=@YMD AND A.KodeKondisi='03' AND A.REKENINGGROUPING IS NULL      
--AND A.DataSource='LC'      
          
                                                    
IF OBJECT_ID('TEMPDB..#TEMP_MASTER_SEQ') IS NOT NULL                                     
DROP TABLE #TEMP_MASTER_SEQ                                 
                                
SELECT REKENINGGROUPING, MAX(MAX_SEQ_GROUP) MAX_SEQ_GROUP INTO #TEMP_MASTER_SEQ                                 
FROM DM_SEQ_REKENINGGROUPING_MASTER  where ymd<@YMD                              
GROUP BY REKENINGGROUPING            
          
--SELECT A.CIF,A.RekeningFasilitas,A.REKENINGGROUPING, C.REKENINGGROUPING,A.KodeKondisi,B.KodeKondisi ,          
UPDATE A SET A.REKENINGGROUPING=      
CASE WHEN G.CIF IS NOT NULL THEN B.REKENINGGROUPING ELSE      
LEFT(B.REKENINGGROUPING,LEN(B.REKENINGGROUPING)-2)+'WO'+'0'+      
CASE WHEN F.REKENINGGROUPING IS NOT NULL THEN  CAST(MAX_SEQ_GROUP+1 AS VARCHAR) ELSE CAST(ISNULL(A.SEQ_GROUP,1) AS VARCHAR) END          
END      
FROM DM_F01 A          
INNER JOIN          
TEMP_F01_PREV B          
ON A.RekeningFasilitas=B.RekeningFasilitas AND B.KodeKondisi='00'          
INNER JOIN          
AKTIFSEMUAPREV C ON A.CIF=C.CIF          
INNER JOIN          
REGLA_COMMON..TBLM_COMMONCODEDETAIL E ON           
ISNULL(A.TableSource,'')=E.VALUE1 AND PARENTCOMMONCODE='SLIK421'          
AND C.PLDT=E.Value3        
LEFT JOIN      
#TEMP_MASTER_SEQ F      
ON LEFT(b.REKENINGGROUPING,LEN(B.REKENINGGROUPING)-2)=F.REKENINGGROUPING      
LEFT JOIN      
HBSEMUACURR G      
ON A.CIF=G.CIF  and c.PLDT=g.Value3    
WHERE A.YMD=@YMD           
AND A.DataSource='LC'      
AND A.KodeKondisi='03'      
AND A.REKENINGGROUPING IS NULL      
--AND A.CIF='01I3069460293'        
          
          
          
          
          
          
UPDATE A                                      
--SELECT                                                                                       
SET                                                                                                
A.REKENINGGROUPING=B.REKENINGGROUPING          
                              
FROM DM_F01 A            
LEFT JOIN          
TEMP_F01_PREV B          
ON A.RekeningFasilitas=B.RekeningFasilitas --AND A.KodeKondisi=B.KodeKondisi          
WHERE A.YMD=@YMD AND A.DATASOURCE='LC' AND A.KODEKONDISI IN('03','04','09')           
AND A.CIF LIKE '%I%'            
and a.REKENINGGROUPING is null          
                                    
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 6, getdate()          
                     
--** + KOMBINASI SEQUENCE**--                                                                                                        
                                                         
                                                   
--IF OBJECT_ID('TEMPDB..#PREV') IS NOT NULL                                                                                                                  
--DROP TABLE #PREV                                                           
                                                                                                                        
--SELECT LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2) REKENINGGROUPING,MAX(ISNULL(SEQ_GROUP,0)) MAX_SEQ_GROUP INTO  #PREV                                                     
--FROM DM_F01  A                                                                                                                      
----WHERE CONVERT(VARCHAR(6), YMD, 112) = @PREV_MONTH02 AND DATASOURCE='LC' AND KODEKONDISI='02'  --AND CIF='01I0213001149' --20240725_FI-                                      
--WHERE CONVERT(VARCHAR(6), YMD, 112) <= @PREV_MONTH02 AND DATASOURCE='LC' AND A.KODEKONDISI IN ('01','02','07','08','09','12')   --20240725_FI+                                      
--GROUP BY LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2)                                                                   
                                                    
-- IF @PREV_MONTH02<>'202504' -- Agar hasil cleansing manual tidak keganggu - Aris 20250522              
-- BEGIN              
              
--DELETE DM_SEQ_REKENINGGROUPING_MASTER WHERE  CONVERT(VARCHAR(6), YMD, 112) = @PREV_MONTH02                                 
                                
--INSERT INTO regla_dm..log_dm_f01          
--SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 7, getdate()          
                  
--/*UPDATE MASTER REKENING GROUPING*/                              
-- select ymd, rekeningfasilitas into #TBLT_F01_PREV                   
-- --from [IDWVDPANT02\ANT2_SQL01,10501].regla_slik.dbo.tblt_F01  --LINK SERVER PROD           
-- from [IDWVDUANT002\ANT_SQL01,10501].regla_slik.dbo.tblt_F01 --LINK SERVER uat          
-- where CONVERT(VARCHAR(6), YMD, 112) = @PREV_MONTH02 AND DATASOURCE='LC'                  
--and KODEKONDISI IN ('01','02','05','06','07','08','09','11','12','14')                    
          
--INSERT INTO regla_dm..log_dm_f01          
--SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 8, getdate()          
                  
--INSERT INTO DM_SEQ_REKENINGGROUPING_MASTER                              
--SELECT ymd, LEFT(A.rekeningfasilitas,LEN(A.rekeningfasilitas)-2) REKENINGGROUPING,MAX(CAST(RIGHT(REKENINGFASILITAS,2) AS NUMERIC)) MAX_SEQ_GROUP                                   
--FROM #TBLT_F01_PREV A                                
----LEFT JOIN DM_SEQ_REKENINGGROUPING_MASTER B ON LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2)=B.REKENINGGROUPING                                       
--GROUP BY ymd, LEFT(A.rekeningfasilitas,LEN(A.rekeningfasilitas)-2)                                
----having min(KODEKONDISI) not in ('00','03')--IN ('01','02','05','06','07','08','09','11','12','14')                        
              
--  END                
            
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 9, getdate()          
                                
                                                          
--IF OBJECT_ID('TEMPDB..#CIFKONDISI') IS NOT NULL                                                                                                                  
--DROP TABLE #CIFKONDISI                                                 
--                                                    
--SELECT LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2) REK_GROUP, MIN(KODEKONDISI) KODEKONDISI INTO #CIFKONDISI                                                    
--FROM  DM_F01                                                      
--WHERE CONVERT(VARCHAR(6), YMD, 112) = @PREV_MONTH02 AND DATASOURCE='LC' -- AND CIF='01I0213001149'                                                      
--GROUP BY LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2)                                              
                                                    
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 10, getdate()          
                                                    
UPDATE A                                                                                                                      
--SELECT                     
SET                                                                                    
A.REKENINGGROUPING=LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-1)+CAST(ISNULL(MAX_SEQ_GROUP,0)+1 AS VARCHAR)                                                                                                                
, A.SEQ_GROUP=ISNULL(MAX_SEQ_GROUP,0)+1                                                                            
--SELECT A.SOURCEPROCESS,REKENINGFASILITAS,A.REKENINGGROUPING,LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-1)+CAST(ISNULL(MAX_SEQ_GROUP,0)+1 AS VARCHAR)                                                                                   
                                                                    
FROM DM_F01 A                                          
INNER JOIN #TEMP_MASTER_SEQ B ON LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2)=B.REKENINGGROUPING                                                      
--LEFT JOIN #CIFKONDISI C ON LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2)=C.REK_GROUP                                 
--WHERE A.YMD=@YMD AND A.DATASOURCE='LC'   AND A.KODEKONDISI<> '02' AND C.KODEKONDISI<>'00' --20240811_FI-, BIAR KETEMU HASIL JOINNYA MESKIPUN GAK ADA DATANYA                                    
WHERE A.YMD=@YMD AND A.DATASOURCE='LC'   AND A.KODEKONDISI NOT IN('02','09','03','04')-- OJKFINDING --AND ISNULL(C.KODEKONDISI,'02') <>'00'   --20240811_FI+                                     
AND A.CIF LIKE '%I%'  --AND A.CIF='01I0213001149'                                                                       
AND A.REKENINGGROUPING<>LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-1)+CAST(ISNULL(MAX_SEQ_GROUP,0)+1 AS VARCHAR)       
AND A.SourceProcess NOT  IN('STG_F01.DTSX','DATA BULAN LALU') --OJKFINDING      
--AND A.KodeKondisi NOT IN      
      
                                        
                                     
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 11, getdate()                                                             
/*UNTUK CIF YG SELURUH REKNING LCNYA LUNAS*/                                       
                                                                                                      
IF OBJECT_ID('TEMPDB..#CIFLUNAS') IS NOT NULL                                                                                        
DROP TABLE #CIFLUNAS                                                                       
                                                                    
SELECT A.CIF,  A.REKENINGFASILITAS INTO #CIFLUNAS                                                                    
FROM DM_F01 A                                   
INNER JOIN                                                                    
(                                                                    
 SELECT CIF, KETERANGAN,COUNT(KODEKONDISI) KODEKONDISI FROM (                                                                    
 SELECT DISTINCT CIF, KODEKONDISI, KETERANGAN FROM DM_F01 WHERE YMD=@YMD AND DATASOURCE='LC'                                                         
 ) A                                                                    
 GROUP BY CIF, KETERANGAN                                                                    
 HAVING COUNT(KODEKONDISI)=1                                                                    
) B ON A.CIF=B.CIF                                                                    
WHERE A.YMD=@YMD AND A.KODEKONDISI='02'AND DATASOURCE='LC' --AND A.REKENINGFASILITAS='2022040805349'                                                                    
                                                                    
                                                                   
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 12, getdate()          
                                                                   
UPDATE A                                       
SET A.REKENINGGROUPING=B.REKENINGGROUPING                                                                     
--SELECT A.REKENINGFASILITAS,A.CIF,B.YMD, A.REKENINGGROUPING, B.REKENINGGROUPING                                                                     
FROM DM_F01 A                                                                    
LEFT JOIN DM_F01 B ON A.REKENINGFASILITAS=B.REKENINGFASILITAS AND CONVERT(VARCHAR(6), B.YMD, 112) = @PREV_MONTH02                                                                   
INNER JOIN #CIFLUNAS C ON A.REKENINGFASILITAS=C.REKENINGFASILITAS                              
WHERE A.YMD=@YMD AND A.DATASOURCE='LC' AND A.REKENINGGROUPING IS NULL                                                                    
                                                            
                                       
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 13, getdate()          
                                               
/* UNTUK UPDATE REKENING HAPUS BUKU YANG LUNAS DI BULAN INI*/                                                  
                                                 
                                                                            
IF OBJECT_ID('TEMPDB..#REK_HB') IS NOT NULL                                                                                        
DROP TABLE #REK_HB                                                                       
                                                                    
SELECT * INTO #REK_HB FROM DM_F01                
WHERE CONVERT(VARCHAR(6), YMD, 112) = @PREV_MONTH02 AND KODEKONDISI='03'                            
                                  
                                                       
--IF OBJECT_ID('TEMPDB..#CIF_HB') IS NOT NULL                                                                                        
--DROP TABLE #CIF_HB                                     
                                                         
--SELECT A.CIF,  MAX(A.KODEKONDISI) MAX_KONDISI--A.REKENINGFASILITAS, A.KODEKONDISI --INTO #CIFLUNAS                                           
--INTO #CIF_HB                                  
--FROM DM_F01 A                                                                    
--INNER JOIN  #REK_HB B ON A.CIF=B.CIF   AND A.REKENINGFASILITAS=B.REKENINGFASILITAS                                                                 
--WHERE A.YMD=@YMD AND A.DATASOURCE='LC' --AND A.CIF='01I1000752065'                                                                  
--GROUP BY A.CIF                                                                    
                                                          
            
INSERT INTO regla_dm..log_dm_f01          
SELECT @Download_date2, 'USPU_REKENINGGROUPING_SLIK', 14, getdate()          
            
UPDATE A                                                
SET A.REKENINGGROUPING=B.REKENINGGROUPING                                                
--SELECT A.REKENINGFASILITAS,A.REKENINGGROUPING, B.REKENINGGROUPING,B.KODEKONDISI, A.KODEKONDISI                                                 
FROM DM_F01 A                                                
INNER JOIN #REK_HB B ON A.REKENINGFASILITAS=B.REKENINGFASILITAS AND A.DATASOURCE=B.DATASOURCE                                    
--INNER JOIN #CIF_HB C ON A.CIF=C.CIF AND C.MAX_KONDISI='02'                                              
WHERE A.YMD=@YMD AND A.KODEKONDISI='02' AND A.DATASOURCE='LC' --AND A.CIF='01I1000752065'                                                
                                                
                                
/*UPDATE MASTER REKENING GROUPING*/                                
                                
--INSERT INTO DM_SEQ_REKENINGGROUPING_MASTER                 
--SELECT @ymd ymd, LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2) REKENINGGROUPING,MAX(ISNULL(A.SEQ_GROUP,0)) MAX_SEQ_GROUP                                  
--FROM DM_F01  A                                  
----LEFT JOIN DM_SEQ_REKENINGGROUPING_MASTER B ON LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2)=B.REKENINGGROUPING                                
--WHERE YMD = @YMD AND DATASOURCE='LC'-- AND KODEKONDISI IN ('01','02','05','06','07','08','09','11','12','14') --20240725_FI+                                        
----AND B.REKENINGGROUPING IS NULL                                
--GROUP BY LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2)                                  
-- having min(KODEKONDISI) not in ('00','03')--IN ('01','02','05','06','07','08','09','11','12','14')                          
                                 
                           
--delete DM_SEQ_REKENINGGROUPING_MASTER                                
                                
--SELECT YMD, LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2) REKENINGGROUPING,MAX(ISNULL(SEQ_GROUP,0)) MAX_SEQ_GROUP                                     
--INTO  DM_SEQ_REKENINGGROUPING_MASTER                                                       
--FROM DM_F01  A                                                                                                                        
----WHERE CONVERT(VARCHAR(6), YMD, 112) = @prev_month02 AND DATASOURCE='LC' AND KODEKONDISI='02'  --AND CIF='01I0213001149' --20240725_FI-                                        
--WHERE CONVERT(VARCHAR(6), YMD, 112) <= '20240830' AND DATASOURCE='LC' AND KODEKONDISI IN ('01','02','07','08','09','12') --20240725_FI+                                        
--GROUP BY LEFT(REKENINGGROUPING,LEN(REKENINGGROUPING)-2)                                    
                                
                                
--SELECT LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2) REKENINGGROUPING,MAX(ISNULL(A.SEQ_GROUP,0)) MAX_SEQ_GROUP                                     
--INTO #TEMP_MASTER FROM DM_F01  A                                  
--WHERE CONVERT(VARCHAR(6), YMD, 112) =@YMD AND DATASOURCE='LC' AND KODEKONDISI IN ('01','02','07','08','09','12') --20240725_FI+                                        
--GROUP BY LEFT(A.REKENINGGROUPING,LEN(A.REKENINGGROUPING)-2)                                  
                                
--UPDATE A                                
--SET A.MAX_SEQ_GROUP=B.MAX_SEQ_GROUP                                 
----SELECT  A.REKENINGGROUPING, A.MAX_SEQ_GROUP, B.MAX_SEQ_GROUP                                     
--FROM DM_SEQ_REKENINGGROUPING_MASTER  A                                  
--INNER JOIN #TEMP_MASTER B ON A.REKENINGGROUPING=B.REKENINGGROUPING                                
--WHERE  B.MAX_SEQ_GROUP > A.MAX_SEQ_GROUP   --CONVERT(VARCHAR(6), YMD, 112) = '20240930' AND DATASOURCE='LC' AND KODEKONDISI IN ('01','02','07','08','09','12') --20240725_FI+                                        
                                
                                       
                                  
--SELECT KODEKONDISI,REKENINGGROUPING,* FROM DM_F01 WHERE CIF='01I1001108969' ORDER BY YMD                                      
                                    
  --   SELECT KODE_KONDISI,ISWRITEOFF,* FROM REGLA_STAGING..TBL_LC_SLIK_LOAN_DAILY WHERE REKENING_FASILITAS='1231227010995' ORDER BY DOWNLOAD_DATE 
GO


