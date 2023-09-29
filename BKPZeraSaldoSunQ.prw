#INCLUDE "totvs.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "TopConn.ch"

#DEFINE CEOL	Chr(13)+Chr(10)

/*/{Protheus.doc} GERAINVENT
//Rotina para lançar na tabela de inventario os saldos dos  do estoque que precisam ser preenchidos. 
	Deve ser executada após	o cadastro e antes de executar a rotina de inventario.
@author Econsiste
@since 05/11/2019
@version P12
@type function
/*/
User Function GERAINVENT()

Local nLin		:= 000
Local bOk    	:= {|| If(Gravar(), oDlg1:End(), ) }
Local bCancel 	:= {|| oDlg1:End() }

Private cProdI 	:= Space(TamSx3("B1_COD")[1]) 
Private cProdF  := Replicate("Z", TamSx3("B1_COD")[1])
Private dDtInv 	:= dDataBase
Private cLocal 	:= CriaVar("B7_LOCAL") 
Private cNroDoc := PADR(geraDoc(),TamSx3("B7_DOC")[1])

	dbSelectArea("SB1")
	dbSetOrder(1)
	
	oMainWnd:ReadClientCoords()
	Define MsDialog oDlg1 Title "Selecione os parametros para os itens" From 000,000 To 290,360 Of oMainWnd Pixel

		nLin := 040
		@ nLin,005 Say "Do produto: "																		Of oDlg1 Pixel
		@ nLin-2,060 MsGet cProdI	F3 "SB1"	Picture PesqPict("SB1","B1_COD") 	SIZE 80,10 HasButton		Of oDlg1 Pixel
	
		nLin += 015
		@ nLin,005 Say "Até o produto: "																	Of oDlg1 Pixel
		@ nLin-2,060 MsGet cProdF	F3 "SB1"	Picture PesqPict("SB1","B1_COD") 	SIZE 80,10 HasButton	Of oDlg1 Pixel
	
		nLin += 015
		@ nLin,005 Say "Data inventário : "																	Of oDlg1 Pixel
		@ nLin-2,060 MsGet dDtInv				Picture PesqPict("SB7","B7_DATA")	SIZE 50,10 HasButton	Of oDlg1 Pixel
	
		nLin += 015
		@ nLin,005 Say "Armazém: "																			Of oDlg1 Pixel
		@ nLin-2,060 MsGet cLocal	F3 "NNR" Valid(ExistCpo("NNR",cLocal))	Picture PesqPict("SB7","B7_LOCAL")	SIZE 30,10 HasButton	Of oDlg1 Pixel
	
		nLin += 015
		@ nLin,005 Say "Documento: "																		Of oDlg1 Pixel
		@ nLin-2,060 MsGet cNroDoc				Picture PesqPict("SB7","B7_DOC")							Of oDlg1 Pixel
	
	Activate MsDialog oDlg1 On Init ( EnchoiceBar(oDlg1,bOk,bCancel,,), ,, )

Return ( Nil )


// Ação do botão confirmar
Static Function Gravar()

Local lRet			:= .T.		
Local dDtBaseAux 	:= dDataBase
Local cMsg			:= ""

	//Validações
	If Empty(dDtInv) .And. lRet 
		SFCMsgErro("Informe a data do inventario!","GERAINVENT : Atenção")
		lRet := .F.
	EndIf
	If Empty(cLocal) .And. lRet 
		SFCMsgErro("Informe o armazem do inventario!","GERAINVENT : Atenção")
		lRet := .F.
	EndIf
	If Empty(cNroDoc) .And. lRet 
		SFCMsgErro("Informe o numero do documento a ser gravado na tabela de inventario!","GERAINVENT : Atenção")
		lRet := .F.
	EndIf
	If lRet
		dbSelectArea("SB7")
		(DbSetOrder(4)) //SB70104 : B7_FILIAL, B7_DOC, B7_DATA, R_E_C_N_O_, D_E_L_E_T_
		If DbSeek(xFilial("SB7") + cNroDoc + DTOS(dDtInv))
			If AllTrim(SB7->B7_LOCAL) <> AllTrim(cLocal)
				cMsg := "Documento informado tem itens do armazem " + AllTrim(SB7->B7_LOCAL) + ", diferente do armazem informado." + CEOL
				cMsg += "Deseja continuar mesmo assim ? "
				If !MsgNoYes(cMsg,"GERAINVENT : Atenção")
					lRet := .F.
				EndIf
			Endif
		EndIf
	Endif

	If lRet
		//Altera a database do sistema, para a data parametrizada
		dDataBase := dDtInv	
	
		cMsg	:= "Será gerado lançamentos na tabela de inventário (SB7) "
		cMsg	+= "com os itens que tem saldo em estoque e não foram inventariados." + CEOL 
		cMsg	+= "Deseja realmente executar a rotina zera saldos ?"
		If MsgNoYes(cMsg,"GERINVENT : Confirmação")
			Processa( {|| lRet := RunProc()}, "Aguarde...","Executando Rotina !!!", .T. )
		Else
			lRet := .F.
		EndIf
	
		//Restaura database do sistema
		dDataBase := dDtBaseAux
	EndIf

Return ( lRet )

//
Static Function RunProc()                         

Local lRet		:= .T.
Local contL 	:= 0  
Local contN 	:= 0 
Local cMensagem	:= ""
Local cAliasTMP	:= ""
Local aVetor := {}

PRIVATE lMsErroAuto := .F.

	BEGIN TRANSACTION

	If lRet
		//Faz a verificação para produtos com lote
		cQuery := " SELECT DISTINCT B8_PRODUTO, B1_TIPO, B1_LOCALIZ " + CEOL
		cQuery += " 	, B8_LOCAL, B8_LOTECTL
		cQuery += " 	, B8_DTVALID,ISNULL(BF_LOCALIZ,'')	BF_LOCALIZ " + CEOL
		cQuery += " 	, SUM(B8_SALDO) B8_SALDO " + CEOL
		cQuery += " FROM " + RetSQLName("SB8") + " B8 WITH (NOLOCK) " + CEOL
		cQuery += " 	INNER JOIN " + RetSQLName("SB1") + " B1 WITH (NOLOCK) ON " + CEOL
		cQuery += "			B1_FILIAL 	= '" + xFilial("SB1") + "' AND " + CEOL
		cQuery += " 		B1_COD		= B8_PRODUTO AND " + CEOL
		cQuery += " 		B1.D_E_L_E_T_ = B8.D_E_L_E_T_  " + CEOL
		cQuery += " 	LEFT JOIN " + RetSQLName("SBF") + " BF WITH (NOLOCK) ON " + CEOL
		cQuery += " 		BF_FILIAL	= B8_FILIAL AND " + CEOL
		cQuery += " 		BF_PRODUTO	= B8_PRODUTO AND " + CEOL
		cQuery += " 		BF_LOCAL	= B8_LOCAL AND " + CEOL
		cQuery += " 		BF_LOTECTL	= B8_LOTECTL AND " + CEOL
		cQuery += " 		BF.D_E_L_E_T_ = B8.D_E_L_E_T_ " + CEOL
		cQuery += " 	LEFT JOIN " + RetSQLName("SB7") + " B7 WITH (NOLOCK) ON " + CEOL
		cQuery += "			B7_FILIAL	= '" + xFilial("SB7") + "' AND " + CEOL
		cQuery += " 		B7_COD		= B8_PRODUTO  AND " + CEOL
		cQuery += " 		B7_LOCAL 	= B8_LOCAL AND " + CEOL
		cQuery += " 		B7_LOTECTL	= B8_LOTECTL AND " + CEOL
		cQuery += " 		B7_LOCALIZ	= BF_LOCALIZ AND " + CEOL
		cQuery += " 		B7_DATA		= '" + DTOS(dDtInv) + "' AND " + CEOL
		cQuery += " 		B7.D_E_L_E_T_ = B1.D_E_L_E_T_ " + CEOL
		cQuery += " WHERE B8.D_E_L_E_T_	= ' ' " + CEOL
		cQuery += " 	AND B8_FILIAL 	= '" + xFilial("SB8") +"' " + CEOL
		cQuery += " 	AND B8_SALDO	<> 0 " + CEOL
		cQuery += " 	AND B8_PRODUTO 	BETWEEN '" + cProdI + "' AND '" + cProdF + "' " + CEOL  
		cQuery += " 	AND B8_LOCAL = '"+ cLocal +"' " + CEOL
		cQuery += " 	AND ISNULL(B7_COD,'') = '' " + CEOL  
		cQuery += " GROUP BY B8_PRODUTO,B8_LOCAL,B8_LOTECTL,B1_TIPO,B8_DTVALID,ISNULL(BF_LOCALIZ,''),B1_LOCALIZ " + CEOL
		cQuery += " ORDER BY B8_PRODUTO,B8_LOCAL,B8_LOTECTL " + CEOL
	
		cAliasTMP	:= GetNextAlias()
		dbUseArea(.T.,"TOPCONN",TCGenQry(,,ALLTRIM(Upper(cQuery))),cAliasTMP,.F.,.F.)
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbGoTop())
		
		Count To nRecCount
		ProcRegua(nRecCount)
		
		TCSETFIELD( cAliasTMP,"B8_DTVALID","D")
		
		(cAliasTMP)->(dbGoTop())
		While !(cAliasTMP)->(eof())
		
			IncProc("Incluindo produtos com rastreabilidade")
		
			/* Alterado para inclusao via execauto
			RecLock("SB7",.T.)
				SB7->B7_FILIAL	:= xFilial("SB7")
				SB7->B7_COD		:= (cAliasTMP)->B8_PRODUTO
				SB7->B7_LOCAL	:= (cAliasTMP)->B8_LOCAL
				SB7->B7_TIPO	:= (cAliasTMP)->B1_TIPO
				SB7->B7_QUANT	:= 0
				SB7->B7_QTSEGUM	:= 0
				SB7->B7_DOC 	:= AllTrim(cNroDoc)
				SB7->B7_DATA	:= dDtInv
				SB7->B7_LOTECTL	:= (cAliasTMP)->B8_LOTECTL
				SB7->B7_DTVALID	:= (cAliasTMP)->B8_DTVALID
				SB7->B7_LOCALIZ	:= (cAliasTMP)->BF_LOCALIZ
				SB7->B7_ESCOLHA := "S"
				SB7->B7_ORIGEM := "MATA270"
			dbUnLock()
			MsUnlock() 
			*/
			
			If AllTrim((cAliasTMP)->B1_LOCALIZ) == "S" .And. Empty((cAliasTMP)->BF_LOCALIZ)
				cMsg	:= "Produto: " + AllTrim((cAliasTMP)->B8_PRODUTO) + CEOL
				cMsg	+= "Local: " + AllTrim((cAliasTMP)->B8_LOCAL) + CEOL
				cMsg	+= "Lote: " + AllTrim((cAliasTMP)->B8_LOTECTL) + CEOL
				cMsg	+= "O produto tem controle de endereçamento, porém não está endereçado."
				cMsg	+= "O mesmo não sera incluido."
				SFCMsgErro(cMsg,"GERAINVENT : Erro")
				
				(cAliasTMP)->(dbSkip())
				Loop
			Endif
			
			aVetor	:= {}
			aVetor 	:= {{"B7_FILIAL", 	xFilial("SB7"),				Nil},;
						{"B7_COD",		(cAliasTMP)->B8_PRODUTO,	Nil},; // Deve ter o tamanho exato do campo B7_COD, pois faz parte da chave do indice 1 da SB7
						{"B7_LOCAL",	(cAliasTMP)->B8_LOCAL,		Nil},; // Deve ter o tamanho exato do campo B7_LOCAL, pois faz parte da chave do indice 1 da SB7
			            {"B7_DOC",		AllTrim(cNroDoc),			Nil},;
			            {"B7_QUANT",	0,							Nil},;
			            {"B7_LOTECTL",	(cAliasTMP)->B8_LOTECTL,	Nil},;
			            {"B7_DTVALID",	(cAliasTMP)->B8_DTVALID,	Nil},;
			            {"B7_LOCALIZ",	(cAliasTMP)->BF_LOCALIZ,	Nil},;
			            {"B7_ESCOLHA",	"S",						Nil},;
			            {"B7_DATA",		dDtInv,						Nil} } // Deve ter o tamanho exato do campo B7_DATA, pois faz parte da chave do indice 1 da SB7
			            
			// MSExecAuto({|x,y,z| mata270(x,y,z)},aVetor,.T.,3)
			
			// If lMsErroAuto
			//     MostraErro()
			//     DisarmTransaction()
			//     lRet 	:= .F.
			//     contL	:= 0
			//     Exit
			// Else
			//     contL++		 //contador de alterações 
			// EndIf
		
			(cAliasTMP)->(dbSkip())
		EndDo
		(cAliasTMP)->(DbCloseArea())
	EndIf 

	//faz a verificação para produtos sem lote (B1_RASTRO = 'N')
	If lRet   
		cQuery := " SELECT DISTINCT B1_RASTRO " + CEOL
		cQuery += " 	, B1_COD, B2_LOCAL, B1_TIPO, B1_LOCALIZ " + CEOL
		cQuery += " 	, ISNULL(BF_LOCALIZ,'')	BF_LOCALIZ " + CEOL
		cQuery += " FROM " + RetSQLName("SB2") + " B2 WITH (NOLOCK) " + CEOL
		cQuery += " 	INNER JOIN " + RetSQLName("SB1") + " B1 ON " + CEOL
		cQuery += " 		B1_FILIAL 	= '" + xFilial("SB1") + "' AND " + CEOL
		cQuery += " 		B1_COD 		= B2_COD AND " + CEOL
		cQuery += " 		B2.D_E_L_E_T_ = B1.D_E_L_E_T_ " + CEOL
		cQuery += " 	LEFT JOIN " + RetSQLName("SBF") + " BF WITH (NOLOCK) ON " + CEOL
		cQuery += " 		BF_FILIAL	= B2_FILIAL AND " + CEOL
		cQuery += " 		BF_PRODUTO	= B2_COD AND " + CEOL
		cQuery += " 		BF_LOCAL	= B2_LOCAL AND " + CEOL
		cQuery += " 		BF.D_E_L_E_T_ = B2.D_E_L_E_T_ " + CEOL
		cQuery += " 	LEFT JOIN " + RetSQLName("SB7") + " B7 WITH (NOLOCK) ON " + CEOL
		cQuery += " 		B7_FILIAL 	= B2_FILIAL AND " + CEOL
		cQuery += " 		B7_COD 		= B2_COD AND " + CEOL
		cQuery += " 		B7_LOCAL 	= B2_LOCAL AND " + CEOL
		cQuery += " 		B7_DATA		= '" + DTOS(dDtInv) + "' AND " + CEOL
		cQuery += " 		B7_LOCALIZ	= BF_LOCALIZ AND " + CEOL
		cQuery += " 		B7.D_E_L_E_T_ = B2.D_E_L_E_T_ " + CEOL
		cQuery += " WHERE B2.D_E_L_E_T_ = ' ' " + CEOL
		cQuery += " 	AND B2_FILIAL 	= '" + xFilial("SB2") + "' " + CEOL
		cQuery += " 	AND B2_QATU 	<> 0 " + CEOL
		cQuery += " 	AND B1_RASTRO 	= 'N' " + CEOL 		
	  	cQuery += " 	AND B2_COD 		BETWEEN '"+ cProdI + "' AND '" + cProdF + "' " + CEOL  
		cQuery += "		AND B2_LOCAL 	= '"+ cLocal +"' " + CEOL
		cQuery += " 	AND ISNULL(B7_COD,'') = '' " + CEOL
		cQuery += " ORDER BY B1_COD,B2_LOCAL " + CEOL
	
		cAliasTMP	:= GetNextAlias()
		dbUseArea(.T.,"TOPCONN",TCGenQry(,,ALLTRIM(Upper(cQuery))),cAliasTMP,.F.,.F.)
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbGoTop())
		
		Count To nRecCount
		ProcRegua(nRecCount)
		
		(cAliasTMP)->(dbGoTop())
		While !(cAliasTMP)->(eof())
		
			IncProc("Incluindo produtos sem rastreabilidade")
		
			/* Alterado para inclusao via execauto
			RecLock("SB7",.T.)
				SB7->B7_FILIAL	:= xFilial("SB7")
				SB7->B7_COD		:= (cAliasTMP)->B1_COD
				SB7->B7_LOCAL	:= (cAliasTMP)->B2_LOCAL
				SB7->B7_TIPO	:= (cAliasTMP)->B1_TIPO
				SB7->B7_QUANT	:= 0
				SB7->B7_QTSEGUM	:= 0
				SB7->B7_DOC 	:= AllTrim(cNroDoc)
				SB7->B7_DATA	:= dDtInv
				SB7->B7_ESCOLHA := "S"
				SB7->B7_ORIGEM  := "MATA270"
			dbUnLock()
			MsUnlock() 
			*/
			
			If AllTrim((cAliasTMP)->B1_LOCALIZ) == "S" .And. Empty((cAliasTMP)->BF_LOCALIZ)
				cMsg	:= "Produto: " + AllTrim((cAliasTMP)->B1_COD) + CEOL
				cMsg	+= "Local: " + AllTrim((cAliasTMP)->B2_LOCAL) + CEOL
				cMsg	+= "O produto tem controle de endereçamento, porém não está endereçado."
				SFCMsgErro(cMsg,"GERAINVENT : Erro")
				
				(cAliasTMP)->(dbSkip())
				Loop
			Endif
	
			aVetor	:= {}
			aVetor 	:= {{"B7_FILIAL", 	xFilial("SB7"),				Nil},;
						{"B7_COD",		(cAliasTMP)->B1_COD,		Nil},; // Deve ter o tamanho exato do campo B7_COD, pois faz parte da chave do indice 1 da SB7
						{"B7_LOCAL",	(cAliasTMP)->B2_LOCAL,		Nil},; // Deve ter o tamanho exato do campo B7_LOCAL, pois faz parte da chave do indice 1 da SB7
			            {"B7_DOC",		AllTrim(cNroDoc),			Nil},;
			            {"B7_QUANT",	0,							Nil},;
			            {"B7_LOCALIZ",	(cAliasTMP)->BF_LOCALIZ,	Nil},;
			            {"B7_ESCOLHA",	"S",						Nil},;
			            {"B7_DATA",		dDtInv,						Nil} } // Deve ter o tamanho exato do campo B7_DATA, pois faz parte da chave do indice 1 da SB7
			            
			// MSExecAuto({|x,y,z| mata270(x,y,z)},aVetor,.T.,3)
			
			// If lMsErroAuto
			//     MostraErro()
			//     DisarmTransaction()
			//     lRet := .F.
			//     contN := 0
			//     Exit
			// Else
			// 	contN++		//contador de alterações
			// Endif
	
			(cAliasTMP)->(dbSkip())
		EndDo
		(cAliasTMP)->(DbCloseArea()) 
	EndIf
	
	END TRANSACTION
	
	total:= contN + contL
	If (total) > 0 
		cMensagem := "Inclusão finalizada com sucesso! Foram incluidos "+ cValToChar(contL) +" itens de lote e "+ cValToChar(contN) +" itens sem  lote para a tabela de inventário." 
	Else
		cMensagem := "Não foi encontrado nenhum item para os parametros informados! Foram incluidos "+ cValToChar(total) +" itens para a tabela de inventário." 
	EndIf

	If !Empty(cMensagem) .And. !lMsErroAuto
		MsgInfo(cMensagem,"GERAINVENT : INFO")
	EndIf

Return ( lRet )

// 
Static Function geraDoc()

Local cArea		:= getArea()
Local cNroDoc 	:= DTOS(date())
Local dDtHoje	:= date()

	dbSelectArea("SB7")
	(DbSetOrder(1)) //SB70101 : B7_FILIAL, B7_DATA, B7_COD, B7_LOCAL, B7_LOCALIZ, B7_NUMSERI, B7_LOTECTL, B7_NUMLOTE, B7_CONTAGE, R_E_C_N_O_, D_E_L_E_T_
	If DbSeek(xFilial("SB7") + DTOS(dDtHoje))
		cNroDoc := SB7->B7_DOC
	EndIf
	dbCloseArea()
	
	RestArea(cArea)

Return ( cNroDoc )
