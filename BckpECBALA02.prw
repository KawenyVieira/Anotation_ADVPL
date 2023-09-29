#Include "Protheus.ch"

/*/{Protheus.doc} ECBALA02
// Faz a requisicao de peso para a balanca e le o retorno.
@author Leandro Pereira
@since 12/08/2019
@version P12
@type function
/*/
User Function ECBALA02()

Local nPeso		:= 0
Local nH    	:= 0
Local cBuffer   := ""
Local cCfg		:= ""
Local cTipConv	:= SuperGetMv("EC_BALA02A",.F.,"D")		//Tipo de conversao     
Local nFatConv	:= SuperGetMv("EC_BALA02B",.F.,1000)	//fator de conversao
Local cLeitBal	:= SuperGetMv("EC_BALA02C",.F.,"2")		//1=AGRX003B, 2=msOpenPort
Local ncont		:= 0

	ProcRegua(000)

	//1=AGRX003B
	If AllTrim(cLeitBal) == "1"
		dbSelectArea( "DX5" )
		dbSetOrder( 1 )
		dbSeek(xFilial( "DX5" ))
		While ! DX5->(Eof()) .And. DX5->DX5_FILIAL == xFilial( "DX5" ) 
			if DX5->DX5_STATUS <> "2"
				nPeso := AGRX003B()
				Exit
			endif
			
			DX5->(dbskip())
		End
		
		If Empty(nPeso)
			//MsgStop("Nao foi possivel realizar a leitura do peso automaticamente. Contate o Administrador","ECBALA02 :: ERRO")
		EndIf
	
	//2=msOpenPort
	ElseIf AllTrim(cLeitBal) == "2"
	
		aTemp 		:= fCfgBalanc() 
		cCfg		:= aTemp[1]
		cBalanca	:= aTemp[2]
		
		lRet       := msOpenPort(nH,cCfg)
		if(!lRet)
			Alert("Falha ao conectar com a porta serial")
			Return ( nPeso )
		EndIf
		
		For ncont := 1 To 50

			msRead(nH,@cBuffer)
			
			Sleep(1000)
			if(!Empty(cBuffer)) 
				nPeso := IsNumber(cBuffer,cBalanca)
				Exit
			EndIf
		Next
		msClosePort(nH)  
	
	//3=TXT
	ElseIf AllTrim(cLeitBal) == "3"
		nPeso := fLeitTXT()
	Endif
	
	If cTipConv == "M"
		nPeso := (nPeso * nFatConv) 
	ElseIf cTipConv == "D"
		nPeso := (nPeso / nFatConv)
	End
		
Return ( nPeso )

// Funcao para obter os dados de configuracao da balança
Static Function fCfgBalanc(cBalanca)

Local cCfg := ""

Default cBalanca	:= ""

	dbSetOrder( 1 )
	dbSeek(xFilial( "DX5" ))
	While ! DX5->(Eof()) .And. DX5->DX5_FILIAL == xFilial( "DX5" ) 
		if DX5->DX5_STATUS <> "2"
			cBalanca := AllTrim(DX5->DX5_MARCA)
			
			//cCfg	:= "COM1:2400,e,8,1"
			cCfg	:= AllTrim(DX5->DX5_TIPPOR) + ":"	//Porta Serial
			cCfg	+= AllTrim(DX5->DX5_TIPVEL) + ","	//Velocida de transmissao em bps
			cCfg	+= "e" + ","						//Paridade s/n
			cCfg	+= AllTrim(DX5->DX5_NBITDA) + ","	//Quantidade de bits de dados
			cCfg	+= AllTrim(DX5->DX5_TIPPAR) 		//Bits de parada
			
			Exit
		endif
		
		DX5->(dbskip())
	End

Return ( {cCfg, cBalanca} )


// Separa os caracteres numericos da string recebida da balanca
Static Function IsNumber(cNum,cBalanca)

Local nPeso     := 0 
Local cNumeros  := "0123456789."  
Local cNewNum   := "" 
Local nCont		:= 0

	if cBalanca == "LIDER"	//http://advpl-protheus.blogspot.com.br/2013/11/integracao-protheus-x-balanca.html
		//bloco que separa o numero da string enviada pela balanca 
		For nCont := 1 To Len(cNum) 
		    if(SubStr(cNum,nCont,1) == "E")     
		        Exit
		    EndIf  
		    
		    if(SubStr(cNum,nCont,1) == "I") // peso instavel  
		        //Return "-1"        
				cNewNum := "0"
		    EndIf
		    
		    if(SubStr(cNum,nCont,1) $ cNumeros)
		       cNewNum += SubStr(cNum,nCont,1)
		    EndIf
		Next nCont 
		
	else //Balanca TOLEDO, protocolo P03
	 //cNum := "*0`025680000000 "	
	
		For nCont := 1 To Len(cNum) 
		    if SubStr(cNum,nCont,1) == CHR(2)//Inicio do Texto(STX tabela ASCII)
		  		
		  		cNewNum := SubStr(cNum,nCont+4,6)
		  		cNewNum := STRTRAN(cNewNum," ","0")
		  		
		  		Do Case  // ")" ou "*" nao possui ponto flutuante
		  			case SubStr(cNum,nCont+1,1) == "+"//1 casa da direita para esquerda
		  				cNewNum := SubStr(cNewNum,1,5)+"."+SubStr(cNewNum,6,1)
		  			case SubStr(cNum,nCont+1,1) == ","//2 casas da direita para esquerda
		  				cNewNum := SubStr(cNewNum,1,4)+"."+SubStr(cNewNum,5,2)
		  			case SubStr(cNum,nCont+1,1) == "-"//3 Casas da direita para esquerda
						cNewNum := SubStr(cNewNum,1,3)+"."+SubStr(cNewNum,4,3)
		  			case SubStr(cNum,nCont+1,1) == "."//4 Casas da direita para esquerda
						cNewNum := SubStr(cNewNum,1,2)+"."+SubStr(cNewNum,3,4)
		  		endCase
		  		Exit
		    EndIf  
		Next nCont 
	endif	
	
	nPeso  :=  Val(cNewNum) 
	
Return ( nPeso )              

//Leitura da pesagem em arquivo TXT
Static Function fLeitTXT()

Local cArqTxt 	:= GetNewPar("EC_BALA02D","C:\LerBal\pesagem\pesagem.txt")	//Diretorio onde está salvo o arquivo de pesagem
Local nHdl		:= 0
Local nPesoAux	:= 0
Local nPeso		:= 0
Local nCont		:= 0
Local nI		:= 0

	If Empty(Alltrim(cArqTxt))
		Alert("Nao existem dados para importar. Processo ABORTADO")
		Return	
	EndIf

	nHdl := fOpen(cArqTxt,0 )
	IF nHdl == -1
		IF FERROR()== 516
			ALERT("Feche o programa que gerou o arquivo.")
		EndIF
	EndIf

	FT_FUse(cArqTxt )  //abre o arquivo
	FT_FGoTop()         //posiciona na primeira linha do arquivo
	While nCont <= 3

		nCont++

		cLinha 		:= Alltrim(FT_FReadLn())
		nPeso		:= Val(cLinha)

		//Aguarda a balança estabilizar
		For nI := 1 To 3
			cLinha 		:= Alltrim(FT_FReadLn())
			nPesoAux	:= Val(cLinha)

			Sleep(1000)
		Next nI
		If nPeso == nPesoAux
			Exit
		Endif
	End
	FT_FUSE()
	fClose( nHdl )

Return ( nPeso )
