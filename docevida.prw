
#INCLUDE "rwmake.ch"
#include "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#include "protheus.ch"
#INCLUDE "TOPCONN.CH"
/*/{Protheus.doc} FGETNOTAS() 
    Rotina de verificação da existencia de notas fiscais de Saida, a partir de arquivos fornecidos pelo usuario (Arquivo .csv)
    Alem da criação automatica das NF's inexistentes, incluindo suas respectivas parcelas
    @type  Function
    @author Kaweny - Econsiste
    @since 31/10/2022
    @version 12.1.33
/*/

/*-----------------------------------------ENDERECAMENTO DO ARQUIVO-------------------------------------------------
    Rotina para selecao do arquivo, atraves de cx de perguntas
*/
User Function DVFAT02() 

    Local   lRet      := .F.
    Local   nOpc      := 0
    Private cCaminho  := Space(100)
    Private aCampos := {}
    Private aProd  := {}

    While !lRet
        nOpc := 0
        lRet := .F.
        DEFINE MSDIALOG oDlg TITLE "Importacao de arquivo " From 0,0 To 13,50
        tSay():New(05,07,{|| "Este programa realiza leitura de um arquivo .csv"+chr(13)+chr(10)+;
                            "para verificacao de notas na tabela contas a pagar,"+chr(13)+chr(10)+;
                            "alem de realizar a insercao das nao exixtentes no sistema"},oDlg,,,,,,.T.,,,200,80)		

        oSayArq := tSay():New(55,07,{|| "Informe o local onde se encontra o arquivo para importacao:"},oDlg,,,,,,.T.,,,200,80)
        oGetArq := TGet():New(65,05,{|u| If(PCount()>0,cCaminho:=u,cCaminho)},oDlg,150,010,'@!',,,,,,,.T.,,,,,,,,,,'cCaminho') 
        oBtnArq := tButton():New(65,160,"Abrir..." ,oDlg,{|| cCaminho := SelectFile(cCaminho)},30,12,,,,.T.) 
        oBtnImp := tButton():New(80,050,"Importar" ,oDlg,{|| nOpc:=1,oDlg:End()},40,12,,,,.T.) //Importar
        oBtnCan := tButton():New(80,110,"Cancelar" ,oDlg,{|| nOpc:=0,oDlg:End()},40,12,,,,.T.) //Cancelar

        ACTIVATE MSDIALOG oDlg CENTERED                                                          

        //-- Validacoes	
        If nOpc == 1  
            If Empty(cCaminho)
                MsgInfo("Arquivo nao informado.","Atencao!")
                lRet := .F.
            ElseIf !File(cCaminho)
                MsgInfo("Arquivo nao encontrado.","Atencao!")
                lRet := .F.
            Else
                lRet := .T.
            EndIf
        Else
            lRet := .T.
        EndIf
        If lRet .And. nOpc == 1
            Processa({|| fLerArq(cCaminho)},"Processando a leitura do arquivo.","Aguarde..") 
            If Len(aProd) > 0
                If MsgYesNo(AllTrim(Str(Len(aProd)))+" registros a serem atualizados."+" Confirma?")  		
                    Processa({|| fCompare()},"Realizando a importacao","Aguarde...")
                EndIf
            EndIf	
        Endif
    End
Return lRet 
/*-----------------------------------------SELECAO DO ARQUIVO-------------------------------------------------
    Rotina para selecao do arquivo
*/
Static Function SelectFile(cArquivo)
    cType 	 := 'Arquivo txt|*.txt|Arquivo CSV|*.csv'
    //verificando se o arquivo nao esta vazio
    cArquivo := cGetFile(cType, "Ok")
    If !Empty(cArquivo)
        cArquivo += Space(100-Len(cArquivo))
    Else
        cArquivo := Space(100)
    EndIf

    Return cArquivo
/*-----------------------------------------LEITURA DO ARQUIVO-------------------------------------------------
    As funções FT_F* são utilizadas para ler arquivos texto, em que as linhas são delimitadas pela 
    seqüência de caracteres CRLF ou LF(*) e o tamanho máximo, de cada linha, de 1022 bytes. Além disso,
    o arquivo é aberto em uma área de trabalho similar a usada pelas tabelas de dados 
*/
Static Function fLerArq(cCaminho)
    Local cLinha := ""
    Local lPrim := .T.

    //Seleciona o arquivo na variavel cCaminho
    FT_FUSE(cCaminho)
    FT_FGOTOP()
    //
    ProcRegua(FT_FLASTREC())

    While !FT_FEOF()
    
        IncProc("Lendo arquivo texto...")
    
        cLinha := FT_FREADLN()
    
        If lPrim
            aCampos := Separa(cLinha,";",.T.)
            lPrim := .F.
        Else
            AADD(aProd,Separa(cLinha,";",.T.))
        EndIf
    
        FT_FSKIP()
    EndDo

    FT_FUSE()

Return
/*---------------------------------------------------COMPARACAO DE NOTAS-------------------------------------------------
    Rotina para pesquisa de nota e verificando se a nota é existente na tabela SE1 e se a nota pesquisada contem mais de uma parcela
*/
static function fCompare()
    
    Local lDesbloqClient
    Local lDesbloqVend
    Local nI:=0

    Private lMsErroAuto 
    //TAMSX3() => DEVOLVE UM ARRAY [1]=TAM CAMPO, [2]=CASA DECIMAIS, [3]=TP CAMPO
    for nI:=1 to Len(aProd) 
        DbSelectArea("SE1")
        DbSetOrder(1) /*Chave de Pesquisa order=1 || FILIAL+ SERIE+ CODIGO+ PARCELA+ TIPO ||*/
        IF !dbseek(xFilial("SE1")+ PadR(AllTrim(aProd[nI,2]),TAMSX3("E1_PREFIXO")[1]," ")+ aProd[nI,3]+ PadR(AllTrim(aProd[nI,4]),TAMSX3("E1_PARCELA")[1]," ")+ "NF ")
            //Montando array com as informações da nova nota
            aArray := { { "E1_PREFIXO"  , aProd[nI,2]       , NIL },;
                        { "E1_NUM"      , aProd[nI,3]       , NIL },;
                        { "E1_PARCELA"  , aProd[nI,4]       , NIL },;
                        { "E1_TIPO"     , "NF "             , NIL },;
                        { "E1_NATUREZ"  , aProd[nI,6]       , NIL },;
                        { "E1_CLIENTE"  , PadR(AllTrim(aProd[nI,7]),TAMSX3("E1_CLIENTE")[1]," ")       , NIL },;
                        { "E1_LOJA"     , PadR(AllTrim(aProd[nI,8]),TAMSX3("E1_LOJA")[1]," ")       , NIL },;
                        { "E1_EMISSAO"  , StoD(aProd[nI,9])       , NIL },;
                        { "E1_VENCTO"   , StoD(aProd[nI,11])      , NIL },;
                        { "E1_VENCREA"  , StoD(aProd[nI,12]) , NIL},;
                        { "E1_VALOR"    , Val(Replace(aProd[nI,13],",","."))      , NIL },;
                        { "E1_VLCRUZ"   , Val(Replace(aProd[nI,13],",","."))      , NIL }}
           
            //--------------------desbloquear cliente ---------------------
            //Verificar se cliente esta bloqueado 
            lDesbloqClient := .F.
            DbSelectArea("SA1")
            DbSetOrder(1)
            if dbseek(xFilial("SA1")+ PadR(AllTrim(aProd[nI,7]),TAMSX3("E1_CLIENTE")[1]," ") + PadR(AllTrim(aProd[nI,8]),TAMSX3("E1_LOJA")[1]," "))
                if SA1->A1_MSBLQL == "1"
                    lDesbloqClient := .T.
                    RecLock("SA1", .F.)
                        SA1->A1_MSBLQL := "2"	
                    MsUnlock()
                endif
            endif

            //--------------------desbloquear Vendedor--------------------- 
            lDesbloqVend := .F.
            DbSelectArea("SA3")
            DbSetOrder(1)
            if dbseek(xFilial("SA3")+ SA1->A1_VEND)
                if SA3->A3_MSBLQL == "1"
                    lDesbloqVend := .T.
                    RecLock("SA3", .F.)
                        SA3->A3_MSBLQL := "2"	
                    MsUnlock()
                endif
            endif
                
            //Chama a rotina automática
            lMsErroAuto := .F.
            MsExecAuto( { |x,y| FINA040(x,y)} , aArray, 3)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
            //Se houve erro, mostra o erro ao usuário
            If lMsErroAuto
                MostraErro()
            EndIf
                
            //-----------bloquear cliente------------
            if lDesbloqClient
                DbSelectArea("SA1")
                DbSetOrder(1)
                if dbseek(xFilial("SA1")+ PadR(AllTrim(aProd[nI,7]),TAMSX3("E1_CLIENTE")[1]," ") + PadR(AllTrim(aProd[nI,8]),TAMSX3("E1_LOJA")[1]," "))
                    if SA1->A1_MSBLQL == "2"
                        RecLock("SA1", .F.)
                            SA1->A1_MSBLQL := "1"	
                        MsUnlock()
                    endif
                endif
            endif

            //-----------bloquear VENDEDOR------------
            if lDesbloqVend
                DbSelectArea("SA3")
                DbSetOrder(1)
                if dbseek(xFilial("SA3")+ SA1->A1_VEND)
                    if SA3->A3_MSBLQL == "2"
                        RecLock("SA3", .F.)
                            SA3->A3_MSBLQL := "1"	
                        MsUnlock()
                    endif
                endif
            endif
        ENDiF       
    next
RETURN




