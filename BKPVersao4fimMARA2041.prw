#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MARA241   ºAutor  ³Alessandro Guerreiroº Data ³  16/07/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Rotina para impressao da posicao do financeiro de acordo comº±±
±±º          ³os parametros informados pelo usuario                       º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºMODULO    ³SIGAFIN/SIGACTB                                             º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/


USER FUNCTION MARA241()
	LOCAL cDESC1       := "Este programa tem como objetivo imprimir relatorio "
	Local cDESC2       := "com valores em aberto da carteira de acordo com os "
	Local cDESC3       := "parametros especificados pelo usuario              "
	Local cPICT        := ""
	Local TITULO       := "Posicao Carteira a Pagar"
	Local nLIN         := 80
	//                                                                                                   1                                                                                                   2
	//         1         2         3         4         5         6         7         8         9         *         1         2         3         4         5         6         7         8         9         *         1         2
	//123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x123456789x
	Local CABEC1       := "FORNECEDOR" 
	Local CABEC2       := "PF   TITULO     PC TP  EMISSAO   DIGIT   VENCTO        VALOR          SALDO"
	//999999/99 - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	//XXX  XXXXXXXXX  XX XXX 99/99/9999 99/99/9999 99/99/9999 999.999.999,99    999.999.999,99

	Local IMPRIME      := .T.
	Local aORD         := {}
	Private lEND       := .F.
	Private lABORTPRINT:= .F.
	Private LIMITE     := 80
	Private TAMANHO    := "P"
	Private NOMEPROG   := "MARA241"
	Private nTIPO      := 18
	Private aRETURN    := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLASTKEY   := 0
	//Private cPERG      := PADR("MARA241",LEN(SX1->X1_GRUPO))
	Private cPERG      := "MARA241"
	Private CBTXT      := Space(10)
	Private CBCONT     := 00
	Private CONTFL     := 01
	Private M_PAG      := 01
	Private WNREL      := "MARA241"

	Private cSTRING    := "SE2"

	dbSelectArea("SE2")
	dbSetOrder(1)

	//--------Lista de peerguntas no configurador--------------
		/* _aGRPSX1:={}
		AADD(_aGRPSX1,{cPERG,"01","Data de Disponibilidade de ?","mv_ch1","D",08,0,0,"G",space(60),"mv_par01"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})
		AADD(_aGRPSX1,{cPERG,"02","Data de Disponibilidade ate ?","mv_ch1","D",08,0,0,"G",space(60),"mv_par02"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})
		AADD(_aGRPSX1,{cPERG,"03","Fornecedor de      ?","mv_ch2","C",06,0,0,"G",space(60),"mv_par03"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"SA2"})
		AADD(_aGRPSX1,{cPERG,"04","Fornecedor ate     ?","mv_ch3","C",06,0,0,"G",space(60),"mv_par04"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"SA2"})
		AADD(_aGRPSX1,{cPERG,"05","Loja de            ?","mv_ch4","C",02,0,0,"G",space(60),"mv_par05"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})
		AADD(_aGRPSX1,{cPERG,"06","Loja ate           ?","mv_ch5","C",02,0,0,"G",space(60),"mv_par06"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})
		AADD(_aGRPSX1,{cPERG,"07","Tipo Relatorio     ?","mv_ch6","N",01,0,0,"C",space(60),"mv_par07"       ,"Analitico"      ,space(30),space(15),"Sintetico"       ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})
		AADD(_aGRPSX1,{cPERG,"08","Desconsiderar Tipo ?","mv_ch7","C",90,0,0,"G","U_MARA241A","mv_par08"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})	
		AADD(_aGRPSX1,{cPERG,"09","Enviar para        ?","mv_ch8","N",01,0,0,"C",space(60),"mv_par09"       ,"Impressora"     ,space(30),space(15),"Planilha"       ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})	

		U_PERGSX1()*/

	PERGUNTE(cPERG,.F.)

	WNREL := SETPRINT(cSTRING,NOMEPROG,cPERG,@TITULO,cDESC1,cDESC2,cDESC3,.T.,aORD,.T.,TAMANHO,,.T.)

	IF nLASTKEY == 27
		RETURN
	ENDIF

	SETDEFAULT(aRETURN,cSTRING)

	IF nLASTKEY == 27
		RETURN
	ENDIF

	nTIPO := IF(aRETURN[4]==1,15,18)

	RPTSTATUS({|| RUNREPORT(CABEC1,CABEC2,TITULO,NLIN) },TITULO)
RETURN


/*************************************************************************************************************************************************/
/*************************************************************************************************************************************************/
/*************************************************************************************************************************************************/

STATIC FUNCTION RUNREPORT(CABEC1,CABEC2,TITULO,NLIN)
	LOCAL dDTDE:= MV_PAR01
	LOCAL dDTATE:= MV_PAR02
	LOCAL cFORNDE := MV_PAR03
	LOCAL cFORNATE:= MV_PAR04
	LOCAL cLOJADE := MV_PAR05
	LOCAL cLOJAATE:= MV_PAR06
	LOCAL nTIPOREL:= MV_PAR07
	LOCAL cTIPOFIL:= ALLTRIM(MV_PAR08)
	LOCAL nENVPARA:= MV_PAR09
	LOCAL cFDL := CHR(13)+CHR(10)
	LOCAL cDIRDOCS
	LOCAL cARQ        
	LOCAL cPATHTMP  
	LOCAL _nHDL
	LOCAL cLINHA := ""  
	LOCAL cFILTRO := ""

	//variaveis filtro duplicadas
	LOCAL cAuxiliar:= ''


	LOCAL cFORANT := SPACE(6)   
	LOCAL nBAIXA  := 0   
	LOCAL nTOTFOR := nTOTGER := 0
	LOCAL nSLDFOR := nSLDGER := 0  

	IF nENVPARA == 2	
		cDIRDOCS := MSDOCPATH()
		cARQ     := "POSICAO_CONTAS_A_PAGAR.CSV"
		IF FILE(cDIRDOCS+"\"+cARQ)
			FERASE(cDIRDOCS+"\"+cARQ)
		ENDIF 
		_nHDL := fCREATE(cDIRDOCS+"\"+cARQ,0)

		FWRITE(_nHDL,'POSIÇÃO CONTAS A PAGAR - '+DTOC(dDTDE)+'Ate'+DTOC(dDTATE)+cFDL)
	ENDIF

	IF nTIPOREL == 2   
		IF nENVPARA == 1
			CABEC1 := "FORNECEDOR													           SALDO"
			CABEC2 := ""	
		ELSE
			FWRITE(_nHDL,"CODIGO;FORNECEDOR;SALDO"+cFDL)			
		ENDIF
	ELSE
		IF nENVPARA == 2                                       
			FWRITE(_nHDL,"CODIGO;FORNECEDOR;PREFIXO;TITULO;PARCELA;TIPO;EMISSAO;DIGITACAO;VENCIMENTO;VALOR;SALDO"+cFDL)		
		ENDIF
	ENDIF              

	IF (!EMPTY(aRETURN[7]))
		cFILTRO := " AND "
		cFILTRO += STRTRAN(aRETURN[7],".and."," AND ")
		cFILTRO := STRTRAN(cFILTRO,".or."," OR ")
		cFILTRO := STRTRAN(cFILTRO,"dToS","")
		cFILTRO := STRTRAN(cFILTRO,"==","=")
		cFILTRO := STRTRAN(cFILTRO,'"',"'")	
		cFILTRO := STRTRAN(cFILTRO,"$","IN"	)
		cFILTRO := STRTRAN(cFILTRO,"Alltrim","")
	ENDIF	

	/*****************************************************************************************
		-Atualização Saldos em aberto de acordo com a Data de disponibilidade do titulo,-
		-Nao houve alteração nos filtros e construcao de valores finais no relatorio-
			Autor: Kaweny_Econsiste
			Data: 15/02/2023
	******************************************************************************************/
	TITULO := ALLTRIM(TITULO)+" - "+DTOC(dDTDE)
   
	cQUERY := " SELECT * " +CRLF
	cQUERY += " FROM " + RetSqlName("SE2") + " SE2 "       + CRLF
	cQUERY += " INNER JOIN " + RetSqlName("SE5")+ " SE5 "  + CRLF
    cQUERY += "	  ON SE2.E2_FILIAL= SE5.E5_FILIAL  "       + CRLF
    cQUERY += "	     AND SE2.E2_PREFIXO= SE5.E5_PREFIXO  " + CRLF
    cQUERY += "	     AND SE2.E2_NUM= SE5.E5_NUMERO  "      + CRLF
    cQUERY += "	     AND SE2.E2_PARCELA= SE5.E5_PARCELA  " + CRLF
    cQUERY += "	     AND SE2.E2_LOJA= SE5.E5_LOJA  "       + CRLF
	cQUERY += "	     AND SE2.E2_FORNECE= SE5.E5_CLIFOR  "  + CRLF
    cQUERY += "	     AND SE2.E2_TIPO= SE5.E5_TIPO  "       + CRLF
    cQUERY += "	     AND SE2.D_E_L_E_T_ = SE5.D_E_L_E_T_ " + CRLF
	cQUERY += " WHERE SE2.D_E_L_E_T_=' '"         		   + CRLF
	cQUERY += " 	AND SE2.E2_FILIAL='"+xFILIAL("SE2")+"'"    + CRLF
	cQUERY += " 	AND SE5.E5_DTDISPO BETWEEN '"+DTOS(dDTDE)+"'AND'"+DTOS(dDTATE) +"'"+ CRLF
	cQUERY += " 	AND((SE2.E2_BAIXA !=' ' AND SE2.E2_SALDO= 0 AND SE5.E5_DTDISPO > '"+DTOS(dDTATE)+"')" 
	cQUERY += " 	OR (SE2.E2_BAIXA = ' ' OR SE2.E2_BAIXA > '"+DTOS(dDTATE)+"')"
	cQUERY += " 	OR (SE2.E2_BAIXA <= '"+DTOS(dDTATE)+"' AND E2_SALDO > 0))"  + CRLF
	cQUERY += " 	AND SE2.E2_FORNECE BETWEEN '"+cFORNDE+"' AND '"+cFORNATE+"'"  + CRLF
	cQUERY += " 	AND SE2.E2_LOJA BETWEEN '"+cLOJADE+"' AND '"+cLOJAATE+"'"     + CRLF
	IF !EMPTY(cTIPOFIL)
		cQUERY += " AND SE2.E2_TIPO NOT IN ("+cTIPOFIL+")"    + CRLF
	ENDIF
	cQUERY += cFILTRO    + CRLF
	cQUERY += " ORDER BY SE2.E2_FORNECE,SE2.E2_LOJA,SE2.E2_PREFIXO,SE2.E2_NUM,SE2.E2_PARCELA"

	MEMOWRIT("MARA241.SQL",cQUERY)

	TCQUERY cQUERY NEW ALIAS "TMPSE2" 
	//U_SETFIELD("TMPSE2")

	tcsetfield("TMPSE2","E2_EMISSAO","D")
	tcsetfield("TMPSE2","E2_VENCTO","D")

	TMPSE2->(DBGOTOP())     

	PROCREGUA(0)    
	SETPRC(000,000)

	WHILE TMPSE2->(!EOF()) 
		//filtro para valores duplicados da query		
		if AllTrim(cAuxiliar) != AllTrim(TMPSE2->E2_FORNECE+ TMPSE2->E2_LOJA + TMPSE2->E2_PREFIXO+ TMPSE2->E2_NUM+ TMPSE2->E2_PARCELA)
		cAuxiliar := TMPSE2->E2_FORNECE+ TMPSE2->E2_LOJA + TMPSE2->E2_PREFIXO+ TMPSE2->E2_NUM+ TMPSE2->E2_PARCELA
			INCPROC()
			IF nENVPARA == 1
			//
				IF PROW()=000 .OR. PROW()+1 >= 55
					IF !EMPTY(cFORANT) .AND. nTIPOREL == 2
						WHILE TMPSE2->(!EOF()) .AND. cFORANT == TMPSE2->E2_FORNECE
							//						cQUERY := "SELECT SUM(CASE WHEN E5_TIPO NOT IN ('PA','NDF','AB-') AND (E5_TIPODOC IN ('MT','JR') OR E5_RECPAG='R') THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM "
							//						cQUERY := "SELECT SUM(CASE WHEN E5_TIPO NOT IN ('PA','AB-') AND (E5_TIPODOC IN ('MT','JR') OR E5_RECPAG='R') THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM "									
							cQUERY := "SELECT SUM(CASE WHEN (E5_TIPODOC IN ('MT','JR') OR (E5_RECPAG='R' AND E5_TIPODOC IN ('ES'))) THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM "
							cQUERY += RETSQLNAME("SE5")
							cQUERY += " WHERE D_E_L_E_T_=' '"
							cQUERY += " AND E5_FILIAL='"+xFILIAL("SE5")+"'"
							cQUERY += " AND E5_NUMERO='"+TMPSE2->E2_NUM+"'"
							cQUERY += " AND E5_PREFIXO='"+TMPSE2->E2_PREFIXO+"'"
							cQUERY += " AND E5_PARCELA='"+TMPSE2->E2_PARCELA+"'"
							cQUERY += " AND E5_FORNECE='"+TMPSE2->E2_FORNECE+"'"
							cQUERY += " AND E5_LOJA='"+TMPSE2->E2_LOJA+"'"
							cQUERY += " AND E5_DATA BETWEEN '"+DTOS(dDTDE)+"'AND'"+DTOS(dDTATE) +"'"+ CRLF  
							cQUERY += " AND E5_TIPO = '"+TMPSE2->E2_TIPO+"'"  
							cQUERY += " AND E5_SITUACA <> 'C'"						
							//----
							IF TMPSE2->E2_TIPO == "PA "
								cQUERY += " AND E5_MOTBX<>'NOR'"
								//							cQUERY += " AND E5_TIPODOC IN ('PA','BA','ES')"
							ENDIF

							TCQUERY cQUERY NEW ALIAS "TMPSE5"

							// TMPSE5->(DBGOTOP())              
							// nBAIXA := TMPSE2->E5_VALOR              
							// TMPSE5->(DBCLOSEAREA())

							//----Versao Original
							TMPSE5->(DBGOTOP())              
							nBAIXA := TMPSE5->E5_VALOR              
							TMPSE5->(DBCLOSEAREA())

							IF TMPSE2->E2_TIPO $ "PA /NDF/AB-"		        
								nTOTFOR -= TMPSE2->E2_VLCRUZ
								nSLDFOR -= (TMPSE2->E2_VLCRUZ-nBAIXA)
							ELSE	
								nTOTFOR += TMPSE2->E2_VLCRUZ
								nSLDFOR += (TMPSE2->E2_VLCRUZ-nBAIXA)
							ENDIF

							TMPSE2->(DBSKIP())						
						ENDDO                 

						@ PROW()  ,067 PSAY nSLDFOR PICTURE "@E 999,999,999.99"
						nSLDGER += nSLDFOR
						nSLDFOR := 0
					ENDIF

					CABEC(TITULO,CABEC1,CABEC2,NOMEPROG,TAMANHO,nTIPO)		

					IF PROW() > 000 .AND. nTIPOREL == 1 .AND. !EMPTY(cFORANT)
						@ PROW()+1,	000 PSAY cFORANT+" - "+POSICIONE("SA2",1,xFILIAL("SA2")+cFORANT,"A2_NOME")
					ENDIF				
				ENDIF                                                 

				IF cFORANT <> TMPSE2->E2_FORNECE
					IF !EMPTY(cFORANT) 
						IF nTIPOREL == 1
							@ PROW()+1,038 PSAY "TOTAL....:"
							@ PROW()  ,052 PSAY nTOTFOR PICTURE "@E 999,999,999.99"
							@ PROW()  ,067 PSAY nSLDFOR PICTURE "@E 999,999,999.99"
							@ PROW()+1,000 PSAY ""

							nTOTGER += nTOTFOR
							nSLDGER += nSLDFOR

							nTOTFOR := nSLDFOR := 0			
						ELSE
							@ PROW()  ,067 PSAY nSLDFOR PICTURE "@E 999,999,999.99"
							nSLDGER += nSLDFOR
							nSLDFOR := 0
						END
					ENDIF

					@ PROW()+1,000 PSAY TMPSE2->E2_FORNECE+" - "+POSICIONE("SA2",1,xFILIAL("SA2")+TMPSE2->E2_FORNECE,"A2_NOME")

					cFORANT := TMPSE2->E2_FORNECE
				ENDIF          

				//RETIRADO NDF DO TRATAMENTO POIS ESTAVA SENDO SOMADO O ESTORNO		
				//			cQUERY := "SELECT SUM(CASE WHEN E5_TIPO NOT IN ('PA','NDF','AB-') AND (E5_TIPODOC IN ('MT','JR') OR E5_RECPAG='R') THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM "
				//			cQUERY := "SELECT SUM(CASE WHEN E5_TIPO NOT IN ('PA','AB-') AND (E5_TIPODOC IN ('MT','JR') OR E5_RECPAG='R') THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM " 
				cQUERY := "SELECT SUM(CASE WHEN (E5_TIPODOC IN ('MT','JR') OR (E5_RECPAG='R' AND E5_TIPODOC IN ('ES'))) THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM "			
				cQUERY += RETSQLNAME("SE5")
				cQUERY += " WHERE D_E_L_E_T_=' '"
				cQUERY += " AND E5_FILIAL='"+xFILIAL("SE5")+"'"
				cQUERY += " AND E5_NUMERO='"+TMPSE2->E2_NUM+"'"
				cQUERY += " AND E5_PREFIXO='"+TMPSE2->E2_PREFIXO+"'"
				cQUERY += " AND E5_PARCELA='"+TMPSE2->E2_PARCELA+"'"
				cQUERY += " AND E5_FORNECE='"+TMPSE2->E2_FORNECE+"'"
				cQUERY += " AND E5_LOJA='"+TMPSE2->E2_LOJA+"'"
				//		cQUERY += " AND E5_RECPAG = 'P'"
				cQUERY += " AND E5_DATA BETWEEN '"+DTOS(dDTDE)+"'AND'"+DTOS(dDTATE) +"'"+ CRLF  
				cQUERY += " AND E5_TIPO = '"+TMPSE2->E2_TIPO+"'" 
				cQUERY += " AND E5_SITUACA <> 'C'"
				//------
				IF TMPSE2->E2_TIPO == "PA "
					cQUERY += " AND E5_MOTBX<>'NOR'"
					//				cQUERY += " AND E5_TIPODOC IN ('PA','BA','ES')"
				ENDIF

				TCQUERY cQUERY NEW ALIAS "TMPSE5"

				// TMPSE5->(DBGOTOP())              
				// nBAIXA := TMPSE2->E5_VALOR              
				// TMPSE5->(DBCLOSEAREA())

				//--------Original---
				TMPSE5->(DBGOTOP())              
				nBAIXA := TMPSE5->E5_VALOR              
				TMPSE5->(DBCLOSEAREA())

				IF nTIPOREL == 1		
					@ PROW()+1,000 PSAY TMPSE2->E2_PREFIXO
					@ PROW()  ,006 PSAY TMPSE2->E2_NUM
					@ PROW()  ,017 PSAY TMPSE2->E2_PARCELA
					@ PROW()  ,020 PSAY TMPSE2->E2_TIPO

					//@ PROW()  ,024 PSAY STOD(SUBSTR(TMPSE2->E2_EMISSAO,1,8)) DTOC(TMPSE2->E2_EMISSAO)
					@ PROW()  ,024 PSAY DTOC(TMPSE2->E2_EMISSAO)

					@ PROW()  ,033 PSAY DTOC(IF(!(TMPSE2->E2_TIPO$"PA /NDF/AB-"),POSICIONE("SF1",1,xFILIAL("SF1")+TMPSE2->(E2_NUM+E2_PREFIXO+E2_FORNECE+E2_LOJA),"F1_DTDIGIT"),STOD(TMPSE2->E2_EMIS1)))

					//@ PROW()  ,042 PSAY STOD(SUBSTR(TMPSE2->E2_VENCTO,1,8)) //DTOC(TMPSE2->E2_VENCTO)
					@ PROW()  ,042 PSAY DTOC(TMPSE2->E2_VENCTO) 

					IF TMPSE2->E2_TIPO $ "PA /NDF/AB-"
						@ PROW()  ,052 PSAY (-1)*TMPSE2->E2_VLCRUZ PICTURE "@E 999,999,999.99"
						@ PROW()  ,067 PSAY (-1)*(TMPSE2->E2_VLCRUZ-nBAIXA) PICTURE "@E 999,999,999.99"
					ELSE
						@ PROW()  ,052 PSAY TMPSE2->E2_VLCRUZ PICTURE "@E 999,999,999.99"
						@ PROW()  ,067 PSAY (TMPSE2->E2_VLCRUZ-nBAIXA) PICTURE "@E 999,999,999.99"
					ENDIF
				ENDIF

				IF TMPSE2->E2_TIPO $ "PA /NDF/AB-"		        
					nTOTFOR -= TMPSE2->E2_VLCRUZ
					nSLDFOR -= (TMPSE2->E2_VLCRUZ-nBAIXA)
				ELSE	
					nTOTFOR += TMPSE2->E2_VLCRUZ
					nSLDFOR += (TMPSE2->E2_VLCRUZ-nBAIXA)
				ENDIF
			ELSE
				IF cFORANT <> TMPSE2->E2_FORNECE
					IF !EMPTY(cFORANT) 
						IF nTIPOREL == 2
							cLINHA += TRANSFORM(nSLDFOR,"@E 999,999,999.99")+cFDL
							FWRITE(_nHDL,cLINHA)
							nSLDFOR := 0
						END
					ENDIF

					cLINHA := TMPSE2->E2_FORNECE+";"                                             
					cLINHA += POSICIONE("SA2",1,xFILIAL("SA2")+TMPSE2->E2_FORNECE,"A2_NOME")+";"

					cFORANT := TMPSE2->E2_FORNECE
				ELSE
					cLINHA := cFORANT+";"                                             
					cLINHA += POSICIONE("SA2",1,xFILIAL("SA2")+cFORANT,"A2_NOME")+";"
				ENDIF          

				//			cQUERY := "SELECT SUM(CASE WHEN E5_TIPO NOT IN ('PA','NDF','AB-') AND (E5_TIPODOC IN ('MT','JR') OR E5_RECPAG='R') THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM "
				cQUERY := "SELECT SUM(CASE WHEN (E5_TIPODOC IN ('MT','JR') OR (E5_RECPAG='R' AND E5_TIPODOC IN ('ES'))) THEN E5_VALOR*-1 ELSE E5_VALOR END) E5_VALOR FROM "
				cQUERY += RETSQLNAME("SE5")
				cQUERY += " WHERE D_E_L_E_T_=' '"
				cQUERY += " AND E5_FILIAL='"+xFILIAL("SE5")+"'"
				cQUERY += " AND E5_NUMERO='"+TMPSE2->E2_NUM+"'"
				cQUERY += " AND E5_PREFIXO='"+TMPSE2->E2_PREFIXO+"'"
				cQUERY += " AND E5_PARCELA='"+TMPSE2->E2_PARCELA+"'"
				cQUERY += " AND E5_FORNECE='"+TMPSE2->E2_FORNECE+"'"
				cQUERY += " AND E5_LOJA='"+TMPSE2->E2_LOJA+"'"
				//		cQUERY += " AND E5_RECPAG = 'P'"
				cQUERY += " AND E5_DATA BETWEEN '"+DTOS(dDTDE)+"'AND'"+DTOS(dDTATE) +"'"+ CRLF  
				cQUERY += " AND E5_TIPO = '"+TMPSE2->E2_TIPO+"'" 
				cQUERY += " AND E5_SITUACA <> 'C'"		

				//-----------
				IF TMPSE2->E2_TIPO == "PA "
					cQUERY += " AND E5_MOTBX<>'NOR'"
					//				cQUERY += " AND E5_TIPODOC IN ('PA','BA','ES')"
				ENDIF

				TCQUERY cQUERY NEW ALIAS "TMPSE5"

				// TMPSE5->(DBGOTOP())              
				// nBAIXA := TMPSE2->E5_VALOR              
				// TMPSE5->(DBCLOSEAREA())

				//----Original
				TMPSE5->(DBGOTOP())              
				nBAIXA := TMPSE5->E5_VALOR              
				TMPSE5->(DBCLOSEAREA())

				IF nTIPOREL == 1		
					cLINHA += TMPSE2->E2_PREFIXO+";"
					cLINHA += TMPSE2->E2_NUM+";"
					cLINHA += TMPSE2->E2_PARCELA+";"
					cLINHA += TMPSE2->E2_TIPO+";"
					cLINHA += DTOC(TMPSE2->E2_EMISSAO)+";"//DTOC(TMPSE2->E2_EMISSAO)+";"                                                                                 
					cLINHA += DTOC(POSICIONE("SF1",1,xFILIAL("SF1")+TMPSE2->(E2_NUM+E2_PREFIXO+E2_FORNECE+E2_LOJA),"F1_DTDIGIT"))+";"//DTOC(POSICIONE("SF1",1,xFILIAL("SF1")+TMPSE2->(E2_NUM+E2_PREFIXO+E2_FORNECE+E2_LOJA),"F1_DTDIGIT"))+";"
					cLINHA += DTOC(TMPSE2->E2_VENCTO)+";"//DTOC(TMPSE2->E2_VENCTO)+";"
					IF TMPSE2->E2_TIPO $ "PA /NDF/AB-"
						cLINHA += TRANSFORM((-1)*TMPSE2->E2_VlCRUZ,"@E 999,999,999.99")+";"
						cLINHA += TRANSFORM((-1)*(TMPSE2->E2_VLCRUZ-nBAIXA),"@E 999,999,999.99")+cFDL
					ELSE
						cLINHA += TRANSFORM(TMPSE2->E2_VLCRUZ,"@E 999,999,999.99")+";"
						cLINHA += TRANSFORM((TMPSE2->E2_VLCRUZ-nBAIXA),"@E 999,999,999.99")+cFDL
					ENDIF
					//U_Otrem
				ENDIF

				IF TMPSE2->E2_TIPO $ "PA /NDF/AB-"		        
					nSLDFOR -= (TMPSE2->E2_VLCRUZ-nBAIXA)
				ELSE	
					nSLDFOR += (TMPSE2->E2_VLCRUZ-nBAIXA)
				ENDIF 

				IF nTIPOREL == 1
					FWRITE(_nHDL,cLINHA)
				ENDIF
			ENDIF
		ENDIF
		
		TMPSE2->(DBSKIP())
			
	ENDDO                             

	TMPSE2->(DBCLOSEAREA())

	IF nENVPARA == 1	                        
		IF nTIPOREL == 1
			@ PROW()+1,038 PSAY "TOTAL....:"
			@ PROW()  ,052 PSAY nTOTFOR PICTURE "@E 999,999,999.99"
			@ PROW()  ,067 PSAY nSLDFOR PICTURE "@E 999,999,999.99"

			nTOTGER += nTOTFOR
			nSLDGER += nSLDFOR
		ELSE 
			@ PROW()  ,067 PSAY nSLDFOR PICTURE "@E 999,999,999.99"
			nSLDGER += nSLDFOR
			nSLDFOR := 0
		ENDIF

		@ PROW()+2,000 PSAY "TOTAL GERAL:"				
		IF nTIPOREL == 1
			@ PROW()  ,052 PSAY nTOTGER PICTURE "@E 999,999,999.99"
		ENDIF
		@ PROW()  ,067 PSAY nSLDGER PICTURE "@E 999,999,999.99"
	ELSE
		IF nTIPOREL == 2
			cLINHA += TRANSFORM(nSLDFOR,"@E 999,999,999.99")+cFDL
			FWRITE(_nHDL,cLINHA)
			nSLDFOR := 0
		ENDIF
	ENDIF

	SET DEVICE TO SCREEN

	IF nENVPARA == 1
		If aReturn[5]==1
			dbCommitAll()
			SET PRINTER TO
			OurSpool(wnrel)
		ENDIF
	ELSE
		FCLOSE(_nHDL)
		cPATHTMP := ALLTRIM(GETTEMPPATH())

		IF FILE(cPATHTMP+cARQ)
			FERASE(cPATHTMP+cARQ)
		ENDIF
		CPYS2T(cDIRDOCS+"\"+cARQ,cPATHTMP,.T.)

		IF !APOLECLIENT("MSEXCEL")
			//			MSGALERT("MSEXCEL NãO INSTALADO")
			SHELLEXECUTE("OPEN",cARQ,"",cPATHTMP,1)
		ELSE
			_oEXCELAPP:=MSEXCEL():NEW()
			_oEXCELAPP:WORKBOOKS:OPEN(cPATHTMP+cARQ)
			_oEXCELAPP:SETVISIBLE(.T.)
		ENDIF	
	ENDIF

	MS_FLUSH()
RETURN

/****************************************************************************************************************************************/
/****************************************************************************************************************************************/
/****************************************************************************************************************************************/

//MSSELECT PARA ESCOLHA DO TIPO DE NF
USER FUNCTION MARA241A()
	LOCAL aAREA   := GETAREA()
	LOCAL lFILTRO := .F.
	LOCAL lINVERTE
	LOCAL cMARCA   
	LOCAL N := 1    

	LOCAL cFILTRO := ALLTRIM(&(READVAR()))
	LOCAL MVRET   := ALLTRIM(READVAR())   

	PRIVATE aHDHR   := {}
	PRIVATE aCLHR := {} 
	PRIVATE oDLG001      

	Static _oTabTemp	:= Nil

	//_cARQTMP := CRIATRAB(,.F.)

	aSTRU := {}	               
	AADD( aSTRU,{"OK"       ,"C",01,0})
	AADD( aSTRU,{"CHAVE"    ,"C",03,0})
	AADD( aSTRU,{"DESCRI"   ,"C",30,0})

	//verifica se ja objeto em uso
	If _oTabTemp <> Nil

		DbSelectArea("TMP")

		_oTabTemp:Delete()
		_oTabTemp := Nil
	Endif

	//DBCREATE(_cARQTMP, aSTRU)
	//DBUSEAREA(.T.,,_cARQTMP,"TMP",.T.,.F.)  

	_oTabTemp := FWTemporaryTable():New( "TMP" )  
	_oTabTemp:SetFields(aSTRU) ƒ
	_oTabTemp:AddIndex("indice1", {"DESCRI"} )
	_oTabTemp:Create()    

	cMARCA  :=GETMARK(,"TMP","OK")	

	cQUERY := "SELECT X5_CHAVE,X5_DESCRI FROM "
	cQUERY += RETSQLNAME("SX5")
	cQUERY += " WHERE D_E_L_E_T_=' '"
	cQUERY += " AND X5_FILIAL='"+xFILIAL("SX5")+"'"	
	cQUERY += " AND X5_TABELA = '05'"
	cQUERY += " ORDER BY X5_DESCRI"

	TCQUERY cQUERY NEW ALIAS "TRB"
	TRB->(DBGOTOP())

	WHILE TRB->(!EOF())
		RECLOCK("TMP",.T.)
		TMP->CHAVE    := TRB->X5_CHAVE
		TMP->DESCRI   := TRB->X5_DESCRI
		IF TMP->CHAVE $ cFILTRO
			TMP->OK := cMARCA
		ENDIF
		MSUNLOCK()

		TRB->(DBSKIP())
	ENDDO           

	TRB->(DBCLOSEAREA())

	//_cCHAVE  := "DESCRI"
	//_cINDTMP := CRIATRAB(,.F.)
	//TMP->(INDREGUA("TMP",_cINDTMP,_cCHAVE))

	cCADASTRO := "Tipos de Titulo"

	_aCAMPO:={}
	AADD(_aCAMPO,{"OK"       ,," "              ,"  "})
	AADD(_aCAMPO,{"CHAVE"    ,,"Tipo"           ,"@!"})
	AADD(_aCAMPO,{"DESCRI"   ,,"Descrição"      ,"@!"})

	lINVERTE:=.F.
	//cMARCA  :=GETMARK(,"TMP","OK")	
	nOPCA   :=0	
	TMP->(DBGOTOP())

	DEFINE MSDIALOG oDLG001 TITLE "Tipos de Titulo (Selecionar no máximo 30 tipos)" FROM 000,000 to 035,063
	oMARK01:=MSSELECT():NEW("TMP","OK","",_aCAMPO,@lINVERTE,@cMARCA,{15,1,260,250},,,)    //595
	oMARK01:oBROWSE:lHASMARK:=.T.	
	oMARK01:oBROWSE:lCANALLMARK:=.T.
	oMARK01:oBROWSE:bALLMARK:={|| INVSEL(cMARCA)}
	ACTIVATE MSDIALOG oDLG001 CENTER ON INIT ENCHOICEBAR(oDLG001,{|| nOPCA:=1,oDLG001:END()},{|| oDLG001:END()})

	IF nOPCA==1           
		TMP->(DBGOTOP())	
		WHILE TMP->(!EOF())
			IF TMP->OK == cMARCA
				IF !(lFILTRO)
					lFILTRO := .T.
					cFILTRO := ""
				ENDIF  
				IF !(TMP->CHAVE $ cFILTRO)
					cFILTRO += IF(N==1,"'",",'")+TMP->CHAVE+"'"
				ENDIF
				N++
			ENDIF
			TMP->(DBSKIP())		   	
		ENDDO                            
	ENDIF            

	IF !(lFILTRO)
		cFILTRO := " "    
	ENDIF                    

	&MVRET :=ALLTRIM(cFILTRO)
	
	TMP->(DBCLOSEAREA())
	_oTabTemp:Delete() 

	RESTAREA(aAREA)
RETURN .T.

/****************************************************************************************************************************************/
/****************************************************************************************************************************************/
/****************************************************************************************************************************************/

//ROTINA PARA MARCAR/DESMARCAR MARKBROWSE
STATIC FUNCTION INVSEL(cMARCA,oMARK01)
	LOCAL cAREA := TMP->(GETAREA())

	TMP->(DBGOTOP())
	WHILE TMP->(!EOF())
		RECLOCK("TMP",.F.)
		IF !TMP->(MARKED("OK"))
			TMP->OK := SPACE(2)
		ELSE
			TMP->OK := cMARCA
		ENDIF
		TMP->(MSUNLOCK())		
		TMP->(DBSKIP())
	END

	TMP->(RESTAREA(cAREA))
RETURN()                                                                  



/*                                                                   
ANALITICO           
1         2         3         4         5         6         7         8
123456789*123456789*123456789*123456789*123456789*123456789*123456789*123456789*
FORNECEDOR
PF   TITULO     PC  TP   EMISSAO    VENCIMENTO      VALOR            SALDO
999999/99 - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXX  XXXXXXXXX  XX  XXX 99/99/9999  99/99/9999  999.999.999,99   999.999.999,99


SINTETICO
1         2         3         4         5         6         7         8
123456789*123456789*123456789*123456789*123456789*123456789*123456789*123456789*
FORNECEDOR													           SALDO
999999/99 - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    999.999.999,99
*/



