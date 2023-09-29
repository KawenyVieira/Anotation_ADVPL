#INCLUDE "TOTVS.CH"
#INCLUDE "Topconn.ch"

user Function WWFIN01()
    Local cQuery := ""
    Local cPerg := "WWFIN01"
    Local lContinua := .F.
    
    local cNomeArq := " "
    Private nHdl
    Private cQuebraLin := Chr( 13 ) + Chr( 10 )  // Caracteres de Salto de Linha
    Private aHeader := {}
    Private aDetail := {}
    Private aTriller := {}

    Private nTotReg:= 0
    Private nTotServ:= 0
    Private nTotDedu:= 0
    Private nTotImp:= 0
   
   //-------Chama o campo de perguntas para construção do filtro------------------
   
    while  Pergunte(cPerg,.T.)
       //------ Chama Função com o layout--------------------
        REGISTRO()

        //------ Chama Consulta do Banco-----------------------
        cQuery := " SELECT  "                + CRLF 
        cQuery += "     SFT.FT_TIPOMOV"                                         + CRLF      //E=entrada || S= saida
        cQuery += "   , SFT.FT_NFISCAL"                                         + CRLF      // N° nF 
        cQuery += "   , SFT.FT_TIPO"                                            + CRLF         // Tipo de lançamento S=serviço
        cQuery += "   , SFT.FT_ESPECIE"                                         + CRLF      // Espécie do documento fiscal fixo(NFS)
        cQuery += "   , SFT.FT_VALCONT"                                         + CRLF      // Valor total de serviço

        cQuery += "   , SFT.FT_ALIQICM"                                         + CRLF      // Aliquota ISS
        cQuery += "   , SFT.FT_VALICM"                                          + CRLF       // Valor ISS

        cQuery += "   , SFT.FT_DESCONT"                                         + CRLF      // Valor Desconto
        cQuery += "   , SFT.FT_SERIE"                                           + CRLF
        cQuery += "   , SFT.FT_CLIEFOR"                                         + CRLF
        cQuery += "   , SFT.FT_ENTRADA"                                         + CRLF
        cQuery += "   FROM " + RetSqlName("SFT") + " SFT "                      + CRLF 

        cQuery +=  " WHERE SFT.FT_ENTRADA >='"+ dtoS(MV_PAR01)+"' "                  + CRLF //Data de entrada do documento fiscal no sistema.
        cQuery += "   AND SFT.FT_ENTRADA <='"+ dtos(MV_PAR02)+"' "                   + CRLF 
        cQuery += "   AND SFT.D_E_L_E_T_ = ' ' "                                + CRLF 
        cQuery += "   AND SFT.FT_ESPECIE = 'NFS' "                              + CRLF  
        cQuery += "   AND SFT.FT_SERIE >= '"+ MV_PAR03+"' "                     + CRLF 
        cQuery += "   AND SFT.FT_SERIE <= '"+ MV_PAR04+"' "                     + CRLF 
        cQuery += "   AND SFT.FT_TIPOMOV = '"+ IIF(MV_PAR05 = 1, "E", "S")+"' " + CRLF
        cQuery += "   AND SFT.FT_NFISCAL >= '"+ MV_PAR06+"' "                  + CRLF
        cQuery += "   AND SFT.FT_NFISCAL <= '"+ MV_PAR07+"' "                   + CRLF
        cQuery += "   AND SFT.FT_CLIEFOR >= '"+ MV_PAR08+"' "                   + CRLF
        cQuery += "   AND SFT.FT_CLIEFOR <= '"+ MV_PAR09+"' "                   + CRLF
    
        
        cQuery := ChangeQuery(cQuery)
    
        If Select("QRY") > 0 // verifica se a tabela ta ativa, se ja estiver ela sera fechada para nao ter duplicidade
            Dbselectarea("QRY")
            QRY->(DbClosearea())
        EndIf

        TcQuery cQuery New Alias "QRY"

        //-------------- Preenchendo o Header--------------------------------------------------------------
        if !QRY->(EOF())// validação de conteudo apos a busca no banco, se houver dados, cria-se o arquivo
            lContinua := .t.
            cNomeArq:= AllTrim(MV_PAR10)
            //Verifica se Arquivo Existe
            If File( cNomeArq )
                If ( nAviso := Aviso( 'AVISO', 'Deseja substituir o ' + AllTrim( cNomeArq ) + ' existente ?', {'Sim', 'Não'} ) ) == 1
                    //Deleta Arquivo
                    If fErase( cNomeArq ) <> 0
                        MsgAlert( 'Ocorreram problemas na tentativa de deleção do arquivo '+AllTrim( cNomeArq )+'.' )
                        Return NIL
                    EndIf
                Else
                    Return NIL
                EndIf
            EndIf

            //Verifica se Nome de Arquivo em Branco
            If Empty( cNomeArq )
                MsgAlert( 'Nome do Arquivo nos Parametros em Branco.', 'Atenção!' )
                Return NIL
            Else
                //Cria Arquivo
                nHdl := fCreate( cNomeArq )
                nSeq_ := 0
                lContinua := .T.
                
                //Verifica Criacao do Arquivo
                If nHdl == -1
                    MsgAlert( 'O arquivo '+AllTrim( cNomeArq )+' não pode ser criado! Verifique os parametros.', 'Atenção!' )
                    Return NIL
                EndIf
            EndIf
            
            //Chama a função FWrite() para preecnher o arquivo com o Heaeder
            FWrite( nHdl, GeraLinhas( aHeader, 1 ) )
            exit
        else
            MsgAlert("Nenhum registro encontrado com os parametros informados!", "AVISO!")
        endif  
    end

    if !lContinua
        return
    endif

    //-------------- Preenchendo o Detail--------------------------------------------------------------
    While !QRY->(EOF()) //Enquando não for fim de arquivo
        
        //Chamar função para preencher o arquivo com o detail
        FWrite( nHdl, GeraLinhas( aDetail, 2 ) )
        
        // Incrementar variaveir que serão utilizadas no triller
        nTotReg ++
        nTotServ += QRY->FT_VALCONT 
        nTotDedu += QRY->FT_DESCONT
        nTotImp += QRY->FT_VALICM 

        QRY->(dbskip()) // pula linha
    ENDDO

    //função preencher o arquivo com o triller
    FWrite( nHdl, GeraLinhas( aTriller, 3 ) )
    MsgInfo("Arquivo gerado com sucesso", "Status do aqruivo")

RETURN

//---------------------Gera Linhas Generico --------------------------------
Static Function GeraLinhas( aTipo, nOpcao )
Local cLinha     := ''
Local nTamMaxLin := 0
Local nI         := 0
local cNomCampo
local cTipoReg := ""
if nOpcao == 1
    nTamMaxLin:=100
elseif nOpcao == 2
    nTamMaxLin:= 350
elseif nOpcao == 3
    nTamMaxLin:= 100
endif 


For nI := 1 To Len( aTipo )
	cTipoReg := Alltrim(aTipo[1][7])
	bAux      := &( '{|| ' + aTipo[nI][7] + ' } ' ) 
	cTipo     := aTipo[nI][5]
    nDecimal  := aTipo[nI][6]
	nTamanho  := aTipo[nI][4]
	cNomCampo := aTipo[nI][1]
	
   
	uConteudo := EVal( bAux )
	uConteudo := IIf( ValType( uConteudo ) == 'U' , '', EverChar( uConteudo ) )
	
    //Validação do comportamento do tipo de dado recebido
	If cTipo == 'C'
		If !empty(uConteudo)
			uConteudo := PADR( FwNoAccent(SubStr( AllTrim( uConteudo ), 1, nTamanho )), nTamanho )// preencher com vazio
		Else
			lAbort := .T.
			Exit
		EndIf
	ElseIf cTipo == 'N'
            uConteudo := StrZero( Val( uConteudo ) * (10^nDecimal) , nTamanho )
	
	ElseIf cTipo == 'X'
		If !empty(uConteudo)
			uConteudo := PADL( SubStr( AllTrim( uConteudo ), 1, nTamanho ), nTamanho )
		Else
			lAbort := .T.
			Exit
		EndIf
	elseif cTipo == 'F'
		&uConteudo
	EndIf
	
	cLinha += uConteudo
	
Next


//quebra a linha dentro do arquivo

cLinha += Replicate( ' ', nTamMaxLin - Len( cLinha ) ) + cQuebraLin

Return cLinha    

//funcao everchar (copia)
Static Function EverChar( uCpoConver )

Local cRet  := NIL
Local cTipo := ''

cTipo := ValType( uCpoConver )

If     cTipo == 'C'                    // Tipo Caracter
	cRet := uCpoConver
	
ElseIf cTipo == 'N'                    // Tipo Numerico
	cRet := AllTrim( Str( uCpoConver ) )
	
ElseIf cTipo == 'L'                    // Tipo Logico
	cRet := IIf( uCpoConver, '.T.', '.F.' )
	
ElseIf cTipo == 'D'                    // Tipo Data
	cRet := DToC( uCpoConver )
	
ElseIf cTipo == 'M'                    // Tipo Memo
	cRet := 'MEMO'
	
ElseIf cTipo == 'A'                    // Tipo Array
	cRet := 'ARRAY[' + AllTrim( Str( Len( uCpoConver ) ) ) + ']'
	
ElseIf cTipo == 'U'                    // Indefinido
	cRet := 'NIL'
	
EndIf

Return(cRet)
//-----------------------------------------------------------------------------

Static Function REGISTRO()
  
   

    // Registro Header - TIPO 0
    aHeader := {}
    //               NomeCampo            PosInicial  PosFinal Tamanho  Tipo  Decimal  Descricao
    aAdd( aHeader, { 'TipodeRegistro         ',  001,     001,     1,   'N',    0,    '0' })  //(0) Registro Header
    aAdd( aHeader, { 'TipodeDeclaracao       ',  002,     002,     1,   'C',    0,    '"T"' })  //Prestador(P) e (T)Tomador  
    aAdd( aHeader, { 'TipodeIdentificacao    ',  003,     003,     1,   'N',    0,    '1' })  //(1) cnpj e (2)CPF
    aAdd( aHeader, { 'CnpjCpf                ',  004,     017,    14,   'N',    0,    'SM0 -> M0_CGC'})  //SM0_Identificação da empresa
    aAdd( aHeader, { 'MesReferencia          ',  018,     019,     2,   'F',    0,    'month(stod(QRY->FT_ENTRADA))'})  //Mes da declaracao
    aAdd( aHeader, { 'AnoReferencia          ',  020,     023,     4,   'F',    0,    'year(stod(QRY->FT_ENTRADA))'})  //Ano da declaracao
    aAdd( aHeader, { 'DtLancamento           ',  024,     031,     8,   'N',    0,    'GravaData(ddatabase, .f., 5 )'})  //Funcao para formato de data (ddmmyyyy)
    aAdd( aHeader, { 'TpReferencia           ',  032,     032,     1,   'C',    0,    ' " N " ' }) //(N) Normal (C) Complementar TODO:Perguntar para responsavel
    aAdd( aHeader, { 'VersaoLayout           ',  033,     034,     2,   'N',    0,    '2'})   //(02) Versão do Layout
    aAdd( aHeader, { 'filler                 ',  035,     100,    66,   'C',    0,    '" "' } )  //Livre para futuras informações

    // Registro Detalhes  - TIPO 1
    aDetail :={}
    //                  NomeCampo        PosInicial  PosFinal Tamanho  Tipo  Decimal Descricao
    aAdd( aDetail, { 'TipodeRegistro         ',  001,     001,     1,   'N',   0,    '1' })  //(0) Registro do detalhe
    aAdd( aDetail, { 'TipodeIdentificacao    ',  003,     003,     1,   'N',   0,    '1' })  //(1) cnpj e (2)CPF
    aAdd( aDetail, { 'CnpjCpf                ',  004,     017,    14,   'N',   0,    'SM0 -> M0_CGC'})   //SM0_Identificação da empresa
    aAdd( aDetail, { 'Nome                   ',  017,     116,   100,   'C',   0,    'SM0 -> M0_NOME'})  //SM0_Nome da Empresa 
    aAdd( aDetail, { 'Cidade                 ',  117,     176,    60,   'C',   0,    'SM0 -> M0_CIDENT'})  //SM0_ Cidade da Empresa 
    aAdd( aDetail, { 'Estado                 ',  177,     178,     2,   'C',   0,    'SM0 -> M0_ESTENT'})  //SM0_ Estado da Empresa
    aAdd( aDetail, { 'Nf                     ',  179,     186,     8,   'N',   0,    'QRY-> FT_NFISCAL' })  //Numero da Nf
    aAdd( aDetail, { 'DtEmissao              ',  187,     194,     8,   'N',   0,    'GravaData(stod(QRY->FT_ENTRADA), .f., 5 )'})  //Funcao para formato de data (ddmmyyyy)
    aAdd( aDetail, { 'VlrServico             ',  195,     208,    14,   'N',   2,    'QRY->FT_VALCONT' } )  //Valor dos Servicos Prestados  
    aAdd( aDetail, { 'VlrDeducoes            ',  209,     222,    14,   'N',   2,    'QRY->FT_DESCONT' } )  //Valor desconto
    aAdd( aDetail, { 'Aliquota               ',  223,     227,     5,   'N',   0,    'QRY->FT_ALIQICM' } ) //Aliquota ISS
    aAdd( aDetail, { 'VlrImposto             ',  228,     241,    14,   'N',   2,    'QRY->FT_VALICM' } ) //Valor do Imposto ISS
    aAdd( aDetail, { 'ImpRetido              ',  242,     242,     1,   'C',   0,    ' "S"' } )  // (S) Imposto Retido e (N) Imposto Nao Retido
    aAdd( aDetail, { 'SituacaoNF             ',  243,     243,     1,   'N',   0,    '1'})  //Situacao da Nota Fiscal(1) Normal (2) Cancelada TODO: "validar informação"
    aAdd( aDetail, { 'CodAtividade           ',  244,     249,     6,   'N',   0,    '0' } )  // validar com fiscal_DECRETO Nº 4.947
    aAdd( aDetail, { 'Cfps                   ',  250,     252,     3,   'N',   0,    '0' } )  // validar com fiscal_DECRETO Nº 4.947
    aAdd( aDetail, { 'Serie                  ',  253,     254,     2,   'N',   0,    ' IIF(QRY->FT_VALICM > 0,1,4) '})
        //OPÇÔES: (01) Nota Fiscal de Serviços Tributados -Série A || (04) Nota Fiscal de Serviços Não Tributados ou Isentos -Série C
        
    aAdd( aDetail, { 'filler                 ', 255,     350,     96,    'C ',  0,  '" "' } )//Livre para futuras informações


    // Registro Trailer TIPO 2
    aTriller :={}
    //                  NomeCampo           PosInicial  PosFinal Tamanho Tipo Decimal Descricao
    aAdd( aTriller, { 'TipodeRegistro         ',  001,     001,     1,   'N',   0,    '9' }) //(9) Registro do Trailer
    aAdd( aTriller, { 'QtdRegistros           ',  002,     005,     4,   'N',   0,    'nTotReg' }) //Total dos registros do tipo 1
    aAdd( aTriller, { 'TotalServicos          ',  006,     019,    14,   'N',   2,    'nTotServ'}) //Total dos Servicos
    aAdd( aTriller, { 'TotalDeducoes          ',  020,     033,    14,   'N',   2,    'nTotDedu'}) //Total das Deducoes
    aAdd( aTriller, { 'TotalImpostos          ',  034,     047,    14,   'N',   2,    'nTotImp'}) //Total dos Impostos
    aAdd( aTriller, { 'filler                 ',  048,     100,    53,   'C',   0,    '" "' } )//Livre para futuras informações

   
Return