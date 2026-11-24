# Previsão de Risco Cardíaco com GBM

Neste projeto, o objetivo foi prever se uma pessoa vai desenvolver doença coronariana nos próximos dez anos. Os dados vêm do estudo cardiovascular de Framingham, uma cidade de Massachusetts (EUA) cujos moradores são acompanhados há décadas. O modelo escolhido foi o Gradient Boosting (GBM), em R.

## Os dados

Cada paciente é descrito por fatores de risco de três tipos:

- **Demográficos:** sexo, idade e escolaridade (de 1, ensino médio incompleto, a 4, ensino superior).
- **Comportamentais:** se fuma e quantos cigarros fuma por dia.
- **Histórico e exames:** se toma remédio para pressão, se já teve AVC, se é hipertenso ou diabético, colesterol total, pressão sistólica e diastólica, IMC, frequência cardíaca e glicose.

A variável que o modelo tenta prever é `TenYearCHD`: 1 se a pessoa desenvolveu doença coronariana em dez anos, 0 se não.

## Os desafios dos dados

Essa base tem dois problemas clássicos. O primeiro é o desequilíbrio: a grande maioria das pessoas não desenvolve a doença, então um modelo preguiçoso poderia simplesmente dizer "não" para todo mundo e ainda parecer bom. Para contornar isso, usei o método ROSE, que gera exemplos sintéticos e deixa as classes mais equilibradas no treino.

O segundo problema são os valores faltando. Em vez de jogar fora as linhas incompletas, preenchi os buracos com árvores de decisão (rpart): uma regressão para as variáveis numéricas e uma classificação para as categóricas. Depois os dados foram centralizados e padronizados. Um cuidado importante foi aplicar à base de teste exatamente as mesmas regras aprendidas no treino, para não "vazar" informação.

## Ajustando o modelo

Separei 70% dos dados para treino e 30% para teste. Escrevi uma função que testa combinações de profundidade das árvores (1, 3 e 5) e taxa de aprendizado (0,05, 0,1 e 0,5), usando validação cruzada para descobrir o número ideal de árvores. A melhor combinação foi profundidade 3 e taxa 0,10, com 186 árvores.

Outro detalhe: em vez de usar o corte padrão de 50% para decidir quem tem risco, escolhi o ponto de corte pela curva ROC, procurando o melhor equilíbrio entre acertar os doentes e não alarmar os saudáveis.

## Resultado

Na base de teste, o modelo teve **76,8% de acurácia** e conseguiu identificar **83,2%** dos casos da classe positiva. A especificidade ficou em 40,5%, o que mostra que ainda há espaço para melhorar na outra classe.

## O que tem aqui

- `R/treino_modelo.R` faz todo o processo: tratamento, busca de parâmetros, treino e gravação do modelo.
- `R/prever.R` traz a função `desafio(dados)`, que recebe uma base nova, aplica o mesmo tratamento e devolve a matriz de confusão.
- `dados/dados_gbm.rda` é a base usada no treino.
- `modelo/modelo_risco_cardiaco.Rdata` guarda o modelo treinado, as regras de imputação, o pré-processamento e o ponto de corte.

## Como usar

Para treinar de novo, é só rodar `R/treino_modelo.R`, que já carrega a base da pasta `dados/`. Para usar o modelo pronto numa base nova (com as mesmas colunas), rode a partir da pasta do projeto:

```r
source("R/prever.R")
desafio(minha_base)
```
