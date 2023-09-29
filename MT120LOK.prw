#include "protheus.ch"
#include "rwmake.ch"
/*-----------+----------+--------+------------------+-------+------------+
| Programa:  | MT120LOK | Autor: | Kaweny-eConsiste | Data: | Março/2023 |
+------------+----------+--------+---------------+-------+---------------+
| Descrição: | Ponto de Entrada na Validação da Inclusão do Pedido de    |
|            | Compras a cada Linha.                                     |
+------------+-----------------------------------------------------------*/

User Function MT120LOK()
    Local I :=0
    local lRet := .F.

    If Len(aCols) <= 1
         lRet :=.t.
    else
        For I := 1 to Len(aCols)
            If I == n
                loop
            else
                If  ALLTRIM(aCols[I][3]) == ALLTRIM(aCols[n][3])
                    MsgStop("Não é possível a inclusão do produto no Pedido de Compras! "+ CRLF +" Produto do item "+cValToChar(n) +" é igual ao produto do item "+ cValToChar(I))
                    lRet:=.F.
                    RETURN lRet
                EndIf
            EndIf
            lRet :=.t.
        Next
    EndIf
    
    

RETURN(lRet)