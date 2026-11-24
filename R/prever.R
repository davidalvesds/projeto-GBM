desafio<-function(dados){
  load('modelo/modelo_risco_cardiaco.Rdata')

  if (!require("dplyr")) {
    install.packages("dplyr")
    library(dplyr)
  } else {
    library(dplyr)
  }
  if (!require("caret")) {
    install.packages("caret")
    library(caret)
  } else {
    library(caret)
  }
  if (!require("ROSE")) {
    install.packages("ROSE")
    library(ROSE)
  } else {
    library(ROSE)
  }
  if (!require("mlr")) {
    install.packages("mlr")
    library(mlr)
  } else {
    library(mlr)
  }
  if (!require("rpart")) {
    install.packages("rpart")
    library(rpart)
  } else {
    library(rpart)
  }
  if (!require("gbm")) {
    install.packages("gbm")
    library(gbm)
  } else {
    library(gbm)
  }
  if (!require("pROC")) {
    install.packages("pROC")
    library(pROC)
  } else {
    library(pROC)
  }

  if (!require("ROCR")) {
    install.packages("ROCR")
    library(ROCR)
  } else {
    library(ROCR)
  }

  dados$sex     <- factor(dados$sex, levels = c('M', 'F'),labels = c(0,1)    )
  dados$TenYearCHD <- factor(dados$TenYearCHD, levels = c(0,1))
  dados$education     <- factor(dados$education, levels = c(1,2,3,4),labels = c(0,1,2,3)    )
  dados$currentSmoker <- factor(dados$currentSmoker, levels = c(0,1))
  dados$BPMeds <- factor(dados$BPMeds, levels = c(0,1))
  dados$prevalentStroke <- factor(dados$prevalentStroke, levels = c(0,1))
  dados$prevalentHyp <- factor(dados$prevalentHyp, levels = c(0,1))
  dados$diabetes <- factor(dados$diabetes, levels = c(0,1))

  dados_imp = reimpute(dados, ReNA)
  dados_imp<-predict(preprocessamento,dados_imp)

  tipot<-dados_imp$TenYearCHD==1
  dados_imp<-mutate(dados_imp,TenYearCHD=tipot)

  predicao<-predict(modelFit1,dados_imp,
                    type = 'response',
                    n.trees=a)

  classificacao2<-predicao>=c

  resultado = confusionMatrix(data=as.factor(classificacao2),
                  reference=as.factor(dados_imp$TenYearCHD))

  return(resultado)
}
