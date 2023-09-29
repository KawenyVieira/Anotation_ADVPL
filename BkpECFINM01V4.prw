
#INCLUDE "rwmake.ch"
#include "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#include "protheus.ch"
#INCLUDE "TOPCONN.CH"
/*/{Protheus.doc} ECFINM01() 
    Rotina de inserção de de dados na tabela do contas a pagar
    @type  Function
    @author Kaweny - eConsiste
    @since 27/02/2023
    @version 12.1.33
/*/

/*-----------------------------------------ENDERECAMENTO DO ARQUIVO-------------------------------------------------
    Rotina para selecao do arquivo, atraves de cx de perguntas
*/
User Function ECFINM01() 

    Local aRet := {}
    Local aParambox := {}
    Local cCab := "Inclusao Titulos Contas a pagar"
    //----
    Local   lRet      := .F.
    Local   nOpc      := 0
    Private cCaminho  := Space(100)
    Private aCampos := {}
    Private aProd  := {}

    PUBLIC cPerguntas:= " "
    //Private cPerg := "ECFINM01"

    While !lRet
         lRet := .T.

         aAdd(aParamBox,{9,"O Programa realiza leitura de um arquivo .csv para insercao de notas na tabela contas a pagar",300, 40,.T.}) //texto simples  
         aAdd(aParamBox,{1,"PREFIXO",Space(3),"@!",' '," ","",6,.T.}) // Tipo caractere
         aAdd(aParamBox,{1,"TIPO",Space(TamSx3('X5_CHAVE')[1]),"@!",'ExistCpo("SX5","05"+MV_PAR03)',"05","",6,.T.}) // Tipo caractere
         aAdd(aParamBox,{9,"Informe o local onde se encontra o arquivo para importacao",200, 40,.T.}) //texto simples
         aAdd(aParamBox,{6,"Buscar Aquivo ",Space(50),"","","",50,.F.,"Todos os arquivos (*.*) |*.*"})

        If ParamBox(aParamBox,cCab,@aRet)
            cPerguntas := aRet[1]
            cCaminho := MV_PAR05
            nOpc := 1
        ENDIF                                               

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
            aAux:= Separa(cLinha,";",.F.)
            If  EMPTY(aAux)
                FT_FSKIP()
            else
                AADD(aProd,Separa(cLinha,";",.T.))
            EndIf
        
            
    
        EndIf
    
        FT_FSKIP()
    EndDo

    FT_FUSE()

Return

/*---------------------------------------------------COMPARACAO DE NOTAS-------------------------------------------------
    Rotina para pesquisa de nota e verificando se a nota é existente na tabela SE2, caso nao, inserindo-a
*/
static function fCompare()

    Local aArray := {}
    Local cCodInvalido := " "
    Local nCodInvalido := 0
    Local cJaCadastrado := " "
    Local nJaCadastrado := 0
    Local cNatureza    := " "
    Local cPrefixo := MV_PAR02
    Local cTipo := MV_PAR03
    Local nI:=0

    Private lMsErroAuto 
    //TAMSX3() => DEVOLVE UM ARRAY [1]=TAM CAMPO, [2]=CASA DECIMAIS, [3]=TP CAMPO
    for nI:=1 to Len(aProd) 
        If EMPTY(aProd[nI,1])
            LOOP
        ELSE
            aArray := {}
            //Posicionamento SA2_ encontrar Codigo fornecedor e trazer info necessarias
            DbSelectArea("SA2")
            DbSetOrder(1)/*Chave de Pesquisa order=1 || A2_FILIAL+A2_COD+A2_LOJA ||*/
            IF dbseek( xFilial("SA2") + aProd[nI,3]+ '01' )
                cNatureza := SA2->A2_NATUREZ
            else
                cCodInvalido +=  aProd[nI,3] + CRLF
                nCodInvalido += 1
                cNatureza := " "
                LOOP
            ENDIF

            //Posicionamento SE2_ Validacao da existencia do titulo na tabela contas a pagar
            DbSelectArea("SE2")
            DbSetOrder(1) /*Chave de Pesquisa order=1 || E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA||*/
            IF !dbseek(xFilial("SE2") + PadR(AllTrim(cPrefixo),TAMSX3("E2_PREFIXO")[1]," ") + PadR(AllTrim(aProd[nI,1]),TAMSX3("E2_NUM")[1]," ") +  PadR(AllTrim(aProd[nI,2]),TAMSX3("E2_PARCELA")[1]," ") + PadR(AllTrim(cTipo),TAMSX3("E2_TIPO")[1]," ") + PadR(AllTrim(aProd[nI,3]),TAMSX3("E2_FORNECE")[1]," ") + "01")
                
                //Montando array com as informações da nova nota
                aArray := { { "E2_PREFIXO"  , PadR(AllTrim(cPrefixo),TAMSX3("E2_PREFIXO")[1]," ")    , NIL },;
                            { "E2_NUM"      , PadR(AllTrim(aProd[nI,1]),TAMSX3("E2_NUM")[1]," ")     , NIL },;
                            { "E2_TIPO"     , PadR(AllTrim(cTipo),TAMSX3("E2_TIPO")[1]," ")          , NIL },;
                            { "E2_FORNECE"  , PadR(AllTrim(aProd[nI,3]),TAMSX3("E2_FORNECE")[1]," ") , NIL },;
                            { "E2_LOJA"     , PadR("01",TAMSX3("E2_LOJA")[1]," ")                    , NIL },;
                            { "E2_PARCELA"  , PadR(AllTrim(aProd[nI,2]),TAMSX3("E2_PARCELA")[1]," ") , NIL },;
                            { "E2_NATUREZ"  , PadR(AllTrim(cNatureza),TAMSX3("E2_NATUREZ")[1]," ")   , NIL },;
                            { "E2_EMISSAO"  , dDatabase                                              , NIL },;
                            { "E2_VENCTO"   , ctod(aProd[nI,5])                                      , NIL },;
                            { "E2_VENCREA"  , CtoD(aProd[nI,5])                                      , NIL },;
                            { "E2_VALOR"    , Val(Replace(aProd[nI,4],",","."))                      , NIL },;
                            { "E2_VLCRUZ"   , Val(Replace(aProd[nI,4],",","."))                      , NIL },;
                            { "E2_XUSINC"   , __cUserID                                              , NIL },;
                            { "E2_XNUSINC"  , cUserName                                              , NIL },;
                            { "E2_XDTINC"   , DATE()                                                 , NIL },;
                            { "E2_XHRINC"   , Time()                                                 , NIL }}
                //Chama a rotina automática
                lMsErroAuto := .F.
                MsExecAuto( { |x,y,z| FINA050(x,y,z)} , aArray, 3)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
                //Se houve erro, mostra o erro ao usuário
                If lMsErroAuto
                    MostraErro()
                EndIf
            else
                cJaCadastrado +=  "Codigo:"+aProd[nI,1]+" Parcela:"+aProd[nI,2]+" Fornecedor:"+ aProd[nI,3]+ CRLF
                nJaCadastrado += 1
            ENDiF  
        EndIf     
    next
       
    //----------------------------------------------------Cx Informando o registro--------------------------------------------------------------
     DO CASE 
        CASE !EMPTY( cCodInvalido ).and.!EMPTY( cJaCadastrado )
            MsgInfo(STR((Len(aProd) - (nJaCadastrado+nCodInvalido))) + "Titulos adicionados"+CRLF+ CRLF+"Codigo(s) de fornecedor invalido(s): "+CRLF+ cCodInvalido +CRLF+ "Titulo(s) ja cadastrado(s):"+CRLF+ cJaCadastrado," ")

        CASE !EMPTY( cCodInvalido )
            MsgInfo(STR((Len(aProd) - nCodInvalido )) + "Titulos adicionados"+CRLF+ CRLF+ "Codigo(s) Invalido(s): "+CRLF+ cCodInvalido," ")

        CASE !EMPTY( cJaCadastrado )
            MsgInfo(STR((Len(aProd) - nJaCadastrado)) + " Titulos adicionados"+CRLF+ CRLF+ "Titulo(s) ja cadastrado(s): "+CRLF+ cJaCadastrado," ")

        CASE EMPTY( cCodInvalido) .AND. EMPTY( cJaCadastrado )
            MsgInfo(STR(Len(aProd) )+ " Titulos adicionados com sucesso!"," ")
    ENDCASE
        

    
RETURN




