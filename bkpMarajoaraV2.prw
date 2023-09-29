#INCLUDE "TOTVS.ch"
#INCLUDE "Topconn.ch"
/*/{Protheus.doc} User Function WFMARA02
    Função para envio de WF com saldos do dia anterior no armazém 22
    @type  Function
    @author Kaweny - Econsiste
    @since 02/08/2022
    @version 12.1.33
/*/
User Function WFMARA02()
    Local aParam  :={"01", "06"} //usado para debug
    local cAliasWF := ''
    local cArmazem := '22'
    local cTitPla := ""
    Local cHtml := ''
    local lPar := .f.
    local lPossui := .f.
    local cTo := ""//SuperGetMV("MV_XDESTSA",,"ti@marajoaralaticinos.com.br")
    local i := 0
    Local nTotProd := 0
    Local nTotGeral := 0
    local lMenu:= .F.
    local dDataref
    local cPerg:= "WFMARA02"
    If Type("cFilAnt") == "U"
        If !Empty(aParam[1])
            RpcSetType(3)
            RpcSetEnv(aParam[1],aParam[2],,,"EST")
            Sleep(2000)
        Else
            return
        EndIf
    else
        lMenu:= .T.
        Pergunte(cPerg,.T.)
        dDataref:=MV_PAR01
    Endif


    if !lMenu
        dDataref:=ddatabase /*Perguntar se ta certo por causa da query*/
        cAliasWF := fGetProdutos(cArmazem)
        cTitPla := "Produção por dia do mês de "+MesExtenso( Month(dDataref))
        cTo := SuperGetMV("MV_XPRODIA",,"ti@marajoaralaticinios.com.br;financeiro@marajoaralaticinios.com.br")

        if (cAliasWF)->(!Eof())//verificando se é o fim do arquivo
            lPossui := .t.

                //montando o cabeçalho
            cHtml := ' <html> '+ CRLF
            cHtml += '    <head> '+ CRLF
            cHtml += '                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> '+ CRLF
            cHtml += '                <meta name="GENERATOR" content="Microsoft FrontPage Express 2.0"> ' + CRLF
            cHtml += '                <title>Pedido de Compra Aprovado</title>  '+ CRLF
            cHtml += '            </head> '+ CRLF
            cHtml += '            <body bgcolor="#FFFFFF" bgproperties="fixed"> ' + CRLF
            cHtml += '                <form method="POST" name="aprova"> '+ CRLF
            cHtml += '                    <table border="0" width="733" align="center"> '+ CRLF
            cHtml += '                        <tr> '+ CRLF
            cHtml += '                            <td width="657"> '+ CRLF
            cHtml += '                                <table border="0" width="639" height="85"> '+ CRLF
            cHtml += '                                    <tr> '+ CRLF
            cHtml += '                                        <td  width="639" height="24"> '+ CRLF
            cHtml += '                                            <br> '+ CRLF
            cHtml += '                                            <p align="center"> '+ CRLF
            cHtml += '                                                <font size="4" face="Arial"> '+ CRLF
            cHtml += '                                                    <b>'+cTitPla+'</b> '+ CRLF
            cHtml += '                                                </font> '+ CRLF
            cHtml += '                                            </p> '+ CRLF
            cHtml += '                                            </br> '+ CRLF
            cHtml += '                                        </td> '+ CRLF
            cHtml += '                                    </tr> '+ CRLF
            cHtml += '                                </table> '+ CRLF
            cHtml += '                                <table border="0" width="639" height="85"> '+ CRLF
            cHtml += '                                    <tr> '+ CRLF
            cHtml += '                                        <td width="62" bgcolor="#808080" height="18"> '+ CRLF
            cHtml += '                                            <font face="Arial">Código</font> '+ CRLF
            cHtml += '                                        </td> '+ CRLF
            cHtml += '                                        <td width="190" bgcolor="#808080" height="18"> '+ CRLF
            cHtml += '                                            <font face="Arial">Descrição</font> '+ CRLF
            cHtml += '                                        </td> '+ CRLF

            //loop no html para ingrementaras tabelas que mostram o dia do mes
            //last_date() tras o ultimo dia do mes
            For i:=1 to last_day(dDataref)
                cHtml += '                                        <td align="center" width="87" bgcolor="#808080" height="18"> '+ CRLF
                cHtml += '                                            <font face="Arial">Dia '+cValtoChar(i)+'</font> '+ CRLF
                cHtml += '                                        </td> '+ CRLF
            Next
            cHtml += '                                        <td align="right" width="87" bgcolor="#808080" height="18"> '+ CRLF
            cHtml += '                                            <font face="Arial">Total Produto</font> '+ CRLF
            cHtml += '                                        </td> '+ CRLF
            // ----------------------------------------Criando as Linhas... Enquanto não for fim da query------------------------------------------
            While !((cAliasWF)->(EoF()))  
                nTotProd := 0
                //declarando cor da celula, todas as celulas pares 
                cHtml += '                                    <tr '+iif(lPar,'bgcolor="#C9C9C9"','')+' > '+ CRLF
                cHtml += '                                        <td style= "min-width:100px"><font size="2" face="Arial">'+(cAliasWF)->D3_COD+'</font></td> '+ CRLF
                cHtml += '                                        <td style= "white-space: nowrap" align="left"><font size="2" face="Arial">'+(cAliasWF)->B1_DESC+'</font></td> '+ CRLF
            
                For i:=1 to last_day(dDataref)
                    cDataProd := SubStr(DtoS(dDataref),1,6)+strzero(i,2)
                    nQtd := fGetQtd((cAliasWF)->D3_COD,cDataProd)

                    //Conversão da 1ª Unidade de Medida para a 2ª Unidade de Medida
                    nQtd := Round(ConvUM((cAliasWF)->D3_COD, nQtd, 0,   2) ,0)
                    cHtml += '                                    <td style= "white-space: nowrap; min-width:120px" align="right"><font size="2" face="Arial">'+Transform(nQtd,"@E 999,999,999")+'</font></td> '+ CRLF
                    nTotProd += nQtd
                    nTotGeral += nQtd
                Next
                //tag total do produto (soma das qtd)
                    cHtml += '                                    <td style= "white-space: nowrap; min-width:120px" align="right"><font size="2" face="Arial">'+Transform(nTotProd,"@E 999,999,999")+'</font></td> '+ CRLF

                lPar := !lPar
                cHtml += ' </tr> '+ CRLF
            
                //Pulando Registro
                (cAliasWF)->(DbSkip())
            

            EndDo
            //tag do total geral
            cHtml += ' <tr>'
            cHtml += '                                    <td style= "white-space: nowrap; min-width:120px" align="Left"><font size="2" face="Arial">TOTAL GERAL</font></td> '+ CRLF
            For i:=1 to (last_day(dDataref) + 1)
                cHtml += '                                    <td > </td> '+ CRLF
            Next
            cHtml += '                                    <td style= "white-space: nowrap; min-width:120px" align="right"><font size="2" face="Arial">'+Transform(nTotGeral,"@E 999,999,999")+'</font></td> '+ CRLF
            cHtml += ' </tr> '+ CRLF
    
        
            //------------------------------------------------FECHANDO-HTML----------------------------------------------------------------------
            cHtml += '        <tr> '+ CRLF
            cHtml += '                                        <td colspan="35" width="498" height="8"> '+ CRLF
            cHtml += '                                            <hr> '+ CRLF
            cHtml += '                                        </td> '+ CRLF
            cHtml += '                                    </tr> '+ CRLF
            cHtml += '                                </table> '+ CRLF
            cHtml += '                            </td> '+ CRLF
            cHtml += '                        </tr> '+ CRLF
            cHtml += '                    </table> '+ CRLF
            cHtml += '                </form> '+ CRLF
            cHtml += '            </body> '+ CRLF
            cHtml += '        </html> '+ CRLF
            

        endif 
        if lPossui//file(cArquivo)
            // sendMail(cTo,cCC,cBcc,cAssunto,cBody,cFile)
        // u_sendMail(cTo,"","","Valor total produzido por dia/mês",cHtml)  
        endif
    else
        TREPWFMARA()
    endif
Return Nil

//-----------------------------------------QUERY-PRINCIPAL-------------------------------------------------
Static function fGetProdutos(cArmazem)
    local cQry := ''
    Local cAlias := "TMPWF"
    Private dDataref := MV_PAR01

    cQry := " SELECT " + CRLF 
    cQry += "    D3_COD " + CRLF 
    cQry += "    ,SB1.B1_DESC " + CRLF 
    cQry += "  FROM " + RetSqlName("SD3") + " SD3 " + CRLF 
    cQry += "  INNER JOIN " + RetSqlName("SB1")+ " SB1 " + CRLF
    cQry += "	  ON SB1.B1_COD = SD3.D3_COD  " + CRLF 
    cQry += "        AND SD3.D_E_L_E_T_ = SB1.D_E_L_E_T_ "+ CRLF 
    cQry += "        AND SB1.B1_TIPO = 'PA' "+ CRLF 
    
    cQry += " WHERE SD3.D_E_L_E_T_ = ' ' "+ CRLF
    cQry += " AND D3_FILIAL = '"+xFilial("SD3")+"'"+ CRLF
    cQry += " AND D3_LOCAL ='"+cArmazem+"' "+ CRLF
    cQry += " AND D3_ESTORNO = ' ' "+ CRLF
    cQry += " AND SUBSTR(D3_EMISSAO,1,6) = '"+substr(dtos(dDataref),1,6)+"' "+ CRLF
    cQry += " AND D3_CF = 'DE4' "+ CRLF
    cQry += " GROUP BY D3_COD"+ CRLF
    cQry +=  "       ,SB1.B1_DESC"+ CRLF
    cQry += "ORDER BY D3_COD " + CRLF
    
    //conferencia se a tabela ja esta iniciada e fechar pra nao ter duplicidade
    if SELECT(cAlias) > 0
        dbselectarea(cAlias)
        (cAlias)->(dbclosearea())
    endif
    
    MpSysOpenQuery(cQry,cAlias)
    (cAlias)->(dbgotop())
return cAlias

//-----------------------------------------QUERY-QUANTIDADE-PRODUCAO----------------------------------------------
Static Function fGetQtd(cProduto,cEmissao)
    local nRet := 0
    local cQry := ''
    local cAliasTot := 'TMPTOT'

    cQry += "  SELECT NVL(SUM(D3_QUANT),0) D3_QUANT "
    cQry += "  FROM "+RetSqlName("SD3")+" SD3 "
    cQry += "  WHERE SD3.D_E_L_E_T_ = ' ' "
    cQry += "  AND D3_FILIAL = '"+xFilial("SD3")+"' "
    cQry += "  AND D3_LOCAL ='22' "
    cQry += "  AND D3_ESTORNO = ' ' "
    cQry += "  AND D3_EMISSAO = '"+cEmissao+"' "
    cQry += "  AND D3_CF = 'DE4' "
    cQry += "  AND D3_COD = '"+cProduto+"' "

    if select(cAliasTot) > 0
        dbselectarea(cAliasTot)
        (cAliasTot)->(DBCLOSEAREA())
    endif

    MpSysOpenQuery(cQry,cAliasTot)
    (cAliasTot)->(dbgotop())

    if (cAliasTot)->(!Eof())
        nRet := (cAliasTot)->D3_QUANT
    endif

return nRet

//--------------------------------------------------------TREPORTS---------------------------------------------------------------------------------
Static Function TREPWFMARA()
    //Declaracao de variaveis    
    Private oReport  := Nil 
    Private oSecCab	 := Nil
    Private cPerg 	 := "WFMARA02" //inicia a variavel com o nome do grupo de perguntas que estara no cadastro da tabela
    dDataref := MV_PAR01
    ReportDef() //inicializando static function
     dDataref := MV_PAR01

    oReport	:PrintDialog()//PrintDialog, serve para disparar a impressão do TReport e trazer os dados do banco
  
    
Return Nil

//--------------------------------------------------------TREPORTDEF--------------------------------------------------------------------------------
Static Function ReportDef() //Nesta função nos definimos a estrutura do relatório, por exemplo as seções, campos, totalizadores e etc.
    local i:=0
    
    oReport := TReport():New("TREPWFMARA","Produção por dia/mês do mês de "+MesExtenso( Month(dDataref)),cPerg,{|oReport| PrintReport(oReport)},"Impressão de cadastro de produtos em TReport simples.")
    oReport:SetLandscape(.T.)
    
    //Colunas do relatório
    oSecCab := TRSection():New( oReport , "Produtos")
    TRCell():New(oSecCab, "CODIGO",  , "Codigo", /*Picture*/,11 , /*lPixel*/,/*{|| code-block de impressao }*/,"LEFT",.T.,"CENTER",/*lCellBreak*/,/*nColSpace*/,.T.,/*nClrBack*/,/*nClrFore*/, )
    TRCell():New(oSecCab, "DESCRICAO",  , "Descricao", /*Picture*/,55  , /*lPixel*/,/*{|| code-block de impressao }*/,"LEFT",.T.,"CENTER",/*lCellBreak*/,/*nColSpace*/, ,/*nClrBack*/,/*nClrFore*/, )
    For i:=1 to last_day(MV_PAR01)
        TRCell():New(oSecCab, "DIA"+CValToChar(i),  ,  CValToChar(i), /*Picture*/, , /*lPixel*/,/*{|| code-block de impressao }*/,"CENTER",.T.,"CENTER",/*lCellBreak*/,/*nColSpace*/,.T.,/*nClrBack*/,/*nClrFore*/, )
    NEXT
        TRCell():New(oSecCab, "TOTALPRODUCAO",  , "Total Producao", /*Picture*/,15, /*lPixel*/,/*{|| code-block de impressao }*/,"CENTER",.T.,"CENTER",/*lCellBreak*/,/*nColSpace*/,.T.,/*nClrBack*/,/*nClrFore*/, )

Return Nil

//--------------------------------------------------------PRINTREPORT--------------------------------------------------------------------------------
Static Function PrintReport(oReport)
    local i:= 0
    local cDataProd:= 0
    local nQtd := 0 
    local cDia :=0
    local nTotProd :=0
    local nTotGeral:=0
    local cArmazem:= '22'
    local cAliasMenu
  
    //chamada query principal
    cAliasMenu:= fGetProdutos(cArmazem)
    
    While !((cAliasMenu)->(EoF())) 
        nTotProd:=0
        oSecCab:init()
        //chamar conteudo do Cod e da Desc
        oSecCab:CELL("CODIGO"):SetValue((cAliasMenu)->D3_COD) 
        oSecCab:CELL("DESCRICAO"):SetValue(AllTrim((cAliasMenu)->B1_DESC)) 
        
        //chamar conteudo dos dias
        For i:=1 to last_day(dDataref)
            cDataProd := SubStr(DtoS(dDataref),1,6)+strzero(i,2)
            //chamada query quantidade
            nQtd:= fGetQtd((cAliasMenu)->D3_COD,cDataProd)
            //Conversão da 1ª Unidade de Medida para a 2ª Unidade de Medida
            nQtd := Round(ConvUM((cAliasMenu)->D3_COD, nQtd, 0,   2) ,0)
            cDia := CValToChar(i)
            oSecCab:CELL("DIA"+cDia):SetValue(nQtd)           
            nTotProd += nQtd
            nTotGeral += nQtd
        NEXT
         oSecCab:CELL("TOTALPRODUCAO"):SetValue(nTotProd) 
         oSecCab:PrintLine()
          
        //Pulando Registro
        (cAliasMenu)->(DbSkip())
    ENDDO
         oSecCab:init()
         oSecCab:CELL("CODIGO"):SetValue("TOTAL GERAL")
         oSecCab:CELL("DESCRICAO"):SetValue(" ")
       //Preenchendo colunas vazias do total geral
        For i:=1 to (last_day(dDataref))
            cDia := CValToChar(i)
            oSecCab:CELL("DIA"+cDia):SetValue(" ")
        Next 
        oSecCab:CELL("TOTALPRODUCAO"):SetValue(nTotGeral)
        oSecCab:PrintLine()
Return Nil


