
//----------------------------------------------------------------------
/*/{Protheus.Doc} MT103FIN()

Programa para validar o vencimento das parcelas geradas no documento
de entrada.

@author Diego Bueno
@since 20/07/2016
@version P11 R8

/*/
//----------------------------------------------------------------------
#Include "PROTHEUS.CH"   
#include "rwmake.ch"

User Function MT103FIN()

Local aAreaAnt		:= GetArea()
Local aAreaSA2		:= SA2->(GetArea())
Local aAreaSF4		:= SF4->(GetArea())
Local aLocHead 		:= PARAMIXB[1]      // aHeader do getdados apresentado no folter Financeiro.
Local aLocCols 		:= PARAMIXB[2]      // aCols do getdados apresentado no folter Financeiro.
Local lLocRet  		:= PARAMIXB[3]      // Flag de validaces anteriores padroes do sistema.
Local nPosValor 	:= GDFieldPos("E2_VALOR", aLocHead)	
Local nPosIRRf 		:= GDFieldPos("E2_IRRF", aLocHead)	
Local nPosISS 		:= GDFieldPos("E2_ISS", aLocHead)	
Local nPosINSS 		:= GDFieldPos("E2_INSS", aLocHead)	
Local nPosPis 		:= GDFieldPos("E2_PIS", aLocHead)	
Local nPosCof 		:= GDFieldPos("E2_COFINS", aLocHead)	
Local nPosCSLl 		:= GDFieldPos("E2_CSLL", aLocHead)	
Local nPosParc 		:= GDFieldPos("E2_PARCELA", aLocHead)	
Local nPosVenc 		:= GDFieldPos("E2_VENCTO", aLocHead)	
Local nPosCodBar 	:= GDFieldPos("E2_CODBAR", aLocHead)	
Local nPosConces 	:= GDFieldPos("E2_XCONCES", aLocHead)	
Local _nParcelas 	:= Len(aLocCols)
Local lMt103Fin		:= GetMv("MV_XMT103F",,.T.)//Define se habilita o P.E. MT103FIN.               
Local nDiasPror		:= GetMv("MV_XDIAVEN",,5)
Local nI 			:= 0
Local cFrpgTrf		:= AllTrim(GetNewPar("NG_FRPGTRF","DC"))	//Forma de pagamento para transferencia
Local cFrpgBol		:= AllTrim(GetNewPar("NG_FRPGBOL","BOL"))	//Forma de pagamento para boleto
Local nDifVenc      := GetMv("MV_XDIFVEN",,15)
Local cDestMail     := GetMv("MV_XDESTMA",,"")
Local cPermvenc	    := GetMv("MV_XPERMVC",,"")
Local cPerCond	    := GetMv("MV_XCONMVC",,"")
Local cCgcPer       := GetMv("MV_XCGCPER",,"")+"/"+GetMv("MV_YCGCPER",,"")
Local cCgcForn      := ""

Public cBcoCaixinha := SPACE(03) // Variável a ser utilizada no P.E. SF1100I para a gravacao de quem pagou a Nota com seu próprio caixinha
Public cNumAgenc    := SPACE(05) // Variável a ser utilizada no P.E. SF1100I para a gravacao de quem pagou a Nota com seu próprio caixinha
Public cNumConta    := SPACE(10) // Variável a ser utilizada no P.E. SF1100I para a gravacao de quem pagou a Nota com seu próprio caixinha

Default _LVLDFRMPGT := .F.
Default _cCodForma	:= Space(TamSX3("E2_XFORPGT")[1])	
Default _cVFrmPagt	:= ""	
Default _lBoluni	:= .F.

	//Substituido pelo bloco a seguir
	
	IF lMt103Fin
		
		For nI := 1 to _nParcelas
			If aLocCols[nI][2] < (ddatabase + nDiasPror) - 1			
				lLocRet := .F.
			EndIF
			
		Next nI

	Endif
	
	//"Alteraçao do tratamendo da condição de pagamento "000"" [Kaweny-eConsiste - 04/2023 - Solicitante Hellen]
	If !IsInCallStack("U_GATI001") .Or. (IsInCallStack("U_GATI001") .And. !IsInCallStack("U_Retorna") .And. !IsInCallStack("GeraConhec") .And. !l103Auto) 
		For nI := 1 to _nParcelas	
			If AllTrim(cCondicao) $ AllTrim(cPerCond) 
				
					if !SetCaixa()
						MsgInfo('Esse título irá impactar no Fluxo de Caixa' ,"TITULO JA VENCIDO ! ! !")
						lLocRet := .T. // Libera o lancamento da NF mesmo sem o caixa preenchido - Hellen pediu 
					else
						lLocRet := .T. // Caixa preenchido, libera o lancamento da NF
					Endif
				EndIf
		Next nI
	ENDIF

	// IF !lLocRet .AND. FUNNAME() == "MATA103" 
		
	// 	if !SetCaixa()
	// 		MsgInfo('Esse título irá impactar no Fluxo de Caixa' ,"TITULO JA VENCIDO ! ! !")
	// 		lLocRet := .T. // Libera o lancamento da NF mesmo sem o caixa preenchido - Hellen pediu 
	// 	else
	// 		lLocRet := .T. // Caixa preenchido, libera o lancamento da NF
	// 	Endif
		
	// Endif

	//(inicio)Gilvan 12/05/2022 - Validação data de vencimento das parcelas
	cCgcForn := Posicione("SA2",1,xFilial("SA2") + CA100FOR + CLOJA,"A2_CGC")

	If !(RetCodUsr() $ cPermvenc) .and. !Empty(cCondicao) .and. !(AllTrim(cCondicao) $ AllTrim(cPerCond))
		IF lMt103Fin .AND. FWCodEmp() == "01" .AND. !(cCgcForn $ cCgcPer)

			For nI := 1 to _nParcelas

				If (aLocCols[nI][2] - DATE()) < nDifVenc	
					If FUNNAME() == "MATA103"
						MsgStop("A data de vencimento das parcelas devem ser maiores que 15 dias a contar a partir da data atual."+CHR(13)+CHR(10)+CHR(13)+CHR(10)+;
								IIF(!Empty(aLocCols[nI][1]),"Pacela: "+aLocCols[nI][1],"")+" Vencimento: "+DTOC(aLocCols[nI][2])+CHR(13)+CHR(10)+CHR(13)+CHR(10)+;
								"Consulte o departamento financeiro !!", "Atenção !!")		
						lLocRet := .F.

					elseif FUNNAME() == "U_GATI001" //Rotina de importacao de xml automatico
						//Inclusao da Mensagem na situação de Xml [Kaweny-eConsiste - 04/2023 - Solicitante Hellen]
						cNomeFor := Alltrim(Posicione("SA2",1,xFilial("SA2") + cA100For,"A2_NOME"))
						MsgStop("A data de vencimento das parcelas devem ser maiores que 15 dias a contar a partir da data atual."+CHR(13)+CHR(10)+CHR(13)+CHR(10)+;
								IIF(!Empty(aLocCols[nI][1]),"Pacela: "+aLocCols[nI][1],"")+" Vencimento: "+DTOC(aLocCols[nI][2])+CHR(13)+CHR(10)+CHR(13)+CHR(10)+;
								"Consulte o departamento financeiro !!", "Atenção !!")	

						U_SendMail(cDestMail,,"Aviso - Importa Xml","A rotina de importação automatica não pode importar a NF "+Alltrim(CNFISCAL)+"  do fornecedor "+cNomeFor+". "+;
											"A data de vencimento das parcelas devem ser maiores que 15 dias a contar a partir da data atual, verifique a configurção da condição de pagamento ! "+;
											IIF(!Empty(aLocCols[nI][1]),"Pacela: "+aLocCols[nI][1],"")+" Vencimento: "+DTOC(aLocCols[nI][2]),,)
						lLocRet := .F.
					endif

				EndIf
			Next nI
		Endif
		//Alteração para salvar para usuario com permissao-kaweny eConsiste [05/2023]
	elseif (RetCodUsr() $ cPermvenc) .and. !lLocRet .and. !(AllTrim(cCondicao) $ AllTrim(cPerCond))
		For nI := 1 to _nParcelas	
				
					if !SetCaixa()
						MsgInfo('Esse título irá impactar no Fluxo de Caixa' ,"TITULO JA VENCIDO ! ! !")
						lLocRet := .T. // Libera o lancamento da NF mesmo sem o caixa preenchido - Hellen pediu 
					else
						lLocRet := .T. // Caixa preenchido, libera o lancamento da NF
					Endif
		Next nI
	Endif
	//(fim)Gilvan 12/05/2022 - Validação data de vencimento das parcelas

	//(inicio)LEANDROM 05/03/2020 - Validação da forma de pagamento
	_cVFrmPagt	:= "2"	//2 = validado
	If _lVldFrmPgt .And. lLocRet

		//..valida se gerou duplicata
		lGeraFin := .F.
		For nI := 1 To Len(aLocCols)
			If !aLocCols[nI,Len(aLocHead)+1]	//Linha não deletada
				If !Empty(aLocCols[nI,nPosValor]) 
					lGeraFin := .T.
					Exit
				EndIf
			EndIf
		Next nI

		If lGeraFin
			If Empty(_cCodForma)
				_cVFrmPagt	:= "0"	//0=Forma de pagamento não informada
				MsgAlert("Forma de pagamento não informada.","MT103FIN : Atenção")

			Else
				If AllTrim(_cCodForma) $ cFrpgBol
					If nPosCodBar > 0
						For nI := 1 To Len(aLocCols)
							If !aLocCols[nI,Len(aLocHead)+1]	//Linha não deletada
								If !Empty(aLocCols[nI,nPosValor]) 
									If Empty(aLocCols[nI,nPosCodBar])
										_cVFrmPagt	:= "1"	//1 = Não validado
										MsgAlert("Código de barras da parcela " + aLocCols[nI,nPosParc] + " não informado.","MT103FIN : Atenção")
										Exit

									Else
										If nPosConces > 0
											_nValor := (If(AllTrim(aLocCols[nI,nPosConces]) == "S", Val(SUBSTR(aLocCols[nI,nPosCodBar],5,11)), val(SUBSTR(aLocCols[nI,nPosCodBar],10,10))) / 100 )
											If _nValor > 0
												_dVencto := DaySum(ctod("07/10/1997"), If(AllTrim(aLocCols[nI,nPosConces]) == "S", Val(SUBSTR(aLocCols[nI,nPosCodBar],1,4)), val(SUBSTR(aLocCols[nI,nPosCodBar],6,4))))
												If _dVencto <> aLocCols[nI,nPosVenc] .AND. AllTrim(aLocCols[nI,nPosConces]) == "N"
													_cVFrmPagt	:= "1"	//1 = Não validado
													cMsgAlert := "Vencimento da parcela " + aLocCols[nI,nPosParc] + " difere do vencimento do código de barras." + CRLF
													cMsgAlert += "Vencimento do boleto: " + DTOC(_dVencto) + CRLF
													cMsgAlert += "Vencimento da parcela: " + DTOC(aLocCols[nI,nPosVenc])
													MsgAlert(cMsgAlert,"MT103FIN : Atenção")
													Exit
												EndIf
												If _nValor <> (aLocCols[nI,nPosValor]-aLocCols[nI,nPosIRRf]-aLocCols[nI,nPosISS]-aLocCols[nI,nPosINSS]-aLocCols[nI,nPosPis]-aLocCols[nI,nPosCof]-aLocCols[nI,nPosCSLl])	.And. !_lBoluni
												
													_cVFrmPagt	:= "1"	//1 = Não validado
													cMsgAlert := "Valor da parcela " + aLocCols[nI,nPosParc] + " difere do valor do código de barras." + CRLF
													cMsgAlert += "Valor do boleto: " + AllTrim(Transform(_nValor, PesqPict("SE2","E2_VALOR"))) + CRLF
													cMsgAlert += "Valor da parcela: "  + AllTrim(Transform(aLocCols[nI,nPosValor], PesqPict("SE2","E2_VALOR"))) + CRLF
													MsgAlert(cMsgAlert,"MT103FIN : Atenção")
													Exit
												EndIf
											EndIf
										EndIf
									Endif
								Endif
							EndIf
						Next nI
					Else
						_cVFrmPagt	:= "1"	//1 = Não validado
						MsgAlert("Coluna do código de barras não localizada. Ver PE MT103SE2.","MT103FIN : Atenção")	
					Endif

				ElseIf AllTrim(_cCodForma) $ cFrpgTrf
					dbSelectArea("SA2")
					dbSetOrder(1)
					If dbSeek(xFilial("SA2") + cA100For + cLoja)
						If Empty(SA2->A2_BANCO) .Or. Empty(SA2->A2_AGENCIA) .Or. Empty(SA2->A2_NUMCON)
							_cVFrmPagt	:= "1"	//1 = Não validado
							MsgAlert("Dados bancários não informado, ver cadastro do fornecedor.","MT103FIN : Atenção")
						Endif
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	
	//(fim)LEANDROM 05/03/2020 - Validação da forma de pagamento

	RestArea(aAreaSF4)
	RestArea(aAreaSA2)
	RestArea(aAreaAnt)

Return(lLocRet)

//--------------------------------------------------------------
/*/{Protheus.doc} MyFunction
Description

@param xParam Parameter Description                             
@return xRet Return Description
@author  - diego@gwaya.com                                              
@since 22/7/2016                                                   
/*/
//--------------------------------------------------------------
Static Function SetCaixa()
Local cGroup
Local oButton1
Local oCaixa
Local oOkButtan
Local lGravou := .F.

Private oNomeCaixa
Private cNomeCaixa := Space(40)


Static oDlg

  DEFINE MSDIALOG oDlg TITLE "Titulo ja vencido" FROM 000, 000  TO 300, 500 COLORS 0, 16777215 PIXEL

    @ 025, 020 GROUP cGroup TO 096, 203 PROMPT "Informe caso já foi pago:" OF oDlg COLOR 0, 16777215 PIXEL
    @ 043, 030 MSGET oCaixa VAR cBcoCaixinha SIZE 048, 010 OF oDlg VALID fValCaixa(cBcoCaixinha) COLORS 0, 16777215 F3 "SA6" PIXEL
    @ 043, 082 MSGET oNomeCaixa VAR cNomeCaixa SIZE 109, 010 OF oDlg COLORS 0, 16777215 PIXEL
	@ 063, 042 SAY oSay1 PROMPT "Agencia \ CC " SIZE 051, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 063, 082 MSGET oNomeCaixa VAR cNumAgenc SIZE 054, 010 OF oDlg COLORS 0, 16777215 PIXEL
	@ 063, 140 MSGET oNomeCaixa VAR cNumConta SIZE 054, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 083, 107 BUTTON oOkButtan PROMPT "Ok" SIZE 037, 012 OF oDlg  ACTION ( GravaCaixa(cBcoCaixinha,@lGravou)  ) PIXEL
    @ 083, 153 BUTTON oButton1 PROMPT "Cancelar" SIZE 037, 012 OF oDlg ACTION (oDlg:End()) PIXEL

  ACTIVATE MSDIALOG oDlg CENTERED

Return(lGravou)



//--------------------------------------------------------------
/*/{Protheus.doc} GravaCaixa
Description

@param xParam Parameter Description                             
@return xRet Return Description
@author  - diego@gwaya.com                                              
@since 22/7/2016                                                   
/*/
//--------------------------------------------------------------
Static Function GravaCaixa( cCaixa, lGravou )

//Local cChave := ''

Default lGravou := .F.	
Default cCaixa := ''

if !Empty(cCaixa)
	lGravou := .T.
endif

/*

	SERA GRAVADO NO P.E. SF1100I pela variável pública cBcoCaixinha
	
	DbSelectArea("SE2")
	SE2->(DbSetOrder(6))//E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO  ))
	cChave := xFilial("SE2") + cA100for + cLoja + cSerie + cNFiscal
	if !Empty(cCaixa) .And. SE2->(DbSeek(xFilial("SE2") + cA100for + cLoja + cSerie + cNFiscal  ))
		While !SE2->(Eof()) .And. cChave == SE2->(E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM) 
			RecLock("SE2",.F.)			
			SE2->E2_PORTADO := cCaixa
			lGravou := .T.	
			MsUnlock()
			SE2->(DbSkip())
		End

	endif
*/

oDlg:End()
Return(lGravou)


//--------------------------------------------------------------
/*/{Protheus.doc} GravaCaixa
Description

@param xParam Parameter Description                             
@return xRet Return Description
@author  - diego@gwaya.com                                              
@since 22/7/2016                                                   
/*/
//--------------------------------------------------------------
Static Function fValCaixa( cCaixa )

Local lReturn := .T.

Default cCaixa := ''

	if Empty(cCaixa)
		lReturn := .T.
		cNomeCaixa := Space(40)
		oNomeCaixa:Refresh()	
	endif

	DbSelectArea("SA6")
	SA6->(DbSetOrder(1))
	if !Empty(cCaixa) .And. SA6->(DbSeek(xFilial("SA6") + cCaixa ))
	
		if SA6->A6_BLOCKED == '1' // 
			MsgInfo("Banco/Caixa " + AllTrim(cCaixa) + " bloqueado para uso!", "Banco/Caixa bloqueado" )
			lReturn := .F.
			cNomeCaixa := Space(40)
			oNomeCaixa:Refresh()		
		else	
			cNomeCaixa := SA6->A6_NREDUZ
			cNumAgenc  := SA6->A6_AGENCIA
			cNumConta  := SA6->A6_NUMCON
			oNomeCaixa:Refresh()
		endif
				
	elseIf !Empty(cCaixa)		
		MsgInfo("Banco/Caixa " + AllTrim(cCaixa) + "não existe!", "Banco/Caixa inválido" )
		lReturn := .F.
		cNomeCaixa := Space(40)
		oNomeCaixa:Refresh()
	endif

Return(lReturn)
